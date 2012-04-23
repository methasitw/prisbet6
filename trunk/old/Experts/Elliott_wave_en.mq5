//+------------------------------------------------------------------+
//|                                                 Elliott wave.mq5 |
//|                                                  Roman Martynyuk |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Roman Martynyuk"
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <Object.mqh>
#include <Arrays\List.mqh>
#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayInt.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Arrays\ArrayString.mqh>
#include <ChartObjects\ChartObjectsTxtControls.mqh>
#include <Elliott wave\Data structures.mqh>
#include <Elliott wave\Analysis functions.mqh>
#include <Elliott wave\Rules functions.mqh>
CChartObjectButton *ButtonStart,*ButtonShow,*ButtonClear,*ButtonCorrect;
int State;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   State=0;
   // create control buttons
   ButtonStart=new CChartObjectButton;
   ButtonStart.Create(0,"Begin analysis",0,0,0,150,20);
   ButtonStart.Description("Begin analysis");
   ButtonShow=new CChartObjectButton;
   ButtonShow.Create(0,"Show results",0,150,0,150,20);
   ButtonShow.Description("Show results");
   ButtonClear=new CChartObjectButton;
   ButtonClear.Create(0,"Clear chart",0,300,0,150,20);
   ButtonClear.Description("Clear chart");
   ButtonCorrect=new CChartObjectButton;
   ButtonCorrect.Create(0,"Correct the marks",0,450,0,150,20);
   ButtonCorrect.Description("Correct the marks");
   ChartRedraw();
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //clear waves tree
   ClearTree(FirstNode);
   //clear NodeInfoArray
   ClearNodeInfoArray();
   //clear ZigzagArray
   ClearZigzagArray();
   //clear LabelArray
   for(int i=0;i<ArrayRange(LabelArray,0);i++)
     {
      CArrayObj *ArrayObj=LabelArray[i];
      if(CheckPointer(ArrayObj)!=POINTER_INVALID)
        {
         for(int j=0;j<ArrayObj.Total();j++)
           {
            TLabel *Label=ArrayObj.At(j);
            delete Label;
           }
         ArrayObj.Clear();
         delete ArrayObj;
        }  
   }
   //delete all of the graphical elements from the chart
   for(int i=ObjTextArray.Total()-1;i>=0;i--)
     {
      CChartObjectText *ObjText=ObjTextArray.At(i);
       delete ObjText;
     }
   ObjTextArray.Clear();
   delete ButtonStart;
   delete ButtonShow;
   delete ButtonClear;
   delete ButtonCorrect;
   ChartRedraw();
  }
