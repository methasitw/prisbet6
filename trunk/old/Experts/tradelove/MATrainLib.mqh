//+------------------------------------------------------------------+
//| Optimized by the capital percent value                           |
//+------------------------------------------------------------------+
#include        "UGAlib.mqh"
#include        "MustHaveLib.mqh"
//---
double          cap=10000;           // Initial deposit
double          optF=0.3;            // Optimal F
long            leverage;            // Account leverage
double          contractSize;        // Contract size
double          dig;                 // The number of digits in a quote after a comma (to allow correct forecast of the balance curve for currency pairs with different amount of digits)
//---
int             OptParamCount=2;     // The number of optimized parameters
int             MaxMAPeriod=250;     // Maximum period of the moving averages
//---
int             depth=250;           // Historical depth (by default - 250, in case some other value is needed, it should be changed  in the Expert Advisor/script Initializer)
int             from=0;              // Where we should copy from (must be initialized before each InitFirstLayer() function call)
int             count=2;             // Copies at a time (by default - 2, in case some other value is needed, it should be changed  in the Expert Advisor/script Initializer)
//---
double          ERROR=0.0;           // Average error per gene (that is for the genetic optimiser, I don't know the value)
//+------------------------------------------------------------------+
//| InitArrays()                                                     |
//| Must be called in the Expert Advisor/script Initializer          |
//+------------------------------------------------------------------+
void InitArrays()
  {
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(d,count);
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(o,count);
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(h,count);
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(l,count);
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(c,count);
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(v,count);
  }
