//+------------------------------------------------------------------+
//| Crossing of two лю: optimizing the periods                       |
//+------------------------------------------------------------------+
#include            "MATrainLib.mqh"
#include            "MustHaveLib.mqh"
//---
input double        trainDD=0.5;   // Maximum possible balance drawdown in training
input double        maxDD=0.2;     // Balance drawdown, after which the network is re-trained
//---
int                 MAlong,MAshort;              // лю-handles
double              LongBuffer[],ShortBuffer[];  // Indicator buffers
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   tf=Period();
//--- for bar-to-bar test...
   prevBT[0]=D'2001.01.01';
//... long ago
   TimeToStruct(prevBT[0],prevT);
//--- historical depth (should be set since the optimisation is based on historical data)
   depth=10000;
//--- copies at a time (should be set since the optimisation is based on historical data)
   count=2;
   ArrayResize(LongBuffer,count);
   ArrayResize(ShortBuffer,count);
   ArrayInitialize(LongBuffer,0);
   ArrayInitialize(ShortBuffer,0);
//--- calling the neural network genetic optimisation function
   GA();
//--- getting the optimised neural network parameters and other variables
   GetTrainResults();
//--- getting the account drawdown
   InitRelDD();
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isNewBars()==true)
     {
      bool trig=false;
      CopyBuffer(MAshort,0,0,count,ShortBuffer);
      CopyBuffer(MAlong,0,0,count,LongBuffer);
      if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        {
         if(PositionsTotal()>0)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               ClosePosition();
               trig=true;
              }
           }
        }
      if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
        {
         if(PositionsTotal()>0)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               ClosePosition();
               trig=true;
              }
           }
        }
      if(trig==true)
        {
        //--- if the account drawdown has exceeded the allowable value:
         if(GetRelDD()>maxDD) 
           {
            //--- calling the neural network genetic optimisation function
            GA();
            //--- getting the optimised neural network parameters and other variables
            GetTrainResults();
            //--- readings of the drawdown will from now on be based on the current balance instead of the maximum balance
            maxBalance=AccountInfoDouble(ACCOUNT_BALANCE);
           }
        }
      CopyBuffer(MAshort,0,0,count,ShortBuffer);
      CopyBuffer(MAlong,0,0,count,LongBuffer);
      if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        {
         request.type=ORDER_TYPE_SELL;
         OpenPosition();
        }
      if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
        {
         request.type=ORDER_TYPE_BUY;
         OpenPosition();
        }
     };
  }
//+------------------------------------------------------------------+