MqlRates rates[];
TNode *FirstNode;
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="Begin analysis" && State!=0)
      MessageBox("First press the button \"Clear chart\"");
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="Show results" && State!=1)
      MessageBox("First press the button \"Begin analysis\"");
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="Clear chart" && State!=2)
      MessageBox("First press the button \"Show results\"");
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="Correct marks" && State!=2)
      MessageBox("First press the button \"Show results\"");
   // if the "Begin analysis" has pressed
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="Begin analysis" && State==0)
     {
      // fill the rates array
      CopyRates(NULL,0,0,Bars(_Symbol,_Period),rates);
      // fill the ZigzagArray array
      FillZigzagArray(0,Bars(_Symbol,_Period)-1);
      // create the first node
      TWave *Wave=new TWave;
      Wave.IndexVertex[0] = 0;
      Wave.IndexVertex[1] = Bars(_Symbol,_Period)-1;
      Wave.ValueVertex[0] = 0;
      Wave.ValueVertex[1] = 0;
      FirstNode=new TNode;
      FirstNode.Child=new CArrayObj;
      FirstNode.Wave=Wave;
      FirstNode.Text="First node";
      string NameWaves="Impulse,Leading Diagonal,Diagonal,ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,";
      // call the search for unbegun and incomplete waves function
      NotStartedAndNotFinishedWaves(Wave,1,FirstNode,NameWaves,0);
      MessageBox("Analysis is complete");
      State=1;
      ButtonStart.State(false);
      ChartRedraw();
     }
   // if the "Show results" button has pressed
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="Show results" && State==1)
     {
      ArrayResize(LabelArray,ArrayRange(rates,0));

      //fill the LabelArray array
      FillLabelArray(FirstNode);
      //show the mark-up of the waves on the chart
      CreateLabels();
      State=2;
      ButtonShow.State(false);
      ChartRedraw();
     }
  // if the  "Clear chart" button has pressed
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="Clear chart" && State==2)
     {
      //clear the waves tree
      ClearTree(FirstNode);
      //clear the NodeInfoArray array
      ClearNodeInfoArray();
      //clear the ZigzagArray array
      ClearZigzagArray();
      
      //clear the LabelArray array
      for(int i=0;i<ArrayRange(LabelArray,0);i++)
        {
         CArrayObj *ArrayObj=LabelArray[i];
         if(CheckPointer(ArrayObj)!=POINTER_INVALID)
           {
            for(int j=0;j<ArrayObj.Total();j++)
              {
               TLabel *Label=ArrayObj.At(j);
               delete Label;
              }
            ArrayObj.Clear();
            delete ArrayObj;
           }
        }      
      
      // delete the mark-up from the chart
      for(int i=ObjTextArray.Total()-1;i>=0;i--)
        {
         CChartObjectText *ObjText=ObjTextArray.At(i);
         ObjText.Delete();
        }
      ObjTextArray.Clear();
      State=0;
      ButtonClear.State(false);
      ChartRedraw();
     }
   if(id==CHARTEVENT_OBJECT_CLICK && sparam=="Correct the marks" && State==2)
     {
      CorrectLabel();
      ButtonCorrect.State(false);
      ChartRedraw();
     }
  }
//+------------------------------------------------------------------+
//| CorrectLabel function                                            |
//+------------------------------------------------------------------+
void CorrectLabel()
  {
   double PriceMax=ChartGetDouble(0,CHART_PRICE_MAX,0);
   double PriceMin = ChartGetDouble(0,CHART_PRICE_MIN);
   int WindowHeight=ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   double CurrentPriceInPixels=(PriceMax-PriceMin)/WindowHeight;
   // loop all of the text objects (wave tops) and change their price size
   for(int i=0;i<ObjTextArray.Total();i++)
     {
      CChartObjectText *ObjText=ObjTextArray.At(i);
      double PriceValue=ObjText.Price(0);
      datetime PriceTime=ObjText.Time(0);
      int j;
      for(j=0;j<ArrayRange(rates,0);j++)
        {
         if(rates[j].time==PriceTime)
            break;
        }
      double OffsetInPixels;
      if(rates[j].low>=PriceValue)
        {
         OffsetInPixels=(rates[j].low-PriceValue)/PriceInPixels;
         ObjText.Price(0,rates[j].low-OffsetInPixels*CurrentPriceInPixels);
        }
      else if(rates[j].high<=PriceValue)
        {
         OffsetInPixels=(PriceValue-rates[j].high)/PriceInPixels;
         ObjText.Price(0,rates[j].high+OffsetInPixels*CurrentPriceInPixels);
        }
     }
   PriceInPixels=CurrentPriceInPixels;
  }
