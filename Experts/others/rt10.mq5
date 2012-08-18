//+------------------------------------------------------------------+
//|                                                         rt10.mq5 |
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

input int fast_ema_period = 12;  // MACD fast period 
input int slow_ema_period = 26;  // MACD slow period
input int signal_period=9;       // MACD signal period


int MA_Handle,MACD_Handle;

//--- input parameters
input double TakeProfit    =   0.007; // Take Profit
input double StopLoss      =   0.0035;// Stop Loss

CTrade trade;  
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

      


//---- getting handle of the iMACD indicator
   MACD_Handle=iMACD(NULL,0,fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   if(MACD_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMACD indicator");


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

   double Signal[];


   if(CopyBuffer(MACD_Handle,1,0,90,Signal)<=0) return; // vector de 90 periodos
      
   double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // ask price
   double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); // bid price
   
if (ORDER_TYPE_BUY == signal(Signal,ORDER_TYPE_BUY))
  if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>5000)      // if we have enough money
           {
           printf("VERDE " );
            trade.PositionOpen(_Symbol,                                          // symbol
                               ORDER_TYPE_BUY,                                   // buy order
                               Money_M(),                                        // lots to trade
                               Ask,                                              // last ask price
                               Ask - StopLoss,                                   // Stop Loss
                               Ask + TakeProfit,                                 // Take Profit 
                               " ");                                             // no comments
           }     
  
  
if (ORDER_TYPE_SELL == signal(Signal,ORDER_TYPE_SELL))   
   if (!PositionSelect(_Symbol)) 
   {
          if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>5000)      // if we have enough money
           {
           printf("ROJO   " );
            trade.PositionOpen(_Symbol,                                          // symbol
                               ORDER_TYPE_SELL,                                  // sell order
                               Money_M(),                                        // lots to trade
                               Bid,                                              // last bid price
                               Bid + StopLoss,                                   // Stop Loss
                               Bid - TakeProfit,                                 // Take Profit 
                               " ");                                             // no comments
           }
         }
           
//else
//{
// if (close)
    //  {
//printf("azul  dma " + " dma  " +dmacd0  + "  dmacd0  " + dmacd1 + "  dmacd1 " );
      //   printf("MA[bar] " +  MA[0] + " MA[bar+1]  "  + MA[1] );
      
  //    }
      
//}
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


//      if(!CopyBufferAsSeries(ExtATRHandleWeek,0,0,ATRPeriod,true,ATR)) return(-1);

long signal(double &S[], int dir)
  {
   
 
    int down = ArrayMinimum(S, 0, WHOLE_ARRAY)  ;
    int up =   ArrayMaximum(S, 0, WHOLE_ARRAY) ;
   
   
  
   if ( dir == ORDER_TYPE_BUY && S[0] <= S[down]  )
    {
  
    Print("la señal esta en maximos de 90 periodos [" + S[0]+ "  [ down :" +  S[down] +" ]" );
    return ( ORDER_TYPE_BUY);
    }
    
   else if (  dir == ORDER_TYPE_SELL && S[0] >= S[up])
    {
      Print("la señal esta en minimos de 90 periodos [  " +S[0]+ " ] para la orden de venta  [ up :" +  S[up] +" ]" );
      return (ORDER_TYPE_SELL);
    }
    
return (WRONG_VALUE);
    
  }
