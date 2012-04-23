//+------------------------------------------------------------------+
//|                                              Rules functions.mqh |
//|                                                  Roman Martynyuk |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Roman Martynyuk"
#property link      "http://www.mql5.com"
int IndexVertex[6];                          // Wave Vertex indexes
double ValueVertex[6],Maximum[6],Minimum[6]; // the values of the vertex of the wave and maximum and minimum values of the wave
string Trend;                                // trend direction - "Up" or "Down"
string Formula;                              // wave formula - "1<-2-3>" or "1-2-3>" etc.
int FixedVertex[6];                          // fixed vertexes or not
//+------------------------------------------------------------------+
//| The WaveRules function                                           |
//+------------------------------------------------------------------+
bool WaveRules(TWave *Wave)
  {
   Formula=Wave.Formula;
   bool Result=false;
   // fill the IndexVertex and ValueVertex arrays - indexes of the tops and values of the tops of the wave
   for(int i=0;i<=5;i++)
     {
      IndexVertex[i]=Wave.IndexVertex[i];
      ValueVertex[i]=Wave.ValueVertex[i];
      FixedVertex[i]=-1;
     }
   // fill the FixedVertex array, the values of which indicate whether or not the top of the wave is fixed
   int Pos1=StringFind(Formula,"<");
   string Str;
   if(Pos1>0)
     {
      Str=ShortToString(StringGetCharacter(Formula,Pos1-1));
      FixedVertex[StringToInteger(Str)]=1;
      FixedVertex[StringToInteger(Str)-1]=0;
      Pos1=StringToInteger(Str)+1;
     }
   else Pos1=0;
   int Pos2=StringFind(Formula,">");
   if(Pos2>0)
     {
      Str=ShortToString(StringGetCharacter(Formula,Pos2-1));
      FixedVertex[StringToInteger(Str)]=0;
      Pos2=StringToInteger(Str)-1;
     }
   else
     {
      Pos2=StringLen(Formula);
      Str=ShortToString(StringGetCharacter(Formula,Pos2-1));
      Pos2=StringToInteger(Str);
     }
   for(int i=Pos1;i<=Pos2;i++)
      FixedVertex[i]=1;
   double High[],Low[];
   ArrayResize(High,ArrayRange(rates,0));
   ArrayResize(Low,ArrayRange(rates,0));
     // find the maximums and minimums of the waves
     for(int i=1; i<=5; i++)
     {
      Maximum[i]=rates[IndexVertex[i]].high;
      Minimum[i]=rates[IndexVertex[i-1]].low;
      for(int j=IndexVertex[i-1];j<=IndexVertex[i];j++)
        {
         if(rates[j].high>Maximum[i])Maximum[i]=rates[j].high;
         if(rates[j].low<Minimum[i])Minimum[i]=rates[j].low;
        }
     }
   // find out the trend
   if((FixedVertex[0]==1 && ValueVertex[0]==rates[IndexVertex[0]].low) ||
      (FixedVertex[1]==1 && ValueVertex[1]==rates[IndexVertex[1]].high) ||
      (FixedVertex[2]==1 && ValueVertex[2]==rates[IndexVertex[2]].low) ||
      (FixedVertex[3]==1 && ValueVertex[3]==rates[IndexVertex[3]].high) ||
      (FixedVertex[4]==1 && ValueVertex[4]==rates[IndexVertex[4]].low) ||
      (FixedVertex[5]==1 && ValueVertex[5]==rates[IndexVertex[5]].high))
      Trend="Up";
   else Trend="Down";
   // check the wave by the rules
   if(Wave.Name=="Impulse")
     {
      if(VertexAAboveVertexB(1,0,true)>=0 && VertexAAboveVertexB(2,0,true)>=0 && 
         VertexAAboveVertexB(1,2,false)>=0 && VertexAAboveVertexB(3,2,true)>=0 &&
         VertexAAboveVertexB(3,1,false)>=0 && VertexAAboveVertexB(4,1,true)>=0 &&
         VertexAAboveVertexB(3,4,false)>=0 && VertexAAboveVertexB(5,4,true)>=0 &&
         (WaveAMoreWaveB(3,1)>=0 || WaveAMoreWaveB(3,5)>=0))
         Result=true;
     }
   else if(Wave.Name=="Leading Diagonal")
     {
      if(VertexAAboveVertexB(1,0,true)>=0 && VertexAAboveVertexB(2,0,true)>=0 && 
         VertexAAboveVertexB(1,2,false)>=0 && VertexAAboveVertexB(3,2,true)>=0 &&
         VertexAAboveVertexB(3,1,false)>=0 && VertexAAboveVertexB(4,2,true)>=0 &&
         VertexAAboveVertexB(1,4,false)>=0 &&
         VertexAAboveVertexB(3,4,false)>=0 && VertexAAboveVertexB(5,4,true)>=0&&
         (WaveAMoreWaveB(3,1)>=0 || WaveAMoreWaveB(3,5)>=0))
         Result=true;
     }
   else if(Wave.Name=="Diagonal")
     {
      if(VertexAAboveVertexB(1,0,true)>=0 && VertexAAboveVertexB(2,0,true)>=0 && 
         VertexAAboveVertexB(1,2,false)>=0 && VertexAAboveVertexB(3,2,true)>=0 &&
         VertexAAboveVertexB(3,1,false)>=0 && VertexAAboveVertexB(4,2,true)>=0 &&
         VertexAAboveVertexB(3,4,false)>=0 && VertexAAboveVertexB(5,4,true)>=0&&
         (WaveAMoreWaveB(3,1)>=0 || WaveAMoreWaveB(3,5)>=0))
         Result=true;
     }
   else if(Wave.Name=="ZigZag")
     {
      if(VertexAAboveVertexB(1,0,true)>=0 && VertexAAboveVertexB(2,0,true)>=0 && 
         VertexAAboveVertexB(1,2,false)>=0 && VertexAAboveVertexB(3,2,true)>=0 &&
         VertexAAboveVertexB(3,1,false)>=0)
         Result=true;
     }
   else if(Wave.Name=="Flat")
     {
      if(VertexAAboveVertexB(1,0,false)>=0 &&
         VertexAAboveVertexB(1,2,false)>=0 && VertexAAboveVertexB(3,2,true)>=0)
         Result=true;
     }
   else if(Wave.Name=="Double ZigZag")
     {
      if(VertexAAboveVertexB(1,0,true)>=0 && VertexAAboveVertexB(2,0,true)>=0 && 
         VertexAAboveVertexB(1,2,false)>=0 && VertexAAboveVertexB(3,2,true)>=0 &&
         VertexAAboveVertexB(3,1,false)>=0)
         Result=true;
     }
   else if(Wave.Name=="Double Three")
     {
      if(VertexAAboveVertexB(1,0,true)>=0 && 
         VertexAAboveVertexB(1,2,false)>=0 && VertexAAboveVertexB(3,2,false)>=0)
         Result=true;
     }
   else if(Wave.Name=="Triple ZigZag")
     {
      if(VertexAAboveVertexB(1,0,true)>=0 && VertexAAboveVertexB(2,0,true)>=0 && 
         VertexAAboveVertexB(1,2,false)>=0 && VertexAAboveVertexB(3,2,true)>=0 &&
         VertexAAboveVertexB(3,1,false)>=0 && VertexAAboveVertexB(5,3,false) &&
         VertexAAboveVertexB(3,4,false)>=0 && VertexAAboveVertexB(5,4,true)>=0)
         Result=true;
     }
   else if(Wave.Name=="Triple Three")
     {
      if(VertexAAboveVertexB(1,0,true)>=0 && 
         VertexAAboveVertexB(1,2,false)>=0 && VertexAAboveVertexB(3,2,false)>=0 &&
         VertexAAboveVertexB(3,4,false)>=0 && VertexAAboveVertexB(5,4,false)>=0)
         Result=true;
     }
   else if(Wave.Name=="Contracting Triangle")
     {
      if(VertexAAboveVertexB(1,0,false)>=0 && VertexAAboveVertexB(1,2,false)>=0 && VertexAAboveVertexB(3,2,false)>= 0&&
         VertexAAboveVertexB(3,4,false)>=0 && VertexAAboveVertexB(5,4,false)>=0 &&
         WaveAMoreWaveB(2,3)>=0 && WaveAMoreWaveB(3,4)>=0 && WaveAMoreWaveB(4,5)>=0)
         Result=true;
     }
   else if(Wave.Name=="Expanding Triangle")
     {
      if(VertexAAboveVertexB(1,0,false)>=0 && VertexAAboveVertexB(1,2,false)>=0 && VertexAAboveVertexB(3,2,false)>= 0&&
         VertexAAboveVertexB(3,4,false)>=0 && VertexAAboveVertexB(5,4,false)>=0 &&
         WaveAMoreWaveB(3,2)>=0 && WaveAMoreWaveB(3,2)>=0)
         Result=true;
     }
   return(Result);
  }