double PriceInPixels;
CArrayObj ObjTextArray; // declare an array, which will store the graphical objects of "Text" type
//+------------------------------------------------------------------+
//| CreateLabels function                                            |
//+------------------------------------------------------------------+
void CreateLabels()
  {
   double PriceMax =ChartGetDouble(0,CHART_PRICE_MAX,0);
   double PriceMin = ChartGetDouble(0,CHART_PRICE_MIN);
   int WindowHeight=ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS);
   PriceInPixels=(PriceMax-PriceMin)/WindowHeight;
   int n=0;
   // loop the LabelArray array
   for(int i=0;i<ArrayRange(LabelArray,0);i++)
     {
      // if there are tops with the same index i
      if(CheckPointer(LabelArray[i])!=POINTER_INVALID)
        {
         // obtain the tops with the same indexes i
         CArrayObj *ArrayObj=LabelArray[i];
         // loop the tops and display them on the chart
         for(int j=ArrayObj.Total()-1;j>=0;j--)
           {
            TLabel *Label=ArrayObj.At(j);
            int Level=LevelMax-Label.Level;
            string Text=Label.Text;
            double Value=Label.Value;
            color Color;
            int Size=8;
            if((Level/3)%2==0)
              {
               if(Text=="1") Text="i";
               else if(Text == "2") Text = "ii";
               else if(Text == "3") Text = "iii";
               else if(Text == "4") Text = "iv";
               else if(Text == "5") Text = "v";
               else if(Text == "A") Text = "a";
               else if(Text == "B") Text = "b";
               else if(Text == "C") Text = "c";
               else if(Text == "D") Text = "d";
               else if(Text == "E") Text = "e";
               else if(Text == "W") Text = "w";
               else if(Text=="X") Text="x";
               else if(Text == "XX") Text = "xx";
               else if(Text == "Y") Text = "y";
               else if(Text == "Z") Text = "z";
              }
            if(Level%3==2)
              {
               Color=Green;
               Text="["+Text+"]";
              }
            if(Level%3==1)
              {
               Color=Blue;
               Text="("+Text+")";
              }
            if(Level%3==0)
               Color=Red;
            int Anchor;
            if(Value==rates[i].high)
              {
               for(int k=ArrayObj.Total()-j-1;k>=0;k--)
                  Value=Value+15*PriceInPixels;
               Anchor=ANCHOR_UPPER;
              }
            else if(Value==rates[i].low)
              {
               for(int k=ArrayObj.Total()-j-1;k>=0;k--)
                  Value=Value-15*PriceInPixels;
               Anchor=ANCHOR_LOWER;
              }
            CChartObjectText *ObjText=new CChartObjectText;
            ObjText.Create(0,"wave"+IntegerToString(n),0,rates[i].time,Value);
            ObjText.Description(Text);
            ObjText.Color(Color);
            ObjText.SetInteger(OBJPROP_ANCHOR,Anchor);
            ObjText.FontSize(8);
            ObjText.Selectable(true);
            ObjTextArray.Add(ObjText);
            n++;
           }
        }
     }
   ChartRedraw();
  }
