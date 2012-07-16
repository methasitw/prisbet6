//+------------------------------------------------------------------+
//| Input:                                                           |
//| actual prices changes of five previous bars                      |
//| (brought to the range 0-1)                                       |
//+------------------------------------------------------------------+
#include            "ANNTrainLib.mqh"
#include            "MustHaveLib.mqh"

input double        trainDD=0.5;  // Maximum possible balance drawdown in training
input double        maxDD=0.2;    // Balance drawdown, after which the network is re-trained
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   tf=Period();
//--- for bar-to-bar test...
   prevBT[0]=D'2001.01.01';
//---... long ago
   TimeToStruct(prevBT[0],prevT);
//--- setting the number of neural network layers
   layers=2;
//--- setting the number of neurons at each layer
   neurons=5;
//--- historical depth (should be set since the optimisation is based on historical data)
   depth=1000;
//--- copies at a time (should be set since the optimisation is based on historical data)
   count=6;
//--- necessary neural networks and arrays must be intialized including the arrays
//--- required for its training, in case its is conducted using historical data
   InitArrays();
//--- calling the neural network genetic optimisation function
   GA();
//--- getting the optimised neural network parameters and other variables
   GetTrainANNResults();
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
//| InitFirstLayer                                                   |
//| Must be called before each neural network call                   |
//+------------------------------------------------------------------+
void InitFirstLayer()
  {
   CopyTime(s,tf,from,count,d);
   TimeToStruct(d[1],dt);
   CopyOpen(s,tf,from,count,o);
   CopyClose(s,tf,from,count,c);
//--- 1 st neurone, 5 th bar price change
   ne[0]=(c[0]-o[0])/c[0]+0.5;
//--- 2 nd  neurone, 4 th bar price change
   ne[1]=(c[1]-o[1])/c[1]+0.5;
//--- 3 rd neurone, 3 rd price change   
   ne[2]=(c[2]-o[2])/c[2]+0.5;
//--- 4 th neurone, 2 nd bar price change
   ne[3]=(c[3]-o[3])/c[3]+0.5;
//--- 5 th neurone, 1 st bar price change
   ne[4]=(c[4]-o[4])/c[4]+0.5;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(isNewBars()==true)
     {
      if(PositionsTotal()>0)
        {
         ClosePosition();
         //--- if the account drawdown has exceeded the allowable value:
         if(GetRelDD()>maxDD)
           {
            //--- calling the neural network genetic optimisation function
            GA();
            //--- getting the optimised neural network parameters and other variables
            GetTrainANNResults();
            //--- readings of the drawdown will from now on be based on the current balance instead of the maximum balance
            maxBalance=AccountInfoDouble(ACCOUNT_BALANCE);
           }
        }
      //--- for a neural network using historical data - where the data is copied from
      from=0;
      //--- initializing the input layer
      InitFirstLayer();
      //--- getting the result at the neural network output
      ANNRes=GetANNResult();
      if(ANNRes<0.75) request.type=ORDER_TYPE_SELL;
      else request.type=ORDER_TYPE_BUY;
      OpenPosition();
     };
  }
//+------------------------------------------------------------------+
