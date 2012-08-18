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

input int MovingPeriodSlow = 16;  // MACD fast period 
input int MovingPeriodFast = 23;  // MACD slow period
input int MovingPeriodSlowest = 36;  // MACD slow period

int ExtHandleSlow,ExtHandleFast, ExtHandleSlowest;

//--- input parameters
input double TakeProfit    =   0.008; // Take Profit
input double StopLoss      =   0.0035;// Stop Loss

CTrade trade;  
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

 //---- getting handle of the iMACD indicator
 ExtHandleSlow =iMA(_Symbol,_Period,MovingPeriodSlow,0,MODE_SMA,PRICE_CLOSE);
   if(ExtHandleSlow==INVALID_HANDLE) Print(" Failed to get handle of the iMACD indicator");
   ExtHandleFast =iMA(_Symbol,_Period,MovingPeriodFast,0,MODE_SMA,PRICE_CLOSE);
 if(ExtHandleFast==INVALID_HANDLE) Print(" Failed to get handle of the iMACD indicator");
    ExtHandleSlowest =iMA(_Symbol,_Period,MovingPeriodSlowest,0,MODE_SMA,PRICE_CLOSE);
 if(ExtHandleSlowest==INVALID_HANDLE) Print(" Failed to get handle of the iMACD indicator");
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

   double MAF[], MAS[], MAST[];


   if(CopyBuffer(ExtHandleFast,0,0,2,MAF)<=0) return; // vector de 2 periodos
     if(CopyBuffer(ExtHandleSlow,0,0,2,MAS)<=0) return; // vector de 2 periodos  
     if(CopyBuffer(ExtHandleSlowest,0,0,2,MAST)<=0) return; // vector de 2 periodos  
     
   double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // ask price
   double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID); // bid price
   
if (ORDER_TYPE_BUY == signal(MAF,MAS,MAST,ORDER_TYPE_BUY))
  if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>3000)      // if we have enough money
           {
           printf("ORDER_TYPE_BUY " );
            trade.PositionOpen(_Symbol,                                          // symbol
                               ORDER_TYPE_BUY,                                   // buy order
                               Money_M(),                                        // lots to trade
                               Ask,                                              // last ask price
                               Ask - StopLoss,                                   // Stop Loss
                               Ask + TakeProfit,                                 // Take Profit 
                               " ");                                             // no comments
           }     
  
  
if (ORDER_TYPE_SELL == signal(MAF,MAS,MAST,ORDER_TYPE_SELL))   
   if (!PositionSelect(_Symbol)) 
   {
          if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>3000)      // if we have enough money
           {
           printf("ORDER_TYPE_SELL   " );
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


/*

*/

long signal(double &F[], double &S[],double &SS[], int dir)
  {
     
   if ( dir == ORDER_TYPE_BUY &&  F[1] < S[1] && F[0] > S[0] && S[0] > SS[0])
    {
  
    Print("la señal cruza [slow : fast]  [ " + S[0]+ "  : " +  F[0] +" ] [ " + S[1]+ "  : " +  F[1] +" ]" );
    return ( ORDER_TYPE_BUY);
    }
    
   else if ( dir == ORDER_TYPE_SELL && F[1] > S[1] && F[0] < S[0] && S[0] < SS[0])
    {
      Print("la señal cruza  [slow : fast]  [ " + S[0]+ "  : " +  F[0] +" ] [ " + S[1]+ "  : " +  F[1] +" ]" );
      return (ORDER_TYPE_SELL);
    }
    
   return (WRONG_VALUE);
    
  }