CArrayObj *LabelArray[];
int LevelMax=0;
//+------------------------------------------------------------------+
//| FillLabelArray function                                          |
//+------------------------------------------------------------------+
void FillLabelArray(TNode *Node)
  {
   if(Node.Child.Total()>0)
     {
      // obtain the first node
      TNode *ChildNode=Node.Child.At(0);
      // obtain the structure, in which the information about the wave is stored
      TWave *Wave=ChildNode.Wave;
      string Text;
      // if there is a first top
      if(Wave.ValueVertex[1]>0)
        {
         // mark the top according to the wave
         if(Wave.Name=="Impulse" || Wave.Name=="Leading Diagonal" || Wave.Name=="Diagonal")
            Text="1";
         else if(Wave.Name=="ZigZag" || Wave.Name=="Flat" || Wave.Name=="Expanding Triangle" ||
                Wave.Name=="Contracting Triangle")
            Text="A";
         else if(Wave.Name=="Double ZigZag" || Wave.Name=="Double Three" || 
                Wave.Name=="Triple ZigZag" || Wave.Name=="Triple Three")
            Text="W";
         // obtain the array of the ArrayObj tops, which have the index Wave.IndexVertex[1] on the price chart
         CArrayObj *ArrayObj=LabelArray[Wave.IndexVertex[1]];
         if(CheckPointer(ArrayObj)==POINTER_INVALID)
           {
            ArrayObj=new CArrayObj;
            LabelArray[Wave.IndexVertex[1]]=ArrayObj;
           }
         // put the information about the top with the index Wave.IndexVertex[1] into the array ArrayObj
         TLabel *Label=new TLabel;
         Label.Text=Text;
         Label.Level=Wave.Level;
         if(Wave.Level>LevelMax)LevelMax=Wave.Level;
         Label.Value=Wave.ValueVertex[1];
         ArrayObj.Add(Label);
        }
      if(Wave.ValueVertex[2]>0)
        {
         if(Wave.Name=="Impulse" || Wave.Name=="Leading Diagonal" || Wave.Name=="Diagonal")
            Text="2";
         else if(Wave.Name=="ZigZag" || Wave.Name=="Flat" || Wave.Name=="Expanding Triangle" ||
                Wave.Name=="Contracting Triangle")
            Text="B";
         else if(Wave.Name=="Double ZigZag" || Wave.Name=="Double Three" ||
                Wave.Name=="Triple ZigZag" || Wave.Name=="Triple Three")
            Text="X";
         CArrayObj *ArrayObj=LabelArray[Wave.IndexVertex[2]];
         if(CheckPointer(ArrayObj)==POINTER_INVALID)
           {
            ArrayObj=new CArrayObj;
            LabelArray[Wave.IndexVertex[2]]=ArrayObj;
           }
         TLabel *Label=new TLabel;
         Label.Text=Text;
         Label.Level=Wave.Level;
         if(Wave.Level>LevelMax)LevelMax=Wave.Level;
         Label.Value=Wave.ValueVertex[2];
         ArrayObj.Add(Label);
        }
      if(Wave.ValueVertex[3]>0)
        {
         if(Wave.Name=="Impulse" || Wave.Name=="Leading Diagonal" || Wave.Name=="Diagonal")
            Text="3";
         else if(Wave.Name=="ZigZag" || Wave.Name=="Flat" || 
                Wave.Name=="Expanding Triangle" || Wave.Name=="Contracting Triangle")
            Text="C";
         else if(Wave.Name=="Double ZigZag" || Wave.Name=="Double Three" ||
                Wave.Name=="Triple ZigZag" || Wave.Name=="Triple Three")
            Text="Y";
         CArrayObj *ArrayObj=LabelArray[Wave.IndexVertex[3]];
         if(ArrayObj==NULL)
           {
            ArrayObj=new CArrayObj;
            LabelArray[Wave.IndexVertex[3]]=ArrayObj;
           }
         TLabel *Label=new TLabel;
         Label.Text=Text;
         Label.Level=Wave.Level;
         if(Wave.Level>LevelMax)LevelMax=Wave.Level;
         Label.Value=Wave.ValueVertex[3];
         ArrayObj.Add(Label);
        }
      if(Wave.ValueVertex[4]>0)
        {
         if(Wave.Name=="Impulse" || Wave.Name=="Leading Diagonal" || Wave.Name=="Diagonal")
            Text="4";
         else if(Wave.Name=="Expanding Triangle" || Wave.Name=="Contracting Triangle")
            Text="D";
         else if(Wave.Name=="Triple ZigZag" || Wave.Name=="Triple Three")
            Text="XX";
         CArrayObj *ArrayObj=LabelArray[Wave.IndexVertex[4]];
         if(CheckPointer(ArrayObj)==POINTER_INVALID)
           {
            ArrayObj=new CArrayObj;
            LabelArray[Wave.IndexVertex[4]]=ArrayObj;
           }
         TLabel *Label=new TLabel;
         Label.Text=Text;
         Label.Level=Wave.Level;
         if(Wave.Level>LevelMax)LevelMax=Wave.Level;
         Label.Value=Wave.ValueVertex[4];
         ArrayObj.Add(Label);
        }
      if(Wave.ValueVertex[5]>0)
        {
         if(Wave.Name=="Impulse" || Wave.Name=="Leading Diagonal" || Wave.Name=="Diagonal")
            Text="5";
         else if(Wave.Name=="Expanding Triangle" || Wave.Name=="Contracting Triangle")
            Text="E";
         else if(Wave.Name=="Triple ZigZag" || Wave.Name=="Triple Three")
            Text="Z";
         CArrayObj *ArrayObj=LabelArray[Wave.IndexVertex[5]];
         if(CheckPointer(ArrayObj)==POINTER_INVALID)
           {
            ArrayObj=new CArrayObj;
            LabelArray[Wave.IndexVertex[5]]=ArrayObj;
           }
         TLabel *Label=new TLabel;
         Label.Text=Text;
         Label.Level=Wave.Level;
         if(Wave.Level>LevelMax)LevelMax=Wave.Level;
         Label.Value=Wave.ValueVertex[5];
         ArrayObj.Add(Label);
        }
      // proceed the child nodes of the current node
      for(int j=0;j<ChildNode.Child.Total();j++)
         FillLabelArray(ChildNode.Child.At(j));
     }
  }
