//+------------------------------------------------------------------+
//|LA distancia del ATR, condiciona:
//						Los Stops Loose 
//						La distancia para piramidar
//						
//+------------------------------------------------------------------+
#property copyright "hippie Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"


#include <Trade\Trade.mqh>    
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int ma_period_fast=12;          // Period of MA
input int ma_period_slow = 25;  // MACD fast period 
input int ma_period_slowest = 850;  // MACD slow period

input int atr_period = 14;
input int DD = 5000;
input int positions = 2 ;

input int BB_Period = 90;
input int BB_Dispersion = 2.33;


//--- input parameters
input double Volatility       =  3; // SL
input double VolatilityP      =  5;// SLP

int  MA_handle_fast,MA_handle_slow,MA_handle_slowest, ATR_handle, BB_handle;
CTrade trade;  
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      
		MA_handle_fast=iMA(NULL,0,ma_period_fast,0,MODE_SMMA,PRICE_CLOSE);
		if(MA_handle_fast==INVALID_HANDLE) Print(" Failed to get handle of the iMA Fast indicator");
		
		MA_handle_slow=iMA(NULL,0,ma_period_slow,0,MODE_SMMA,PRICE_CLOSE);
		if(MA_handle_slow==INVALID_HANDLE) Print(" Failed to get handle of the iMA Slow indicator");
		
		MA_handle_slowest=iMA(NULL,0,ma_period_slowest,0,MODE_SMA,PRICE_CLOSE);
		if(MA_handle_slowest==INVALID_HANDLE) Print(" Failed to get handle of the iMA Slowest indicator");
		
		ATR_handle = iATR(NULL,0,atr_period);
		if(ATR_handle==INVALID_HANDLE) Print(" Failed to get handle of the ATR indicator");
		
		BB_handle=iBands(NULL,0,BB_Period,0,BB_Dispersion,PRICE_CLOSE);
		if(BB_handle==INVALID_HANDLE) Print(" Failed to get handle of the BB indicator");

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
   
      double MA_fast[],MA_slow[],MA_slowest[],  ATR[], Upper[], Lower[];
     

   //--- copy newly appeared data in the arrays
      if(CopyBuffer(MA_handle_fast,0,0,3,MA_fast)<=0) return;
      if(CopyBuffer(MA_handle_slow,0,0,3,MA_slow)<=0) return;
      if(CopyBuffer(MA_handle_slowest,0,0,3,MA_slowest)<=0) return;
      if(CopyBuffer(ATR_handle,0,0,3,ATR)<=0) return;
      if(CopyBuffer(BB_handle,1,0,3,Upper)<=0) return;
      if(CopyBuffer(BB_handle,2,0,3,Lower)<=0) return;
      
		bool buy = false, sell= false, close= false, pyr = false;
		double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5); 
		double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5); 
   
    if(!PositionSelect(_Symbol)) 
      {
         buy   =(MA_fast[0] <MA_slow[0] && MA_fast[1] > MA_slow[1]);
         sell  = (MA_fast[0] > MA_slow[0] && MA_fast[1] < MA_slow[1]) ;
         close = false;pyr = false;
       }
       else{    

			HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));  
			double dir = PositionGetInteger(POSITION_TYPE);
 
			double cop =  LastDealOpenPrice();
           // Si ha recorrido un ATR respecto al anterior deal y el numero de posiciones es menor q positions
		   if( HistoryOrdersTotal() < positions  && (cop + ATR[0] < Ask && dir == ORDER_TYPE_BUY || ( cop - ATR[0] >  Bid && dir == ORDER_TYPE_SELL)))
           {
               if (dir == ORDER_TYPE_BUY)
                {
                 pyr=( Bid > Lower[0]);
                  if (pyr) 
                        printf(" pyr position  by signal : Bid  : " + Bid + " Lower[0] "  + Lower[0]);
                 }
          
          else if (dir == ORDER_TYPE_SELL)
                  {
                   pyr =( Ask < Upper[0]);
                     if (pyr) 
                        printf(" pyr position  by signal : Ask  : " + Ask + " Upper[0] "  + Upper[0]);
                   }
            }
            else{ //cerramos  
				if (dir == ORDER_TYPE_BUY)
						{
							close =  ( Ask < Lower[0]);
								if (close)
									printf(" position close by signal : Ask  : " + Ask + " Lower[0] "  + Lower[0]);
						}
					else if (dir == ORDER_TYPE_SELL)
					{
						close =( Bid > Upper[0] );
							if (close)
									printf(" position close by signal :Bid  : " + Bid + " Upper[0] "  + Upper[0]);
					}
				}  
       }
      
      if (!PositionSelect(_Symbol)) 
      {
      if(buy) 
            if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>3000)      	// cuanto es lo minimo para apostar ??
              {
              printf("VERDE pips : " + ATR[0]*Volatility );
               trade.PositionOpen(_Symbol,                                          
                                  ORDER_TYPE_BUY,                                   
                                  Money_M(),                                        
                                  Ask,                                              
                                  Ask - ATR[0]*Volatility,                          
                                  Ask + ATR[0]*5*Volatility,                        
                                  " entramos pa dentro ");                                             
              }
   
        if (sell)
            if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>3000)      // if we have enough money
              {
               printf("ROJO pips : " + ATR[0]*Volatility );
               trade.PositionOpen(_Symbol,                  
                                  ORDER_TYPE_SELL,          
                                  Money_M(),                
                                  Bid,                      
                                  Bid + ATR[0]*Volatility, 
                                  Bid - ATR[0]*5*Volatility,
                                  " Salimos pa fuera");     
              }
            }
         else
         {
            if (close)
                     {
                        trade.PositionClose(_Symbol,1);
                     }
         }
		 buy = false; sell = false; close = false;
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
  