//+------------------------------------------------------------------+
//| Fitness function for neural network genetic optimiser:           |
//| selecting a pair, optF, synapse weights;                         |
//| anything can be optimised but it is necessary                    |
//| to carefully monitor the number of genes                         |
//+------------------------------------------------------------------+
void FitnessFunction(int chromos)
  {
   int    b;
//--- is there an open position?   
   bool   trig=false;
//--- direction of an open position
   string dir="";
//--- opening price
   double OpenPrice=0;
//--- intermediary between a gene colony and optimised parameters
   int    z;
//--- current balance
   double t=cap;
//--- maximum balance
   double maxt=t;
//--- absolute drawdown
   double aDD=0;
//--- relative drawdown
   double rDD=0.000001;
//--- fitness function proper
   double ff=0;
//--- GA is selecting a pair
   z=(int)MathRound(Colony[GeneCount-1][chromos]*12);
   switch(z)
     {
      case  0: {s="AUDUSD"; break;};
      case  1: {s="AUDUSD"; break;};
      case  2: {s="EURAUD"; break;};
      case  3: {s="EURCHF"; break;};
      case  4: {s="EURGBP"; break;};
      case  5: {s="EURJPY"; break;};
      case  6: {s="EURUSD"; break;};
      case  7: {s="GBPCHF"; break;};
      case  8: {s="GBPJPY"; break;};
      case  9: {s="GBPUSD"; break;};
      case 10: {s="USDCAD"; break;};
      case 11: {s="USDCHF"; break;};
      case 12: {s="USDJPY"; break;};
      default: {s="EURUSD"; break;};
     }
   MAshort=iMA(s,tf,(int)MathRound(Colony[1][chromos]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
   MAlong =iMA(s,tf,(int)MathRound(Colony[2][chromos]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
   dig=MathPow(10.0,(double)SymbolInfoInteger(s,SYMBOL_DIGITS));
//--- GA is selecting the optimal F
   optF=Colony[GeneCount][chromos];
   leverage=AccountInfoInteger(ACCOUNT_LEVERAGE);
   contractSize=SymbolInfoDouble(s,SYMBOL_TRADE_CONTRACT_SIZE);
   b=MathMin(Bars(s,tf)-1-count-MaxMAPeriod,depth);
//--- for a neural network using historical data - where the data is copied from
   for(from=b;from>=1;from--)
     {
      CopyBuffer(MAshort,0,from,count,ShortBuffer);
      CopyBuffer(MAlong,0,from,count,LongBuffer);
      if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        {
         if(trig==false)
           {
            CopyOpen(s,tf,from,count,o);
            OpenPrice=o[1];
            dir="SELL";
            trig=true;
           }
         else
           {
            if(dir=="BUY")
              {
               CopyOpen(s,tf,from,count,o);
               if(t>0) t=t+t*optF*leverage*(o[1]-OpenPrice)*dig/contractSize; else t=0;
               if(t>maxt) {maxt=t; aDD=0;} else if((maxt-t)>aDD) aDD=maxt-t;
               if((maxt>0) && (aDD/maxt>rDD)) rDD=aDD/maxt;
               OpenPrice=o[1];
               dir="SELL";
               trig=true;
              }
           }
        }
      if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
        {
         if(trig==false)
           {
            CopyOpen(s,tf,from,count,o);
            OpenPrice=o[1];
            dir="BUY";
            trig=true;
           }
         else
           {
            if(dir=="SELL")
              {
               CopyOpen(s,tf,from,count,o);
               if(t>0) t=t+t*optF*leverage*(OpenPrice-o[1])*dig/contractSize; else t=0;
               if(t>maxt) {maxt=t; aDD=0;} else if((maxt-t)>aDD) aDD=maxt-t;
               if((maxt>0) && (aDD/maxt>rDD)) rDD=aDD/maxt;
               OpenPrice=o[1];
               dir="BUY";
               trig=true;
              }
           }
        }
     }
   if(rDD<=trainDD) ff=t; else ff=0.0;
   AmountStartsFF++;
   Colony[0][chromos]=ff;
  }
//+------------------------------------------------------------------+
//| ServiceFunction                                                  |
//+------------------------------------------------------------------+
void ServiceFunction()
  {
  }
//+------------------------------------------------------------------+
//| Preparing and calling the genetic optimiser                      |
//+------------------------------------------------------------------+
void GA()
  {
//--- number of genes (equal to the number of optimised variables), 
//--- all of them should be specified in FitnessFunction())
   GeneCount=OptParamCount+2;
//--- number of chromosomes in a colony
   ChromosomeCount=GeneCount*11;
//--- minimum search range
   RangeMinimum=0.0;
//--- maximum search range
   RangeMaximum=1.0;
//--- search pitch
   Precision=0.0001;
//--- 1 is a minimum, anything else is a maximum
   OptimizeMethod=2;
   ArrayResize(Chromosome,GeneCount+1);
   ArrayInitialize(Chromosome,0);
//--- number of epochs without any improvement
   Epoch=100;
//--- ratio of Replication, natural mutation, artificial mutation, gene borrowing, 
//--- crossingover, interval boundary displacement ratio, every gene mutation probabilty, %
   UGA(100.0,1.0,1.0,1.0,1.0,0.5,1.0);
  }
//+---------------------------------------------------------------------+
//| getting the optimised neural network parameters and other variables |
//| should always be equal to the number of genes                       |
//+---------------------------------------------------------------------+
void GetTrainResults() //
  {
//--- intermediary between a gene colony and optimised parameters
   int z;
   MAshort=iMA(s,tf,(int)MathRound(Chromosome[1]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
   MAlong =iMA(s,tf,(int)MathRound(Chromosome[2]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
   CopyBuffer(MAshort,0,from,count,ShortBuffer);
   CopyBuffer(MAlong,0,from,count,LongBuffer);
//--- save the best pair
   z=(int)MathRound(Chromosome[GeneCount-1]*12);
   switch(z)
     {
      case  0: {s="AUDUSD"; break;};
      case  1: {s="AUDUSD"; break;};
      case  2: {s="EURAUD"; break;};
      case  3: {s="EURCHF"; break;};
      case  4: {s="EURGBP"; break;};
      case  5: {s="EURJPY"; break;};
      case  6: {s="EURUSD"; break;};
      case  7: {s="GBPCHF"; break;};
      case  8: {s="GBPJPY"; break;};
      case  9: {s="GBPUSD"; break;};
      case 10: {s="USDCAD"; break;};
      case 11: {s="USDCHF"; break;};
      case 12: {s="USDJPY"; break;};
      default: {s="EURUSD"; break;};
     }
//--- saving the best optimal F
   optF=Chromosome[GeneCount];
  }
//+------------------------------------------------------------------+