//+------------------------------------------------------------------+
//| Zigzag function                                                  |
//+------------------------------------------------------------------+
int Zigzag(int H,int Start,int Finish,CArrayInt *IndexVertex,CArrayDouble *ValueVertex)
  {
   bool Up=true;
   double dH=H*Point();
   int j=0;
   int TempMaxBar = Start;
   int TempMinBar = Start;
   double TempMax = rates[Start].high;
   double TempMin = rates[Start].low;
   for(int i=Start+1;i<=Finish;i++)
     {
      // processing the case of a rising segment
      if(Up==true)
        {
         // check that the current maximum has not changed
         if(rates[i].high>TempMax)
           {
            //  if it has, correct the corresponding variables
            TempMax=rates[i].high;
            TempMaxBar=i;
           }
         else if(rates[i].low<TempMax-dH)
           {
            // otherwise, if the lagged level is broken, fixate the maximum
            ValueVertex.Add(TempMax);
            IndexVertex.Add(TempMaxBar);
            j++;
            // correct the corresponding variables
            Up=false;
            TempMin=rates[i].low;
            TempMinBar=i;
           }
        }
      else
        {
         // processing the case of the descending segment
         // check that the current minimum hasn't changed
         if(rates[i].low<TempMin)
           {
            // if it has, correct the corresponding variables
            TempMin=rates[i].low;
            TempMinBar=i;
           }
         else if(rates[i].high>TempMin+dH)
           {
            // otherwise, if the lagged level is broken, fix the minimum
            ValueVertex.Add(TempMin);
            IndexVertex.Add(TempMinBar);
            j++;
            // correct the corresponding variables
            Up=true;
            TempMax=rates[i].high;
            TempMaxBar=i;
           }
        }
     }
   // return the number of zigzag tops
   return(j);
  }
CArrayObj ZigzagArray; // declare the ZigzagArray global dynamic array
//+------------------------------------------------------------------+
//| The FillZigzagArray function                                     |
//| Fills the ZigzagArray                                            |
//+------------------------------------------------------------------+
void FillZigzagArray(int Start,int Finish)
  {
   CArrayInt *IndexVertex=new CArrayInt;         // create the dynamic array of indexes of zigzag tops
   CArrayDouble *ValueVertex=new CArrayDouble;   // create the dynamic array of values of the zigzag tops
   TZigzag *Zigzag;                              // declare the class for storing the indexes and values of the zigzag tops
   int H=1;
   int j=0;
   int n=Zigzag(H,Start,Finish,IndexVertex,ValueVertex);//declare the class for storing the indexes and values of the zigzag tops
   if(n>0)
     {
      // store the tops of the zigzag in the ZigzagArray array
      Zigzag=new TZigzag; // create the object for storing the found indexes and the zigzag tops,
                          // fill it and store in the ZigzagArray array
      Zigzag.IndexVertex=IndexVertex;
      Zigzag.ValueVertex=ValueVertex;
      ZigzagArray.Add(Zigzag);
      j++;
     }
   H++;
   // loop of the H of the zigzag
   while(true)
     {
      IndexVertex=new CArrayInt;                        // create a dynamic array of indexes of zigzag tops
      ValueVertex=new CArrayDouble;                     // create a dynamic array of values of the zigzag tops
      n=Zigzag(H,Start,Finish,IndexVertex,ValueVertex); // find the tops of the zigzag
      if(n>0)
        {
         Zigzag=ZigzagArray.At(j-1);
         CArrayInt *PrevIndexVertex=Zigzag.IndexVertex; // get the array of indexes of the previous zigzag
         bool b=false;
         // check if there is a difference between the current zigzag and the previous zigzag
         for(int i=0; i<=n-1;i++)
           {
            if(PrevIndexVertex.At(i)!=IndexVertex.At(i))
              {
               // if there is a difference, store the tops of a zigzag in the array ZigzagArray
               Zigzag=new TZigzag;
               Zigzag.IndexVertex=IndexVertex;
               Zigzag.ValueVertex=ValueVertex;
               ZigzagArray.Add(Zigzag);
               j++;
               b=true;
               break;
              }
           }
         if(b==false)
           {
            // // otherwise, if there is no difference, release the memory
            delete IndexVertex;
            delete ValueVertex;
           }
        }
      // search for the tops of the zigzag until there is two or less of them
      if(n<=2)
         break;
      H++;
     }
  }