//+-------------------------------------------------------------------------------------+
//| The VertexAAboveVertexB function checks whether or not the top A                    |
//| is higher than top B,passed as the parameters of the given function                 |
//| this check can be performed only if the tops A and B - are fixed,                   |
//| or the top A - is not fixed and even, while the top B - is fixed,                   |
//| or the top A - is fixed, while the top B - is not fixed and odd,                    |
//| or the top A - is not fixed and even, and the top B - is not fixed and odd          |
//+-------------------------------------------------------------------------------------+
int VertexAAboveVertexB(int A,int B,bool InternalPoints)
  {
   double VA=0,VB=0,VC=0;
   int IA=0,IB=0;
   int Result=0;
   if(A>=B)
     {
      IA = A;
      IB = B;
     }
   else if(A<B)
     {
      IA = B;
      IB = A;
     }
   // if the internal points of the wave must be taken into consideration
   if(InternalPoints==true)
     {
      if((Trend=="Up") && ((IA%2==0) || ((IA-IB==1) && (IB%2==0))))
        {
         VA=Minimum[IA];
         IA=IA-IA%2;
        }
      else if((Trend=="Down") && ((IA%2==0) || ((IA-IB==1) && (IB%2==0))))
        {
         VA=Maximum[IA];
         IA=IA-IA%2;
        }
      else if((Trend=="Up") && ((IA%2==1) || ((IA-IB==1) && (IB%2==1))))
        {
         VA=Maximum[IA];
         IA=IA -(1-IA%2);
        }
      else if((Trend=="Down") && (IA%2==1) || ((IA-IB==1) && (IB%2==1)))
        {
         VA=Minimum[IA];
         IA=IA -(1-IA%2);
        }
      VB=ValueVertex[IB];
     }
   else
     {
      VA = ValueVertex[IA];
      VB = ValueVertex[IB];
     }
   if(A>B)
     {
      A = IA;
      B = IB;
     }
   else if(A<B)
     {
      A = IB;
      B = IA;
      VC = VA;
      VA = VB;
      VB = VC;
     }
   if(((FixedVertex[A]==1) && (FixedVertex[B]==1)) || 
      ((FixedVertex[A] == 0) &&(A % 2 == 0) && (FixedVertex[B] == 1)) ||
      ((FixedVertex[A] == 1) && (FixedVertex[B] == 0) && (B %2 == 1)) ||
      ((FixedVertex[A] == 0) & (A %2 == 0) && (FixedVertex[B] == 0) && (B % 2== 1)))
     {
      if(((Trend=="Up") && (VA>=VB)) || ((Trend=="Down") && (VA<=VB)))
         Result=1;
      else
         Result=-1;
     }
   return(Result);
  }
