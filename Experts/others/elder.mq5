//+------------------------------------------------------------------+
//|                                                        elder.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"


#include <Trade\Trade.mqh>    
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int ma_period=13;          // Period of MA
input int fast_ema_period = 12;  // MACD fast period 
input int slow_ema_period = 26;  // MACD slow period
input int signal_period=9;       // MACD signal period
input int atr_Period = 14;
input int DD = 15000;


int           MA_Handle,MACD_Handle, ATRHandle;

//--- input parameters
input double TakeProfit    =  4; // Take Profit
input double StopLoss      =  2;// Stop Loss

CTrade trade;  
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

      
//---- getting handle of the iMA indicator
   MA_Handle=iMA(NULL,0,ma_period,0,MODE_EMA,PRICE_CLOSE);
   if(MA_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMA indicator");

//---- getting handle of the iMACD indicator
   MACD_Handle=iMACD(NULL,0,fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   if(MACD_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMACD indicator");
 
    ATRHandle = iATR(NULL,NULL,atr_Period);
 if(ATRHandle==INVALID_HANDLE) Print(" Failed to get handle of the iMACD indicator");
//----   
   return(0);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

 int Mybars=Bars(_Symbol,_Period);
   if(Mybars<100) // if bars<100
     {
      Alert("We have less than 100 bars on the chart, the Expert Advisor will exit!!!");
      return;
     }


//---- declarations of local variables 
   double MA[],MACDM[],MACDS[],  ATR[];
   double dma,dmacd0,dmacd1;



//--- copy newly appeared data in the arrays
   if(CopyBuffer(MA_Handle,0,0,3,MA)<=0) return;
   if(CopyBuffer(MACD_Handle,0,0,3,MACDM)<=0) return;
   if(CopyBuffer(MACD_Handle,1,0,3,MACDS)<=0) return;
    if(CopyBuffer(ATRHandle,0,0,3,ATR)<=0) return;



 bool buy, sell, close;


    
      dma=MA[0]-MA[1];
      dmacd0=MACDM[0]-MACDS[1];
      dmacd1=MACDM[1]-MACDS[1];

   
      buy   =(dma>0 && dmacd0 > dmacd1 && dmacd0>0);
      sell  = (dma<0 && dmacd0 < dmacd1 && dmacd0<0) ;
      close = (MA[0]<=MA[1] && dmacd0>0 || dma<=0 && dmacd0>dmacd1 || dma>=0 && dmacd0<0 || dma>=0 && dmacd0<dmacd1);
      
 
     
   double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // ask price
   double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); // bid price
   
   if (!PositionSelect(_Symbol)) 
   {
   if(buy)                                          // buy condition ok
         if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>5000)      // if we have enough money
           {
           printf("VERDE dma " + dma + " dmacd0 " + dmacd0 + " dmacd1 " + dmacd1  + " sl " + StopLoss*ATR[0]+ " tp " + TakeProfit*ATR[0]);
            trade.PositionOpen(_Symbol,                                          // symbol
                               ORDER_TYPE_BUY,                                   // buy order
                               Money_M(),                                        // lots to trade
                               Ask,                                              // last ask price
                               Ask - StopLoss*ATR[0],                                   // Stop Loss
                               Ask + TakeProfit*ATR[0],                                 // Take Profit 
                               " ");                                             // no comments
         
           }

     if (sell)
         if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>5000)      // if we have enough money
           {
           printf("ROJO  dma " + dma + "  dmacd0  " + dmacd0 + "  dmacd1  " + dmacd1 + " sl " + StopLoss*ATR[0]+ " tp " + TakeProfit*ATR[0]);
            trade.PositionOpen(_Symbol,                                          // symbol
                               ORDER_TYPE_SELL,                                  // sell order
                               Money_M(),                                        // lots to trade
                               Bid,                                              // last bid price
                               Bid + StopLoss*ATR[0],                                 // Stop Loss
                               Bid - StopLoss*ATR[0],                           // Take Profit 
                               " ");                                             // no comments
           }
         }
           
else
{
 if (close)
      {
//printf("azul  dma " + " dma  " +dmacd0  + "  dmacd0  " + dmacd1 + "  dmacd1 " );
      //   printf("MA[bar] " +  MA[0] + " MA[bar+1]  "  + MA[1] );
      
      }
      
}
        }   
        



double Money_M()
{
//N = [(1 + 8 * Equity / Delta) 0,5 +1] / 2
//Delta neutro = DD / 2
//N =  [ 1+ (1 + 8 * 50.000 / 7.000) ^ 0,5 ] / 2 = 4 contratos.

long Equity =AccountInfoDouble(ACCOUNT_FREEMARGIN);
long DeltaNeutro = DD/2;
long value = 1 + 8*(Equity/DeltaNeutro );
long valuesqrt = sqrt(value);
long N = 1 + ( valuesqrt / 2);

 Print(__FUNCTION__+" El Equity "+ Equity+"  DeltaNeutro: " +DeltaNeutro+ " N: " + N + " value" + value  + " valuesqrt "  + valuesqrt );
 
 return N;
}
  
  