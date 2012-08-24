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
input int ma_periodFast=12;          // Period of MA
input int ma_periodSlow = 25;  // MACD fast period 
input int ma_periodSlowest = 850;  // MACD slow period

input int atr_Period = 14;
input int DD = 5000;
input int positions = 2 ;


int           MA_HandleFast,MA_HandleSlow,MA_HandleSlowEst, ATR_Handle, BB_handle;



//--- input parameters
input double Volatility       =  3; // SL
input double VolatilityP      =  5;// SLP

CTrade trade;  
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

      
//---- getting handle of the iMA indicator
   MA_HandleFast=iMA(NULL,0,ma_periodFast,0,MODE_SMMA,PRICE_CLOSE);
   if(MA_HandleFast==INVALID_HANDLE) Print(" Failed to get handle of the iMA indicator");

//---- getting handle of the iMACD indicator
   MA_HandleSlow=iMA(NULL,0,ma_periodSlow,0,MODE_SMMA,PRICE_CLOSE);
   if(MA_HandleSlow==INVALID_HANDLE) Print(" Failed to get handle of the iMACD indicator");
   
   //---- getting handle of the iMACD indicator
   MA_HandleSlowEst=iMA(NULL,0,ma_periodSlowest,0,MODE_SMA,PRICE_CLOSE);
   if(MA_HandleSlowEst==INVALID_HANDLE) Print(" Failed to get handle of the iMACD indicator");
 
    ATR_Handle = iATR(NULL,NULL,atr_Period);
 if(ATR_Handle==INVALID_HANDLE) Print(" Failed to get handle of the iMACD indicator");
 
    BB_handle=iBands(NULL,NULL,90,0,2.33,PRICE_CLOSE);
 if(BB_handle==INVALID_HANDLE) Print(" Failed to get handle of the iMACD indicator");
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
      double MAFast[],MASlow[],MASlowest[],  ATR[], Upper[], Lower[];
     
   
   
   //--- copy newly appeared data in the arrays
      if(CopyBuffer(MA_HandleFast,0,0,3,MAFast)<=0) return;
      if(CopyBuffer(MA_HandleSlow,0,0,3,MASlow)<=0) return;
      if(CopyBuffer(MA_HandleSlowEst,0,0,3,MASlowest)<=0) return;
      if(CopyBuffer(ATR_Handle,0,0,3,ATR)<=0) return;
      if(CopyBuffer(BB_handle,1,0,3,Upper)<=0) return;
      if(CopyBuffer(BB_handle,2,0,3,Lower)<=0) return;
   
   
    bool buy = false, sell= false, close= false;
   
      double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5); // ask price
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5); // bid price
   
    if(!PositionSelect(_Symbol)) 
   	 {
         buy   =(MAFast[0] <MASlow[0] && MAFast[1] > MASlow[1]);
         sell  = (MAFast[0] > MASlow[0] && MAFast[1] < MASlow[1]) ;
         close = false;
       }
       else{        
               HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));   
   				if(  HistoryOrdersTotal()  < positions  )
   				{
   					 printf("HistoryOrdersTotal  : " + HistoryOrdersTotal() );
   				 }
   				 else{   
   				         double cop =  LastDealOpenPrice();
   				          if(cop + ATR[0] < Ask && PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY || ( cop - ATR[0] >  Bid && PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)) 
   				                  {
   				          		         
                     			 if (PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY)
                     			         {
                     			               close =  ( Ask < Lower[0]);
                     			                  if (close)
                     			                        printf(" Ask  : " + Ask + " Lower[0] "  + Lower[0]);
         								         }
                               else if (PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)
         							          {
         							            close =( Bid > Upper[0] );
         							                  if (close)
         							                        printf(" Bid  : " + Bid + " Upper[0] "  + Upper[0]);
         								      }
   								      }
   			          }  
       }
       
      
      if (!PositionSelect(_Symbol)) 
      {
      if(buy)                                          // buy condition ok
            if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>3000)      // if we have enough money
              {
              printf("VERDE pips : " + ATR[0]*Volatility );
               trade.PositionOpen(_Symbol,                                          // symbol
                                  ORDER_TYPE_BUY,                                   // buy order
                                  Money_M(),                                        // lots to trade
                                  Ask,                                              // last ask price
                                  Ask - ATR[0]*Volatility,                                   // Stop Loss
                                  Ask + ATR[0]*2*Volatility,                                 // Take Profit 
                                  " ");                                             // no comments
            
              }
   
        if (sell)
            if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>3000)      // if we have enough money
              {
               printf("ROJO pips : " + ATR[0]*Volatility );
               trade.PositionOpen(_Symbol,                                          // symbol
                                  ORDER_TYPE_SELL,                                  // sell order
                                  Money_M(),                                        // lots to trade
                                  Bid,                                              // last bid price
                                  Bid + ATR[0]*Volatility,                      // Stop Loss
                                  Bid - ATR[0]*2*Volatility,                       // Take Profit 
                                  " ");                                             // no comments
              }
            }
              
         else
         {
            if (close)         // xq mierda aparece en true ¿?¿?¿?¿?¿?¿?
                     {
                        printf("Cerrado por señal de close  : " + close);
                        trade.PositionClose(_Symbol,1);
                     }
         }
   }   
        


double Money_M()
{

long Equity =AccountInfoDouble(ACCOUNT_FREEMARGIN);
long DeltaNeutro = DD/2;
long value = 1 + 8*(Equity/DeltaNeutro );
long valuesqrt = sqrt(value);
long N = 1 + ( valuesqrt / 2);

 return N;
}
  

//------------------------------------------------------------------	
// Last deal open price to calculate the distance necessary to process a new deal
//------------------------------------------------------------------ 
double LastDealOpenPrice()
  {
   uint pos_total=0;
   uint total=0;
   long pos_id=0;
   ulong HTicket=0;
   double price=0;
   pos_total=PositionsTotal();
  
   if(pos_total>0)
     {

      if(PositionSelect(Symbol())) // continue if open position is for chart symbol and order type
        {
         pos_id=(ENUM_POSITION_PROPERTY_INTEGER)PositionGetInteger(POSITION_IDENTIFIER);
         HistorySelectByPosition(pos_id);
         total=HistoryDealsTotal();
         HTicket=HistoryDealGetTicket(total-1); // get ticket number for last deal in position
        
         if(HTicket>0)
            price=HistoryDealGetDouble(HTicket,DEAL_PRICE);

         return(price);
        }

     }
   return(0);
  }
  