//+-----------------------------------------------------------------------+
//| The WaveAMoreWaveB function checks whether or not the wave A          |
//| is larger than the wave B, passed as the parameters of the function   |
//| this check can be performed only if wave A - is complete,             |
//| and wave B - is incomplete or incomplete and unbegun                  |
//+-----------------------------------------------------------------------+
int WaveAMoreWaveB(int A,int B)
  {
   int Result=0;
   double LengthWaveA=0,LengthWaveB=0;
   if(FixedVertex[A]==1 && FixedVertex[A-1]==1 && (FixedVertex[B]==1 || FixedVertex[B-1]==1))
     {
      LengthWaveA=MathAbs(ValueVertex[A]-ValueVertex[A-1]);
      if(FixedVertex[B]==1 && FixedVertex[B-1]==1) LengthWaveB=MathAbs(ValueVertex[B]-ValueVertex[B-1]);
      else if(FixedVertex[B]==1 && FixedVertex[B-1]==0)
        {
         if(Trend=="Up") LengthWaveB=MathAbs(ValueVertex[B]-Minimum[B]);
         else LengthWaveB=MathAbs(ValueVertex[B]-Maximum[B]);
        }
      else if(FixedVertex[B]==0 && FixedVertex[B-1]==1)
        {
         if(Trend=="Up")LengthWaveB=MathAbs(ValueVertex[B-1]-Minimum[B-1]);
         else LengthWaveB=MathAbs(ValueVertex[B-1]-Maximum[B-1]);
        }
      if(LengthWaveA>LengthWaveB) Result=1;
      else Result=-1;
     }
   return(Result);
  }
//+------------------------------------------------------------------+
