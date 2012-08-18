//+------------------------------------------------------------------+
//|                                                       Aelder.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"


#include <Trade\Trade.mqh>  

int handle1;
double MA[],MACDM[],MACDS[];
input int ma_period=13;          // Period of MA
input int fast_ema_period = 12;  // MACD fast period 
input int slow_ema_period = 26;  // MACD slow period
input int signal_period=9;       // MACD signal period
//--- input parameters
input double TakeProfit    =   0.007; // Take Profit
input double StopLoss      =   0.0035;// Stop Loss


CTrade trade;  
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {


      handle1=iCustom(_Symbol,_Period,"ElderImpulseSystem",ma_period,fast_ema_period,slow_ema_period, signal_period);
      if(handle1==INVALID_HANDLE)
     {
      Print("Error in indicator!");
      return(1);
     }
      
//---
   return(0);
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(handle1);
      
  }
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  double dma,dmacd0,dmacd1;
  
 bool buy, sell, close;
 
   MqlTick tick; //variable for tick info
   if(!SymbolInfoTick(Symbol(),tick))
     {
      Print("Failed to get Symbol info!");
      return;
     }
     
         ArraySetAsSeries(MA,true);
         ArraySetAsSeries(MACDM,true);
         ArraySetAsSeries(MACDS,true);
   
      //--- copy the new values of our indicators to buffers (arrays) using the handle
   if(CopyBuffer(handle1,5,0,3,MA)<0 || CopyBuffer(handle1,6,0,3,MACDM)<0   || CopyBuffer(handle1,7,0,3,MACDS)<0)
     {
      Alert("Error copying  indicator Buffers - error:",GetLastError(),"!!",handle1);
      return;
     }
     
     
      dma=MA[0]-MA[1];
      dmacd0=MACDM[0]-MACDS[0];
      dmacd1=MACDM[1]-MACDS[1];

   
      buy   =(dma>0 && dmacd0 > dmacd1 && dmacd0>0);
      sell  = (dma<0 && dmacd0 < dmacd1 && dmacd0<0) ;
      close = (MA[0]<=MA[1] && dmacd0>0 || dma<=0 && dmacd0>dmacd1 || dma>=0 && dmacd0<0 || dma>=0 && dmacd0<dmacd1);
   
   
   if (buy && sell) return ;
 
     
   double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // ask price
   double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); // bid price
   
   if (!PositionSelect(_Symbol)) 
   {
   if(buy)                                          // buy condition ok
         if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>5000)      // if we have enough money
           {
           printf("VERDE dma " + dma + " dmacd0 " + dmacd0 + " dmacd1 " + dmacd1  );
            trade.PositionOpen(_Symbol,                                          // symbol
                               ORDER_TYPE_BUY,                                   // buy order
                               Money_M(),                                        // lots to trade
                               Ask,                                              // last ask price
                               Ask - StopLoss,                                   // Stop Loss
                               Ask + TakeProfit,                                 // Take Profit 
                               " ");                                             // no comments
           }
           
     if (sell)
         if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>5000)      // if we have enough money
           {
           printf("ROJO  dma " + " dma  " +dmacd0  + "  dmacd0  " + dmacd1 + "  dmacd1 " );
            trade.PositionOpen(_Symbol,                                          // symbol
                               ORDER_TYPE_SELL,                                  // sell order
                               Money_M(),                                        // lots to trade
                               Bid,                                              // last bid price
                               Bid + StopLoss,                                   // Stop Loss
                               Bid - TakeProfit,                                 // Take Profit 
                               " ");                                             // no comments
           }
         }
           
else
{
 if (close)
      {
         printf("azul  dma " + " dma  " +dmacd0  + "  dmacd0  " + dmacd1 + "  dmacd1 " );
         printf("MA[] " +  MA[0] + " MA[1]  "  + MA[1] );
      
      }
      
}


  }
double Money_M()
  {
   double Lots=AccountInfoDouble(ACCOUNT_FREEMARGIN)/100000*50;
   Lots=MathMin(15,MathMax(0.1,Lots));
   if(Lots<0.1)
      Lots=NormalizeDouble(Lots,2);
   else
     {
      if(Lots<1) Lots=NormalizeDouble(Lots,1);
      else       Lots=NormalizeDouble(Lots,0);
     }
   return(Lots);
  }