//+------------------------------------------------------------------+
//| The FindPoints function                                          |
//| Fill the ValuePoints and IndexPoints arrays                      |
//| of the Points structure                                          |
//+------------------------------------------------------------------+
bool FindPoints(int NumPoints,int IndexStart,int IndexFinish,double ValueStart,double ValueFinish,TPoints &Points)
  {
   int n=0;
   // proceed all of th eZigzagArray elements
   for(int i=ZigzagArray.Total()-1; i>=0;i--)
     {
      TZigzag *Zigzag=ZigzagArray.At(i);             // the obtained i zigzag in the ZigzagArray array
      CArrayInt *IndexVertex=Zigzag.IndexVertex;     // get the array of the indexes of the tops of the i zigzags
      CArrayDouble *ValueVertex=Zigzag.ValueVertex;  // get the array of values of the tops of the i zigzag
      int Index1=-1,Index2=-1;
      // search the index of the IndexVertex array, corresponding to the first point
      for(int j=0;j<IndexVertex.Total();j++)
        {
         if(IndexVertex.At(j)>=IndexStart)
           {
            Index1=j;
            break;
           }
        }
      // search the index of the IndexVertex array, corresponding to the last point
      for(int j=IndexVertex.Total()-1;j>=0;j--)
        {
         if(IndexVertex.At(j)<=IndexFinish)
           {
            Index2=j;
            break;
           }
        }
      // if the first and last points were found
      if((Index1!=-1) && (Index2!=-1))
        {
         n=Index2-Index1+1; // find out how many points were found
        }
      // if the required number of points was found (equal or greater)
      if(n>=NumPoints)
        {
         // check that the first and last tops correspond with the required top values
         if(((ValueStart!=0) && (ValueVertex.At(Index1)!=ValueStart)) || 
            ((ValueFinish!=0) && (ValueVertex.At(Index1+n-1)!=ValueFinish)))continue;
         // fill the Points structure, passed as a parameter
         Points.NumPoints=n;
         ArrayResize(Points.ValuePoints, n);
         ArrayResize(Points.IndexPoints, n);
         int k=0;
         // fill the ValuePoints and IndexPoints arrays of Points structure
         for(int j=Index1; j<Index1+n;j++)
           {
            Points.ValuePoints[k]=ValueVertex.At(j);
            Points.IndexPoints[k]=IndexVertex.At(j);
            k++;
           }
         return(true);
        };
     };
   return(false);
  };
CArrayObj NodeInfoArray; // declare an array to store information about the analyzed intervals of the chart
//+------------------------------------------------------------------+
//| The Already function                                             |
//+------------------------------------------------------------------+
bool Already(TWave *Wave,int NumWave,TNode *Node,string Subwaves)
  {
   // obtain the necessary parameters of the wave or the group of waves
   int IndexStart=Wave.IndexVertex[NumWave-1];
   int IndexFinish=Wave.IndexVertex[NumWave];
   double ValueStart = Wave.ValueVertex[NumWave - 1];
   double ValueFinish= Wave.ValueVertex[NumWave];
   // in the loop, proceed the array NodeInfoArray for the search of the marked-up section of the chart
   for(int i=NodeInfoArray.Total()-1; i>=0;i--)
     {
      TNodeInfo *NodeInfo=NodeInfoArray.At(i);
      // if the required section has already been marked-up
      if(NodeInfo.Subwaves==Subwaves && (NodeInfo.ValueStart==ValueStart) && 
         (NodeInfo.ValueFinish==ValueFinish) && (NodeInfo.IndexStart==IndexStart) &&
         (NodeInfo.IndexFinish==IndexFinish))
        {
         // add the child nodes of the found node into the child nodes of the new node
         for(int j=0;j<NodeInfo.Node.Child.Total();j++)
            Node.Child.Add(NodeInfo.Node.Child.At(j));
         return(true); // exit the function
        }
     }
   // if the interval has not been marked-up earlier, then record its data into the array NodeInfoArray
   TNodeInfo *NodeInfo=new TNodeInfo;
   NodeInfo.IndexStart=IndexStart;
   NodeInfo.IndexFinish=IndexFinish;
   NodeInfo.ValueStart=ValueStart;
   NodeInfo.ValueFinish=ValueFinish;
   NodeInfo.Subwaves=Subwaves;
   NodeInfo.Node=Node;
   NodeInfoArray.Add(NodeInfo);
   return(false);
  }
