//+------------------------------------------------------------------+
//|                                           Analysis functions.mqh |
//|                                                  Roman Martynyuk |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Roman Martynyuk"
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| The FinishedWaves function                                       |
//+------------------------------------------------------------------+
void FinishedWaves(TWave *ParentWave,int NumWave,TNode *Node,string Subwaves,int Level)
  {
   int v0,v1,v2,v3,v4,v5,I;
   TPoints Points;
   TNode *ParentNode,*ChildNode;
   int IndexWave;
   string NameWave;
   TWave *Wave;
   int i=0,Pos=0,Start=0;
   // in the ListNameWave array put the waves, which we will be analyzing
   string ListNameWave[];
   ArrayResize(ListNameWave,ArrayRange(WaveDescription,0));
   while(Pos!=StringLen(Subwaves)-1)
     {
      Pos=StringFind(Subwaves,",",Start);
      NameWave=StringSubstr(Subwaves,Start,Pos-Start);
      ListNameWave[i++]=NameWave;
      Start=Pos+1;
     }
   int IndexStart=ParentWave.IndexVertex[NumWave-1];
   int IndexFinish=ParentWave.IndexVertex[NumWave];
   double ValueStart = ParentWave.ValueVertex[NumWave - 1];
   double ValueFinish= ParentWave.ValueVertex[NumWave];
   // find no less than four points on the price chart and record them into the structure Points
   // if none were found, then exit the function
   if(FindPoints(4,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false) return;
   // loop of the complete waves with the formula "1-2-3"   
   v0 = 0;
   v1 = 1;
   v3 = Points.NumPoints - 1;
   while(v1<=v3-2)
     {
      v2=v1+1;
      while(v2<=v3-1)
        {
         int j=0;
         while(j<=i-1)
           {
            // get the name of the wave for analysis from ListNameWave
            NameWave=ListNameWave[j++];
            // find the index of the wave in the structure WaveDescription in order to know the number of sub-waves and its names
            IndexWave=FindWaveInWaveDescription(NameWave);
            if(WaveDescription[IndexWave].NumWave==3)
              {
               // create the object of  TWave class and fill its fields - parameters of the analyzed wave
               Wave=new TWave;;
               Wave.Name=NameWave;
               Wave.Formula="1-2-3";
               Wave.Level=Level;
               Wave.ValueVertex[0] = Points.ValuePoints[v0];
               Wave.ValueVertex[1] = Points.ValuePoints[v1];
               Wave.ValueVertex[2] = Points.ValuePoints[v2];
               Wave.ValueVertex[3] = Points.ValuePoints[v3];
               Wave.ValueVertex[4] = 0;
               Wave.ValueVertex[5] = 0;
               Wave.IndexVertex[0] = Points.IndexPoints[v0];
               Wave.IndexVertex[1] = Points.IndexPoints[v1];
               Wave.IndexVertex[2] = Points.IndexPoints[v2];
               Wave.IndexVertex[3] = Points.IndexPoints[v3];
               Wave.IndexVertex[4] = 0;
               Wave.IndexVertex[5] = 0;
               // check the wave by the rules
               if(WaveRules(Wave)==true)
                 {
                  // if the wave passed the check by the rules, add it to the waves tree
                  ParentNode=Node.Add(NameWave,Wave);
                  I=1;
                  // create the first sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(i));
                  // if the interval the chart, corresponding to the first sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the second sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(i));
                  // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the third sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                 }
               // otherwise, if the wave did not pass the check by the rules, release the memory
               else delete Wave;
              }
           }
         v2=v2+2;
        }
      v1=v1+2;
     }
   // find no less than six points on the price chart and put them into the structure Points
   // if none were found, then exit the function
   if(FindPoints(6,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false)return;
   // loop of the complete waves with the formula "1-2-3-4-5"
   v0 = 0;
   v1 = 1;
   v5 = Points.NumPoints - 1;
   while(v1<=v5-4)
     {
      v2=v1+1;
      while(v2<=v5-3)
        {
         v3=v2+1;
         while(v3<=v5-2)
           {
            v4=v3+1;
            while(v4<=v5-1)
              {
               int j=0;
               while(j<=i-1)
                 {
                  // get the name of the wave for analysis from ListNameWave
                  NameWave=ListNameWave[j++];
                  // find the index of the wave in the  WaveDescription structure in order to know the number of its sub-waves and their names
                  IndexWave=FindWaveInWaveDescription(NameWave);
                  if(WaveDescription[IndexWave].NumWave==5)
                    {
                     // create the object of TWave class and fill its fields - parameters of the analyzed wave
                     Wave=new TWave;
                     Wave.Name=NameWave;
                     Wave.Level=Level;
                     Wave.Formula="1-2-3-4-5";
                     Wave.ValueVertex[0] = Points.ValuePoints[v0];
                     Wave.ValueVertex[1] = Points.ValuePoints[v1];
                     Wave.ValueVertex[2] = Points.ValuePoints[v2];
                     Wave.ValueVertex[3] = Points.ValuePoints[v3];
                     Wave.ValueVertex[4] = Points.ValuePoints[v4];
                     Wave.ValueVertex[5] = Points.ValuePoints[v5];
                     Wave.IndexVertex[0] = Points.IndexPoints[v0];
                     Wave.IndexVertex[1] = Points.IndexPoints[v1];
                     Wave.IndexVertex[2] = Points.IndexPoints[v2];
                     Wave.IndexVertex[3] = Points.IndexPoints[v3];
                     Wave.IndexVertex[4] = Points.IndexPoints[v4];
                     Wave.IndexVertex[5] = Points.IndexPoints[v5];
                     // check the wave by the rules
                     if(WaveRules(Wave)==true)
                       {
                        // if the wave passed the check by the rules, add it to the waves tree
                        ParentNode=Node.Add(NameWave,Wave);
                        I=1;
                        // create the first sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the first sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the second sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the second sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the fourth sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the fifth sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the fifth sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                       }
                     // otherwise, if the wave did not pass the check by the rules, release the memory
                     else delete Wave;
                    }
                 }
               v4=v4+2;
              }
            v3=v3+2;
           }
         v2=v2+2;
        }
      v1=v1+2;
     }
  }
//+------------------------------------------------------------------+
//| The NotStartedWaves function                                     |
//+------------------------------------------------------------------+
void NotStartedWaves(TWave *ParentWave,int NumWave,TNode *Node,string Subwaves,int Level)
  {
   int v1,v2,v3,v4,v5,I;
   TPoints Points;
   TNode *ParentNode,*ChildNode;
   int IndexWave;
   string NameWave;
   TWave *Wave;
   int i=0,Pos=0,Start=0;
   // in the ListNameWave array put the waves, which we will be analyzing
   string ListNameWave[];
   ArrayResize(ListNameWave,ArrayRange(WaveDescription,0));
   while(Pos!=StringLen(Subwaves)-1)
     {
      Pos=StringFind(Subwaves,",",Start);
      NameWave=StringSubstr(Subwaves,Start,Pos-Start);
      ListNameWave[i++]=NameWave;
      Start=Pos+1;
     }
   int IndexStart=ParentWave.IndexVertex[NumWave-1];
   int IndexFinish=ParentWave.IndexVertex[NumWave];
   double ValueStart = ParentWave.ValueVertex[NumWave - 1];
   double ValueFinish= ParentWave.ValueVertex[NumWave];
   // find no less than two points on the price chart and put them into the Points structure
   // if we didn't find any, then exit the function
   if(FindPoints(2,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false)return;
   // the loop of the unbegun waves with the formula "4<-5"
   v5=Points.NumPoints-1;
   v4=v5-1;
   while(v4>=0)
     {
      int j=0;
      while(j<=i-1)
        {
         // get the name of the wave for analysis from the ListNameWave
         NameWave=ListNameWave[j++];
         // find the index of the wave in the WaveDescription structure in order to know the number of its sub-waves and their names
         IndexWave=FindWaveInWaveDescription(NameWave);
         if(WaveDescription[IndexWave].NumWave==5)
           {
            // create the object of TWave class and fill its fields - parameters of the analyzed wave
            Wave=new TWave;
            Wave.Name=NameWave;
            Wave.Level=Level;
            Wave.Formula="4<-5";
            Wave.ValueVertex[0] = 0;
            Wave.ValueVertex[1] = 0;
            Wave.ValueVertex[2] = 0;
            Wave.ValueVertex[3] = 0;
            Wave.ValueVertex[4] = Points.ValuePoints[v4];
            Wave.ValueVertex[5] = Points.ValuePoints[v5];
            Wave.IndexVertex[0] = 0;
            Wave.IndexVertex[1] = 0;
            Wave.IndexVertex[2] = 0;
            Wave.IndexVertex[3] = IndexStart;
            Wave.IndexVertex[4] = Points.IndexPoints[v4];
            Wave.IndexVertex[5] = Points.IndexPoints[v5];
            // check the wave by the rules
            if(WaveRules(Wave)==true)
              {
               // if the wave passed the check by the rules, add it to the waves tree
               ParentNode=Node.Add(NameWave,Wave);
               I=4;
               // create the fourth sub-wave in the wave tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
               I++;
               // create 5th sub-wave in the waves tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the fifth sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
              }
            // otherwise, if the wave did not pass the check by the rules, release the memory
            else delete Wave;
           }
        }
      v4=v4-2;
     }
   // the loop of the unbegun waves with the formula "2<-3"
   v3=Points.NumPoints-1;
   v2=v3-1;
   while(v2>=0)
     {
      int j=0;
      while(j<=i-1)
        {
         // get the name of the wave for analysis from ListNameWave
         NameWave=ListNameWave[j++];
         // find the index of the wave in the WaveDescription structure in order to know the number of its sub-waves and their names
         IndexWave=FindWaveInWaveDescription(NameWave);
         if(WaveDescription[IndexWave].NumWave==3)
           {
            // create the object of TWave class and fill its fields - parameters of the analyzed wave
            Wave=new TWave;
            Wave.Name=NameWave;
            Wave.Level=Level;
            Wave.Formula="2<-3";
            Wave.ValueVertex[0] = 0;
            Wave.ValueVertex[1] = 0;
            Wave.ValueVertex[2] = Points.ValuePoints[v2];
            Wave.ValueVertex[3] = Points.ValuePoints[v3];
            Wave.ValueVertex[4] = 0;
            Wave.ValueVertex[5] = 0;
            Wave.IndexVertex[0] = 0;
            Wave.IndexVertex[1] = IndexStart;
            Wave.IndexVertex[2] = Points.IndexPoints[v2];
            Wave.IndexVertex[3] = Points.IndexPoints[v3];
            Wave.IndexVertex[4] = 0;
            Wave.IndexVertex[5] = 0;
            // check the wave by the rules
            if(WaveRules(Wave)==true)
              {
               // if the wave passed the check by the rules, add it to the waves tree
               ParentNode=Node.Add(NameWave,Wave);
               I=2;
               // create the second sub-wave in the waves tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
               I++;
               // create the third sub-wave in the waves tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
              }
            // otherwise, if the wave did not pass by the rules, release the memory
            else delete Wave;
           }
        }
      v2=v2-2;
     }
   // find not less than three points on the price chart and put them into the Points structure 
   // if we didn't find any, then exit the function
   if(FindPoints(3,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false)return;
   // loop the unbegun waves with the formula "3<-4-5"
   v5=Points.NumPoints-1;
   v4=v5-1;
   while(v4>=1)
     {
      v3=v4-1;
      while(v3>=0)
        {
         int j=0;
         while(j<=i-1)
           {
            // get the name of the wave for analysis from ListNameWave
            NameWave=ListNameWave[j++];
            // find the index of the wave in the  WaveDescription structure in order to know the number of sub-waves and their name
            IndexWave=FindWaveInWaveDescription(NameWave);
            if(WaveDescription[IndexWave].NumWave==5)
              {
               // create the object of class TWave and fill its fields - parameters of the analyzed wave
               Wave=new TWave;
               Wave.Name=NameWave;
               Wave.Level=Level;
               Wave.Formula="3<-4-5";
               Wave.ValueVertex[0] = 0;
               Wave.ValueVertex[1] = 0;
               Wave.ValueVertex[2] = 0;
               Wave.ValueVertex[3] = Points.ValuePoints[v3];
               Wave.ValueVertex[4] = Points.ValuePoints[v4];
               Wave.ValueVertex[5] = Points.ValuePoints[v5];
               Wave.IndexVertex[0] = 0;
               Wave.IndexVertex[1] = 0;
               Wave.IndexVertex[2] = IndexStart;
               Wave.IndexVertex[3] = Points.IndexPoints[v3];
               Wave.IndexVertex[4] = Points.IndexPoints[v4];
               Wave.IndexVertex[5] = Points.IndexPoints[v5];
               // check the wave by the rules
               if(WaveRules(Wave)==true)
                 {
                  // if the wave passed the check by the rules, add it to the waves tree
                  ParentNode=Node.Add(NameWave,Wave);
                  I=3;
                  // create the three sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the fourth sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the fifth sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the fifth sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                 }
               // otherwise, if the wave did not pass by the rules, release the memory
               else delete Wave;
              }
           }
         v3=v3-2;
        }
      v4=v4-2;
     }
   // the loop of the unbegun waves with the formula "1<-2-3"
   v3=Points.NumPoints-1;
   v2=v3-1;
   while(v2>=1)
     {
      v1=v2-1;
      while(v1>=0)
        {
         int j=0;
         while(j<=i-1)
           {
            // get the name of the wave for analysis from ListNameWave
            NameWave=ListNameWave[j++];
            // find the index of the wave in the WaveDescription structure in order to know the number of sub-waves and their names
            IndexWave=FindWaveInWaveDescription(NameWave);
            if(WaveDescription[IndexWave].NumWave==3)
              {
               // create the object of TWave class and fill its fields - parameters of the analyzed wave
               Wave=new TWave;
               Wave.Name=NameWave;
               Wave.Level=Level;
               Wave.Formula="1<-2-3";
               Wave.ValueVertex[0] = 0;
               Wave.ValueVertex[1] = Points.ValuePoints[v1];
               Wave.ValueVertex[2] = Points.ValuePoints[v2];
               Wave.ValueVertex[3] = Points.ValuePoints[v3];
               Wave.ValueVertex[4] = 0;
               Wave.ValueVertex[5] = 0;
               Wave.IndexVertex[0] = IndexStart;
               Wave.IndexVertex[1] = Points.IndexPoints[v1];
               Wave.IndexVertex[2] = Points.IndexPoints[v2];
               Wave.IndexVertex[3] = Points.IndexPoints[v3];
               Wave.IndexVertex[4] = 0;
               Wave.IndexVertex[5] = 0;
               // check the wave by the rules
               if(WaveRules(Wave)==true)
                 {
                  // if the wave passed the check by the rules, add it to the waves tree
                  ParentNode=Node.Add(NameWave,Wave);
                  I=1;
                  // create the first sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // f the interval of the chart, corresponding to the first sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the second sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create a third sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                 }
               // otherwise, if the wave did not pass by the rules, release the memory
               else delete Wave;
              }
           }
         v1=v1-2;
        }
      v2=v2-2;
     }
   // find no less than four point on the price chart and put them into the Points structure 
   // if we didn't find any, then exit the function
   if(FindPoints(4,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false)return;
   // the loop of unbegun and unfinished waves with the formula "1<-2-3-4-5>"
   v5=Points.NumPoints-1;
   v4=v5-1;
   while(v4>=2)
     {
      v3=v4-1;
      while(v3>=1)
        {
         v2=v3-1;
         while(v2>=0)
           {
            int j=0;
            while(j<=i-1)
              {
               // get the name of the wave for analysis from the ListNameWave
               NameWave=ListNameWave[j++];
               // find the index of the wave in the WaveDescription structure in order to know the number of sub-waves and their names
               IndexWave=FindWaveInWaveDescription(NameWave);
               if(WaveDescription[IndexWave].NumWave==5)
                 {
                  // create the object of TWave class and fill its fields - parameters of the analyzed wave
                  Wave=new TWave;
                  Wave.Name=NameWave;
                  Wave.Level=Level;
                  Wave.Formula="2<-3-4-5";
                  Wave.ValueVertex[0] = 0;
                  Wave.ValueVertex[1] = 0;
                  Wave.ValueVertex[2] = Points.ValuePoints[v2];
                  Wave.ValueVertex[3] = Points.ValuePoints[v3];
                  Wave.ValueVertex[4] = Points.ValuePoints[v4];
                  Wave.ValueVertex[5] = Points.ValuePoints[v5];
                  Wave.IndexVertex[0] = 0;
                  Wave.IndexVertex[1] = IndexStart;
                  Wave.IndexVertex[2] = Points.IndexPoints[v2];
                  Wave.IndexVertex[3] = Points.IndexPoints[v3];
                  Wave.IndexVertex[4] = Points.IndexPoints[v4];
                  Wave.IndexVertex[5] = Points.IndexPoints[v5];
                  // check the wave by the rules
                  if(WaveRules(Wave)==true)
                    {
                     // if the wave passed the check by the rules, add it to the waves tree
                     ParentNode=Node.Add(NameWave,Wave);
                     I=2;
                     // create the second sub-wave in the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     //  create the third sub-wave in the waved tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     // create the fourth sub-wave in the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     // create the fifth sub-wave in the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the fifth sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                    }
                  // otherwise, if the wave did not pass by the rules, release the memory
                  else delete Wave;
                 }
              }
            v2=v2-2;
           }
         v3=v3-2;
        }
      v4=v4-2;
     }
  // find no less than five points on the price chart and record it into the structure Points
  // if we didn't find any, then exit the function
   if(FindPoints(5,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false)return;
   // the loop of unbegun waves with the formula "1<-2-3-4-5"
   v5=Points.NumPoints-1;
   v4=v5-1;
   while(v4>=3)
     {
      v3=v4-1;
      while(v3>=2)
        {
         v2=v3-1;
         while(v2>=1)
           {
            v1=v2-1;
            while(v1>=0)
              {
               int j=0;
               while(j<=i-1)
                 {
                  // get the name of the wave for analysis from the ListNameWave
                  NameWave=ListNameWave[j++];
                  // find the index of the wave in the WaveDescription structure in order to know the number of sub-waves and their names
                  IndexWave=FindWaveInWaveDescription(NameWave);
                  if(WaveDescription[IndexWave].NumWave==5)
                    {
                     // create the object of class TWave and fill its fields - parameters of the analyzed wave
                     Wave=new TWave;
                     Wave.Name=NameWave;
                     Wave.Level=Level;
                     Wave.Formula="1<-2-3-4-5";
                     Wave.ValueVertex[0] = 0;
                     Wave.ValueVertex[1] = Points.ValuePoints[v1];
                     Wave.ValueVertex[2] = Points.ValuePoints[v2];
                     Wave.ValueVertex[3] = Points.ValuePoints[v3];
                     Wave.ValueVertex[4] = Points.ValuePoints[v4];
                     Wave.ValueVertex[5] = Points.ValuePoints[v5];
                     Wave.IndexVertex[0] = IndexStart;
                     Wave.IndexVertex[1] = Points.IndexPoints[v1];
                     Wave.IndexVertex[2] = Points.IndexPoints[v2];
                     Wave.IndexVertex[3] = Points.IndexPoints[v3];
                     Wave.IndexVertex[4] = Points.IndexPoints[v4];
                     Wave.IndexVertex[5] = Points.IndexPoints[v5];
                     // check the wave by the rules
                     if(WaveRules(Wave)==true)
                       {
                        // if the wave passed the check by the rules, add it to the waves tree
                        ParentNode=Node.Add(NameWave,Wave);
                        I=1;
                        // create the first sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the first sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the second sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the third sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the fourth sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the fifth sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the fifth sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                       }
                     // otherwise, if the wave did not pass by the rules, release the memory
                     else delete Wave;
                    }
                 }
               v1=v1-2;
              }
            v2=v2-2;
           }
         v3=v3-2;
        }
      v4=v4-2;
     }
  }
//+------------------------------------------------------------------+
//| The NotFinishedWaves function                                    |
//+------------------------------------------------------------------+
void NotFinishedWaves(TWave *ParentWave,int NumWave,TNode *Node,string Subwaves,int Level)
  {
   int v0,v1,v2,v3,v4,I;
   TPoints Points;
   TNode *ParentNode,*ChildNode;
   int IndexWave;
   string NameWave;
   TWave *Wave;
   int i=0,Pos=0,Start=0;
   // Put the waves, which we will be analyzing to the ListNameWave array
   string ListNameWave[];
   ArrayResize(ListNameWave,ArrayRange(WaveDescription,0));
   while(Pos!=StringLen(Subwaves)-1)
     {
      Pos=StringFind(Subwaves,",",Start);
      NameWave=StringSubstr(Subwaves,Start,Pos-Start);
      ListNameWave[i++]=NameWave;
      Start=Pos+1;
     }
   int IndexStart=ParentWave.IndexVertex[NumWave-1];
   int IndexFinish=ParentWave.IndexVertex[NumWave];
   double ValueStart = ParentWave.ValueVertex[NumWave - 1];
   double ValueFinish= ParentWave.ValueVertex[NumWave];
   // find not less than two points on the price chart and record it into the structure Points
   // if we didn't find any, then exit the function
   if(FindPoints(2,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false)return;
   // the loop of unfinished waves with the formula "1-2>"
   v0=0;
   v1=v0+1;
   while(v1<=Points.NumPoints-1)
     {
      int j=0;
      while(j<=i-1)
        {
         // get the name of the wave for analysis from the ListNameWave
         NameWave=ListNameWave[j++];
         // find the index of the wave in the WaveDescription structure in order to know the number of sub-waves and their names
         IndexWave=FindWaveInWaveDescription(NameWave);
         if((WaveDescription[IndexWave].NumWave==5) || (WaveDescription[IndexWave].NumWave==3))
           {
            // create the object of TWave class and fill its fields - parameters of the analyzed wave
            Wave=new TWave;
            Wave.Name=NameWave;
            Wave.Level=Level;
            Wave.Formula="1-2>";
            Wave.ValueVertex[0] = Points.ValuePoints[v0];
            Wave.ValueVertex[1] = Points.ValuePoints[v1];
            Wave.ValueVertex[2] = 0;
            Wave.ValueVertex[3] = 0;
            Wave.ValueVertex[4] = 0;
            Wave.ValueVertex[5] = 0;
            Wave.IndexVertex[0] = Points.IndexPoints[v0];
            Wave.IndexVertex[1] = Points.IndexPoints[v1];
            Wave.IndexVertex[2] = IndexFinish;
            Wave.IndexVertex[3] = 0;
            Wave.IndexVertex[4] = 0;
            Wave.IndexVertex[5] = 0;
            // check the wave by the rules
            if(WaveRules(Wave)==true)
              {
               // if the wave passed the check by the rules, add it to the waves tree
               ParentNode=Node.Add(NameWave,Wave);
               I=1;
               // create the first sub-wave in the waves tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the first sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
               I++;
               // create the second sub-wave in the waves tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
              }
            // otherwise, if the wave did not pass by the rules, release the memory
            else delete Wave;
           }
        }
      v1=v1+2;
     }
   // find no less than three points on the price chart and put it into the Points structure
   // if none were found, then exit the function
   if(FindPoints(3,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false)return;
   // the loop of unfinished waves with the formula "1-2-3>"
   v0=0;
   v1=v0+1;
   while(v1<=Points.NumPoints-2)
     {
      v2=v1+1;
      while(v2<=Points.NumPoints-1)
        {
         int j=0;
         while(j<=i-1)
           {
            // get the name of the wave for analysis from ListNameWave
            NameWave=ListNameWave[j++];
            // find the index of the wave in the WaveDescription structure in order to know the number of sub-waves and their names
            IndexWave=FindWaveInWaveDescription(NameWave);
            if((WaveDescription[IndexWave].NumWave==5) || (WaveDescription[IndexWave].NumWave==3))
              {
               // create the object of TWave class and fill its fields - parameters of the analyzed wave
               Wave=new TWave;
               Wave.Name=NameWave;
               Wave.Level=Level;
               Wave.Formula="1-2-3>";
               Wave.ValueVertex[0] = Points.ValuePoints[v0];
               Wave.ValueVertex[1] = Points.ValuePoints[v1];
               Wave.ValueVertex[2] = Points.ValuePoints[v2];
               Wave.ValueVertex[3] = 0;
               Wave.ValueVertex[4] = 0;
               Wave.ValueVertex[5] = 0;
               Wave.IndexVertex[0] = Points.IndexPoints[v0];
               Wave.IndexVertex[1] = Points.IndexPoints[v1];
               Wave.IndexVertex[2] = Points.IndexPoints[v2];
               Wave.IndexVertex[3] = IndexFinish;
               Wave.IndexVertex[4] = 0;
               Wave.IndexVertex[5] = 0;
               // check the wave by the rules
               if(WaveRules(Wave)==true)
                 {
                  // if the wave passed the check by the rules, add it to the waves tree
                  ParentNode=Node.Add(NameWave,Wave);
                  I=1;
                  // create the first sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the first sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the second sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the third sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, of the corresponding third sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                 }
               // otherwise, if the wave did not pass by the rules, release the memory
               else delete Wave;
              }
           }
         v2=v2+2;
        }
      v1=v1+2;
     }
   // find no less than four points on the price chart and record it into the Points structure 
   // if none were found, then exit the function
   if(FindPoints(4,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false) return;
   // the loop of unfinished waves with the formula "1-2-3-4>"
   v0=0;
   v1=v0+1;
   while(v1<=Points.NumPoints-3)
     {
      v2=v1+1;
      while(v2<=Points.NumPoints-2)
        {
         v3=v2+1;
         while(v3<=Points.NumPoints-1)
           {
            int j=0;
            while(j<=i-1)
              {
               // get the name of the wave for analysis from ListNameWave
               NameWave=ListNameWave[j++];
               // find the index of the wave in WaveDescription structure in order to know the number of sub-waves and the names
               IndexWave=FindWaveInWaveDescription(NameWave);
               if(WaveDescription[IndexWave].NumWave==5)
                 {
                  // create the object of TWave class and fill its fields - parameters of the analyzed wave
                  Wave=new TWave;
                  Wave.Name=NameWave;
                  Wave.Level=Level;
                  Wave.Formula="1-2-3-4>";
                  Wave.ValueVertex[0] = Points.ValuePoints[v0];
                  Wave.ValueVertex[1] = Points.ValuePoints[v1];
                  Wave.ValueVertex[2] = Points.ValuePoints[v2];
                  Wave.ValueVertex[3] = Points.ValuePoints[v3];
                  Wave.ValueVertex[4] = 0;
                  Wave.ValueVertex[5] = 0;
                  Wave.IndexVertex[0] = Points.IndexPoints[v0];
                  Wave.IndexVertex[1] = Points.IndexPoints[v1];
                  Wave.IndexVertex[2] = Points.IndexPoints[v2];
                  Wave.IndexVertex[3] = Points.IndexPoints[v3];
                  Wave.IndexVertex[4] = IndexFinish;
                  Wave.IndexVertex[5] = 0;
                  // check the wave by the rules
                  if(WaveRules(Wave)==true)
                    {
                     // if the wave passed the check for the rules, add it to the waves tree
                     ParentNode=Node.Add(NameWave,Wave);
                     I=1;
                     // create the first sub-wave in the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the first sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     // create the second sub-wave in the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     // create the third sub-wave in the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     // create the fourth sub-wave in the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                    }
                  // otherwise, if the wave didn't pass by the rules, release the memory
                  else delete Wave;
                 }
              }
            v3=v3+2;
           }
         v2=v2+2;
        }
      v1=v1+2;
     }
   // find no less than five points on the price chart and put them into the structure Points
   // if none were found, exit the function
   if(FindPoints(5,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false)return;
   // the loop of unfinished waves with the formula "1-2-3-4-5>"
   v0=0;
   v1=v0+1;
   while(v1<=Points.NumPoints-4)
     {
      v2=v1+1;
      while(v2<=Points.NumPoints-3)
        {
         v3=v2+1;
         while(v3<=Points.NumPoints-2)
           {
            v4=v3+1;
            while(v4<=Points.NumPoints-1)
              {
               int j=0;
               while(j<=i-1)
                 {
                  // get the name of the wave for analysis from ListNameWave
                  NameWave=ListNameWave[j++];
                  // find the index of the wave in the WaveDescription structure in order to know the number of its sub-waves and their names
                  IndexWave=FindWaveInWaveDescription(NameWave);
                  if(WaveDescription[IndexWave].NumWave==5)
                    {
                     // create the object of TWave class and fill its fields - parameters of the analyzed wave
                     Wave=new TWave;
                     Wave.Name=NameWave;
                     Wave.Level=Level;
                     Wave.Formula="1-2-3-4-5>";
                     Wave.ValueVertex[0] = Points.ValuePoints[v0];
                     Wave.ValueVertex[1] = Points.ValuePoints[v1];
                     Wave.ValueVertex[2] = Points.ValuePoints[v2];
                     Wave.ValueVertex[3] = Points.ValuePoints[v3];
                     Wave.ValueVertex[4] = Points.ValuePoints[v4];
                     Wave.ValueVertex[5] = 0;
                     Wave.IndexVertex[0] = Points.IndexPoints[v0];
                     Wave.IndexVertex[1] = Points.IndexPoints[v1];
                     Wave.IndexVertex[2] = Points.IndexPoints[v2];
                     Wave.IndexVertex[3] = Points.IndexPoints[v3];
                     Wave.IndexVertex[4] = Points.IndexPoints[v4];
                     Wave.IndexVertex[5] = IndexFinish;
                     // check the wave by the rules
                     if(WaveRules(Wave)==true)
                       {
                        // if the wave passed the check by the rules, add it to the waves tree
                        ParentNode=Node.Add(NameWave,Wave);
                        I=1;
                        // create the first sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the first sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the second sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the third sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the fourth sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the fifth sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the fifth sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                       }
                     // otherwise, if the wave did not pass by the rules, release the memory
                     else delete Wave;
                    }
                 }
               v4=v4+2;
              }
            v3=v3+2;
           }
         v2=v2+2;
        }
      v1=v1+2;
     }
  }
//+------------------------------------------------------------------+
//| The NotStartedAndNotFinishedWaves function                       |
//+------------------------------------------------------------------+
void NotStartedAndNotFinishedWaves(TWave *ParentWave,int NumWave,TNode *Node,string Subwaves,int Level)
  {
   int v1,v2,v3,v4,I;
   TPoints Points;
   TNode *ParentNode,*ChildNode;
   int IndexWave;
   string NameWave;
   TWave *Wave;
   int i=0,pos=0,start=0;
   // Put the waves, which we will be analyzing to the ListNameWave array
   string ListNameWave[];
   ArrayResize(ListNameWave,ArrayRange(WaveDescription,0));
   while(pos!=StringLen(Subwaves)-1)
     {
      pos=StringFind(Subwaves,",",start);
      NameWave=StringSubstr(Subwaves,start,pos-start);
      ListNameWave[i++]=NameWave;
      start=pos+1;
     }
   int IndexStart=ParentWave.IndexVertex[NumWave-1];
   int IndexFinish=ParentWave.IndexVertex[NumWave];
   double ValueStart = ParentWave.ValueVertex[NumWave - 1];
   double ValueFinish= ParentWave.ValueVertex[NumWave];
   // find no less than two points on the price chart and put them into the structure Points
   // if they are not found, then exit the function
   if(FindPoints(2,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false)return;
   // the loop of unbegun and incomplete waves with the formula "1<-2-3>"
   v1=0;
   while(v1<=Points.NumPoints-2)
     {
      v2=v1+1;
      while(v2<=Points.NumPoints-1)
        {
         int j=0;
         while(j<=i-1)
           {
            // get the name of the wave for analysis from the ListNameWave
            NameWave=ListNameWave[j++];
            // find the index of the wave in the structure WaveDescription in order to
            // find out the number of its sub-waves and their names
            
            IndexWave=FindWaveInWaveDescription(NameWave);
            if((WaveDescription[IndexWave].NumWave==5) || (WaveDescription[IndexWave].NumWave==3))
              {
               // create the object of TWave class and fill its fields - parameters of the analyzed waves
               Wave=new TWave;
               Wave.Name=NameWave;
               Wave.Level=Level;
               Wave.Formula="1<-2-3>";
               Wave.ValueVertex[0] = 0;
               Wave.ValueVertex[1] = Points.ValuePoints[v1];
               Wave.ValueVertex[2] = Points.ValuePoints[v2];
               Wave.ValueVertex[3] = 0;
               Wave.ValueVertex[4] = 0;
               Wave.ValueVertex[5] = 0;
               Wave.IndexVertex[0] = IndexStart;
               Wave.IndexVertex[1] = Points.IndexPoints[v1];
               Wave.IndexVertex[2] = Points.IndexPoints[v2];
               Wave.IndexVertex[3] = IndexFinish;
               Wave.IndexVertex[4] = 0;
               Wave.IndexVertex[5] = 0;
               // check the wave by the rules
               if(WaveRules(Wave)==true)
                 {
                  // if a wave passed the check by rules, add it into the wave tree
                  ParentNode=Node.Add(NameWave,Wave);
                  I=1;
                  // create the first sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the first sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the second sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create a third sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                   // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                 }
               // otherwise, if the wave did not pass by the rules, release the memory
               else delete Wave;
              }
           }
         v2=v2+2;
        }
      v1=v1+2;
     }
   // the loop of unbegun and unfinished waves with the formula "2<-3-4>"
   v2=0;
   while(v2<=Points.NumPoints-2)
     {
      v3=v2+1;
      while(v3<=Points.NumPoints-1)
        {
         int j=0;
         while(j<=i-1)
           {
            // get the name of the wave for analysis from the ListNameWave
            NameWave=ListNameWave[j++];
            // find the index of the wave in the WaveDescription structure in order to know the number of its symbols and its names
            IndexWave=FindWaveInWaveDescription(NameWave);
            if(WaveDescription[IndexWave].NumWave==5)
              {
               // create the object of TWave class and fill its fields - parameters of the analyzed wave
               Wave=new TWave;
               Wave.Name=NameWave;
               Wave.Level=Level;
               Wave.Formula="2<-3-4>";
               Wave.ValueVertex[0] = 0;
               Wave.ValueVertex[1] = 0;
               Wave.ValueVertex[2] = Points.ValuePoints[v2];
               Wave.ValueVertex[3] = Points.ValuePoints[v3];
               Wave.ValueVertex[4] = 0;
               Wave.ValueVertex[5] = 0;
               Wave.IndexVertex[0] = 0;
               Wave.IndexVertex[1] = IndexStart;
               Wave.IndexVertex[2] = Points.IndexPoints[v2];
               Wave.IndexVertex[3] = Points.IndexPoints[v3];
               Wave.IndexVertex[4] = IndexFinish;
               Wave.IndexVertex[5] = 0;
               // check the wave by the rules
               if(WaveRules(Wave)==true)
                 {
                  // if the wave passed the check for rules, add it to the waves tree
                  ParentNode=Node.Add(NameWave,Wave);
                  I=2;
                  // create the second sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the third sub-wave in th waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the fourth sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                 }
               // otherwise, if the wave did not pass the check by rules, release the memory
               else delete Wave;
              }
           }
         v3=v3+2;
        }
      v2=v2+2;
     }
   // the loop of the unbegun and the incomplete waves with the formula "3<-4-5>"
   v3=0;
   while(v3<=Points.NumPoints-2)
     {
      v4=v3+1;
      while(v4<=Points.NumPoints-1)
        {
         int j=0;
         while(j<=i-1)
           {
            // get the name of the wave for analysis from the ListNameWave
            NameWave=ListNameWave[j++];
            // find the index of the wave in the WaveDescription structure in order to
            // find out the number of its symbols and their names
            IndexWave=FindWaveInWaveDescription(NameWave);
            if(WaveDescription[IndexWave].NumWave==5)
              {
               // create the object of TWave class and fill its fields - parameters of the analyzed wave
               Wave=new TWave;
               Wave.Name=NameWave;
               Wave.Level=Level;
               Wave.Formula="3<-4-5>";
               Wave.ValueVertex[0] = 0;
               Wave.ValueVertex[1] = 0;
               Wave.ValueVertex[2] = 0;
               Wave.ValueVertex[3] = Points.ValuePoints[v3];
               Wave.ValueVertex[4] = Points.ValuePoints[v4];
               Wave.ValueVertex[5] = 0;
               Wave.IndexVertex[0] = 0;
               Wave.IndexVertex[1] = 0;
               Wave.IndexVertex[2] = IndexStart;
               Wave.IndexVertex[3] = Points.IndexPoints[v3];
               Wave.IndexVertex[4] = Points.IndexPoints[v4];
               Wave.IndexVertex[5] = IndexFinish;
               // check the wave for the rules
               if(WaveRules(Wave)==true)
                 {
                  // if the wave passed the check by the rules, add it to the waves tree
                  ParentNode=Node.Add(NameWave,Wave);
                  I=3;
                  // create the third sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the third sub-wave has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the fourth sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                  I++;
                  // create the fifth sub-wave in the waves tree
                  ChildNode=ParentNode.Add(IntegerToString(I));
                  // if the interval of the chart, corresponding to the fifth wave, has not been analyzed, then analyze it
                  if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                     NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                 }
               // otherwise, if the wave has not passed the check by the rules, release the memory
               else delete Wave;
              }
           }
         v4=v4+2;
        }
      v3=v3+2;
     }
   // find no less than three points on the price chart and put them in the Points structure
   // if they were not found, then exit the function
   if(FindPoints(3,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false) return;
   // the loop of unbegun and unfinished waved with the formula "1<-2-3-4>"
   v1=0;
   while(v1<=Points.NumPoints-3)
     {
      v2=v1+1;
      while(v2<=Points.NumPoints-2)
        {
         v3=v2+1;
         while(v3<=Points.NumPoints-1)
           {
            int j=0;
            while(j<=i-1)
              {
               // get the name of the wave for analysis from the ListNameWave
               NameWave=ListNameWave[j++];
               // find the index of the wave in the WaveDescription structure in order to know the number of its sub-waves and their names
               IndexWave=FindWaveInWaveDescription(NameWave);
               if(WaveDescription[IndexWave].NumWave==5)
                 {
                  // create an object of TWave class and fill its fields - parameters of the analyzed wave
                  Wave=new TWave;
                  Wave.Name=NameWave;
                  Wave.Level=Level;
                  Wave.Formula="1<-2-3-4>";
                  Wave.ValueVertex[0] = 0;
                  Wave.ValueVertex[1] = Points.ValuePoints[v1];
                  Wave.ValueVertex[2] = Points.ValuePoints[v2];
                  Wave.ValueVertex[3] = Points.ValuePoints[v3];
                  Wave.ValueVertex[4] = 0;
                  Wave.ValueVertex[5] = 0;
                  Wave.IndexVertex[0] = IndexStart;
                  Wave.IndexVertex[1] = Points.IndexPoints[v1];
                  Wave.IndexVertex[2] = Points.IndexPoints[v2];
                  Wave.IndexVertex[3] = Points.IndexPoints[v3];
                  Wave.IndexVertex[4] = IndexFinish;
                  Wave.IndexVertex[5] = 0;
                  // check the wave by the rules
                  if(WaveRules(Wave)==true)
                    {
                     // if the wave passed the check by the rules, add it to the waves tree
                     ParentNode=Node.Add(NameWave,Wave);
                     I=1;
                     // create the first sub-wave in the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the first sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     // create the second sub-wave in the waved tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     // create the third sub-wave in the waves
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     // create the fourth sub-wave of the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                    }
                  // otherwise, if the wave did not pass by the rules, release the memory
                  else delete Wave;
                 }
              }
            v3=v3+2;
           }
         v2=v2+2;
        }
      v1=v1+2;
     }
   // the loop of unbegun and unfinished waves with the formula "2<-3-4-5>"
   v2=0;
   while(v2<=Points.NumPoints-3)
     {
      v3=v2+1;
      while(v3<=Points.NumPoints-2)
        {
         v4=v3+1;
         while(v4<=Points.NumPoints-1)
           {
            int j=0;
            while(j<=i-1)
              {
               // get the name of the wave for analysis from the ListNameWave
               NameWave=ListNameWave[j++];
               // find the index of the wave in the WaveDescription structure in order to know the number of the symbols and their names
               IndexWave=FindWaveInWaveDescription(NameWave);
               if(WaveDescription[IndexWave].NumWave==5)
                 {
                  // create the object of TWave class and fill its fields - parameters of the analyzed wave
                  Wave=new TWave;
                  Wave.Name=NameWave;
                  Wave.Level=Level;
                  Wave.Formula="2<-3-4-5>";
                  Wave.ValueVertex[0] = 0;
                  Wave.ValueVertex[1] = 0;
                  Wave.ValueVertex[2] = Points.ValuePoints[v2];
                  Wave.ValueVertex[3] = Points.ValuePoints[v3];
                  Wave.ValueVertex[4] = Points.ValuePoints[v4];
                  Wave.ValueVertex[5] = 0;
                  Wave.IndexVertex[0] = 0;
                  Wave.IndexVertex[1] = IndexStart;
                  Wave.IndexVertex[2] = Points.IndexPoints[v2];
                  Wave.IndexVertex[3] = Points.IndexPoints[v3];
                  Wave.IndexVertex[4] = Points.IndexPoints[v4];
                  Wave.IndexVertex[5] = IndexFinish;
                  // check the wave by the rules
                  if(WaveRules(Wave)==true)
                    {
                     // if the wave passed the check by the rules, add it to the waves tree
                     ParentNode=Node.Add(NameWave,Wave);
                     I=2;
                     // create the second sub-wave in the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     // create the third sub-wave in the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     // create the fourth sub-wave in the waves tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                     I++;
                     // create the fifth sub-wave in the waved tree
                     ChildNode=ParentNode.Add(IntegerToString(I));
                     // if the interval of the chart, corresponding to the fifth sub-wave, has not been analyzed, then analyze it
                     if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                        NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                    }
                  // otherwise, if the wave has not passed by the rules, release the memory
                  else delete Wave;
                 }
              }
            v4=v4+2;
           }
         v3=v3+2;
        }
      v2=v2+2;
     }
   // find no less than four point on the price chart and put them into the Points structure 
   // if we didn't find any, then exit the function
   if(FindPoints(4,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false) return;
   // the loop of unbegun and unfinished waves with the formula "1<-2-3-4-5>"
   v1=0;
   while(v1<=Points.NumPoints-4)
     {
      v2=v1+1;
      while(v2<=Points.NumPoints-3)
        {
         v3=v2+1;
         while(v3<=Points.NumPoints-2)
           {
            v4=v3+1;
            while(v4<=Points.NumPoints-1)
              {
               int j=0;
               while(j<=i-1)
                 {
                  // get the name of the wave for analysis from the ListNameWave
                  NameWave=ListNameWave[j++];
                  // find the index of the wave in the WaveDescription structure in order to know the number of sub-waves and their names
                  IndexWave=FindWaveInWaveDescription(NameWave);
                  if(WaveDescription[IndexWave].NumWave==5)
                    {
                     // create the object TWave class and fill its fields - parameters of the analyzed wave
                     Wave=new TWave;
                     Wave.Name=NameWave;
                     Wave.Level=Level;
                     Wave.Formula="1<-2-3-4-5>";
                     Wave.ValueVertex[0] = 0;
                     Wave.ValueVertex[1] = Points.ValuePoints[v1];
                     Wave.ValueVertex[2] = Points.ValuePoints[v2];
                     Wave.ValueVertex[3] = Points.ValuePoints[v3];
                     Wave.ValueVertex[4] = Points.ValuePoints[v4];
                     Wave.ValueVertex[5] = 0;
                     Wave.IndexVertex[0] = IndexStart;
                     Wave.IndexVertex[1] = Points.IndexPoints[v1];
                     Wave.IndexVertex[2] = Points.IndexPoints[v2];
                     Wave.IndexVertex[3] = Points.IndexPoints[v3];
                     Wave.IndexVertex[4] = Points.IndexPoints[v4];
                     Wave.IndexVertex[5] = IndexFinish;
                     // check the wave by the rules
                     if(WaveRules(Wave)==true)
                       {
                        // if the wave passed the check by the rules, add it to the waves tree
                        ParentNode=Node.Add(NameWave,Wave);
                        I=1;
                        // create the first sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the first sub-wave has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the second sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the third sub-wave in the waves tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the fourth sub-wave in the waved tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           FinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                        I++;
                        // create the 5th sub-wave in the wave tree
                        ChildNode=ParentNode.Add(IntegerToString(I));
                        // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
                        if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                           NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
                       }
                     // otherwise, if the wave did not pass the check by the rules, release the memory
                     else delete Wave;
                    }
                 }
               v4=v4+2;
              }
            v3=v3+2;
           }
         v2=v2+2;
        }
      v1=v1+2;
     }
   // find no less than one point on the price chart and record it into the structure Points
   // if we didn't find any, then exit the function
   if(FindPoints(1,IndexStart,IndexFinish,ValueStart,ValueFinish,Points)==false)return;
   // the loop of unbegun and unfinished waves with the formula "1<-2>"
   v1=0;
   while(v1<=Points.NumPoints-1)
     {
      int j=0;
      while(j<=i-1)
        {
         // get the name of the wave for analysis from ListNameWave
         NameWave=ListNameWave[j++];
         // find the index of the wave in the WaveDescription structure in order to know the number of sub-waves and their names
         IndexWave=FindWaveInWaveDescription(NameWave);
         if(WaveDescription[IndexWave].NumWave==5 || WaveDescription[IndexWave].NumWave==3)
           {
            // create the object of TWave class and fill its fields - parameters of the analyzed wave
            Wave=new TWave;
            Wave.Name=NameWave;
            Wave.Level=Level;
            Wave.Formula="1<-2>";
            Wave.ValueVertex[0] = 0;
            Wave.ValueVertex[1] = Points.ValuePoints[v1];
            Wave.ValueVertex[2] = 0;
            Wave.ValueVertex[3] = 0;
            Wave.ValueVertex[4] = 0;
            Wave.ValueVertex[5] = 0;
            Wave.IndexVertex[0] = IndexStart;
            Wave.IndexVertex[1] = Points.IndexPoints[v1];
            Wave.IndexVertex[2] = IndexFinish;
            Wave.IndexVertex[3] = 0;
            Wave.IndexVertex[4] = 0;
            Wave.IndexVertex[5] = 0;
            // check the wave by the rules
            if(WaveRules(Wave)==true)
              {
               // if the wave passed the check by the rules, add it to the waves tree
               ParentNode=Node.Add(NameWave,Wave);
               I=1;
               // create the first sub-wave in the waves tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the first sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
               I++;
               // create the second sub-wave in the waved tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
              }
            // otherwise, if the wave did not pass the check by the rules, release the memory
            else delete Wave;
           }
        }
      v1=v1+1;
     }
   // loop the unbegun and unfinished waves with the formula "2<-3>"
   v2=0;
   while(v2<=Points.NumPoints-1)
     {
      int j=0;
      while(j<=i-1)
        {
         // get the name of the wave for analysis from ListNameWave
         NameWave=ListNameWave[j++];
         // find the index of the wave in the WaveDescription structure, in order to know the number of its sub-waves and their names
         IndexWave=FindWaveInWaveDescription(NameWave);
         if(WaveDescription[IndexWave].NumWave==5 || WaveDescription[IndexWave].NumWave==3)
           {
            // create the object of TWave class and fill its fields - parameters of the analyzed wave
            Wave=new TWave;
            Wave.Name=NameWave;
            Wave.Level=Level;
            Wave.Formula="2<-3>";
            Wave.ValueVertex[0] = 0;
            Wave.ValueVertex[1] = 0;
            Wave.ValueVertex[2] = Points.ValuePoints[v2];
            Wave.ValueVertex[3] = 0;
            Wave.ValueVertex[4] = 0;
            Wave.ValueVertex[5] = 0;
            Wave.IndexVertex[0] = 0;
            Wave.IndexVertex[1] = IndexStart;
            Wave.IndexVertex[2] = Points.IndexPoints[v2];
            Wave.IndexVertex[3] = IndexFinish;
            Wave.IndexVertex[4] = 0;
            Wave.IndexVertex[5] = 0;
            // check the wave by the rules
            if(WaveRules(Wave)==true)
              {
               // if the wave passed the check by the rules, add it to the waves tree
               ParentNode=Node.Add(NameWave,Wave);
               I=2;
               // create the second sub-wave in the waves tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the second sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
               I++;
               // create the third sub-wave in the waved tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
              }
            // otherwise, if the wave did not pass by the rules, release the memory
            else delete Wave;
           }
        }
      v2=v2+1;
     }
   // the loop of unbegun and unfinished waves with the formula "3<-4>"
   v3=0;
   while(v3<=Points.NumPoints-1)
     {
      int j=0;
      while(j<=i-1)
        {
         // get the name of the wave for analysis from ListNameWave
         NameWave=ListNameWave[j++];
         // find the index of the wave in the WaveDescription structure on order to know the number of sub-waved and their names
         IndexWave=FindWaveInWaveDescription(NameWave);
         if(WaveDescription[IndexWave].NumWave==5)
           {
            // create the object of TWave class and fill its fields - parameters of the analyzed wave
            Wave=new TWave;
            Wave.Name=NameWave;
            Wave.Level=Level;
            Wave.Formula="3<-4>";
            Wave.ValueVertex[0] = 0;
            Wave.ValueVertex[1] = 0;
            Wave.ValueVertex[2] = 0;
            Wave.ValueVertex[3] = Points.ValuePoints[v3];
            Wave.ValueVertex[4] = 0;
            Wave.ValueVertex[5] = 0;
            Wave.IndexVertex[0] = 0;
            Wave.IndexVertex[1] = 0;
            Wave.IndexVertex[2] = IndexStart;
            Wave.IndexVertex[3] = Points.IndexPoints[v3];
            Wave.IndexVertex[4] = IndexFinish;
            Wave.IndexVertex[5] = 0;
            // check the wave by the rules
            if(WaveRules(Wave)==true)
              {
               // if the wave passed the check by the rules, add it to the waves tree
               ParentNode=Node.Add(NameWave,Wave);
               I=3;
               // create the third sub-wave in the waves tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the third sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
               I++;
               // create the fourth sub-wave in the waves tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
              }
            // otherwise, if the wave did not pass by the rules, release the memory
            else delete Wave;
           }
        }
      v3=v3+1;
     }
   // the loop of unbegun and unfinished waves with the formula "4<-5>"
   v4=0;
   while(v4<=Points.NumPoints-1)
     {
      int j=0;
      while(j<=i-1)
        {
         // get the name of the wave for analysis from ListNameWave
         NameWave=ListNameWave[j++];
         // find the index of the wave in the WaveDescription structure in order to know the number of symbols and their names
         IndexWave=FindWaveInWaveDescription(NameWave);
         if(WaveDescription[IndexWave].NumWave==5)
           {
            // create the object of TWave class and fill its fields - parameters of the analyzed wave
            Wave=new TWave;
            Wave.Name=NameWave;
            Wave.Level=Level;
            Wave.Formula="4<-5>";
            Wave.ValueVertex[0] = 0;
            Wave.ValueVertex[1] = 0;
            Wave.ValueVertex[2] = 0;
            Wave.ValueVertex[3] = 0;
            Wave.ValueVertex[4] = Points.ValuePoints[v4];
            Wave.ValueVertex[5] = 0;
            Wave.IndexVertex[0] = 0;
            Wave.IndexVertex[1] = 0;
            Wave.IndexVertex[2] = 0;
            Wave.IndexVertex[3] = IndexStart;
            Wave.IndexVertex[4] = Points.IndexPoints[v4];
            Wave.IndexVertex[5] = IndexFinish;
            // check the wave by the rules
            if(WaveRules(Wave)==true)
              {
               // if the wave passed the check by the rules, add it to the waves tree
               ParentNode=Node.Add(NameWave,Wave);
               I=4;
               // create the fourth sub-wave in the waves tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the fourth sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  NotStartedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
               I++;
               // reate the fifth sub-wave in the waves tree
               ChildNode=ParentNode.Add(IntegerToString(I));
               // if the interval of the chart, corresponding to the fifth sub-wave, has not been analyzed, then analyze it
               if(Already(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I])==false)
                  NotFinishedWaves(Wave,I,ChildNode,WaveDescription[IndexWave].Subwaves[I],Level+1);
              }
            // otherwise, if the wave did not pass by the rules, release the memory
            else delete Wave;
           }
        }
      v4=v4+1;
     }
  }
//+------------------------------------------------------------------+