//+------------------------------------------------------------------+
//| The function of clearing the waves tree with the top node Node   |
//+------------------------------------------------------------------+
void ClearTree(TNode *Node)
  {
   if(CheckPointer(Node)!=POINTER_INVALID)
     {
      for(int i=0; i<Node.Child.Total();i++)
         ClearTree(Node.Child.At(i));
      delete Node.Child;
      if(CheckPointer(Node.Wave)!=POINTER_INVALID)delete Node.Wave;
      delete Node;
     }
  }
//+------------------------------------------------------------------+
//| The function of clearing the NodeInfoArray array                 |
//+------------------------------------------------------------------+
void ClearNodeInfoArray()
  {
   for(int i=NodeInfoArray.Total()-1; i>=0;i--)
     {
      TNodeInfo *NodeInfo=NodeInfoArray.At(i);
      if(CheckPointer(NodeInfo.Node)!=POINTER_INVALID)delete NodeInfo.Node;
      delete NodeInfo;
     }
   NodeInfoArray.Clear();
  }
//+------------------------------------------------------------------+
//| The function of clearing the ZigzagArray array                   |
//+------------------------------------------------------------------+
void ClearZigzagArray()
  {
   for(int i=0;i<ZigzagArray.Total();i++)
     {
      TZigzag *Zigzag=ZigzagArray.At(i);
      delete Zigzag.IndexVertex;
      delete Zigzag.ValueVertex;
      delete Zigzag;
     }
   ZigzagArray.Clear();
  }
TWaveDescription WaveDescription[]=
  {
     {
      "Impulse",5,
        {
         "",
         "Impulse,Leading Diagonal,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "Impulse,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "Impulse,Diagonal,"
        }
     }
      ,
     {
      "Leading Diagonal",5,
        {
         "",
         "Impulse,Leading Diagonal,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "Impulse,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "Impulse,Diagonal,"
        }
     }
      ,
     {
      "Diagonal",5,
        {
         "",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,"
        }
     }
      ,
     {
      "ZigZag",3,
        {
         "",
         "Impulse,Leading Diagonal,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "Impulse,Diagonal,",
         "",
         ""
        }
     }
      ,
     {
      "Flat",3,
        {
         "",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "Impulse,Diagonal,",
         "",
         ""
        }
     }
      ,
     {
      "Double ZigZag",3,
        {
         "",
         "ZigZag,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "ZigZag,",
         "",
         ""
        }
     }
      ,
     {
      "Triple ZigZag",5,
        {
         "",
         "ZigZag,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "ZigZag,"
        }
     }
      ,
     {
      "Double Three",3,
        {
         "",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "",
         ""
        }
     }
      ,
     {
      "Triple Three",5,
        {
         "",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,"
        }
     }
      ,
     {
      "Contracting Triangle",5,
        {
         "",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,"
        }
     }
      ,
     {
      "Expanding Triangle",5,
        {
         "",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,",
         "ZigZag,Flat,Double ZigZag,Triple ZigZag,Double Three,Triple Three,Contracting Triangle,Expanding Triangle,"
        }
     }
  };
//+------------------------------------------------------------------+
//| The FindWaveInWaveDescription function                           |
//+------------------------------------------------------------------+
int FindWaveInWaveDescription(string NameWave)
  {
   for(int i=0;i<ArrayRange(WaveDescription,0);i++)
      if(WaveDescription[i].NameWave==NameWave)return(i);
   return(-1);
  }
//+------------------------------------------------------------------+
