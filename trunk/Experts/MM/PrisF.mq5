//+----------------------------------------------------------------------------+
//|                                                                   Pris.mq5 |
//|                                         Copyright © 2011, David Monteagudo |
//+----------------------------------------------------------------------------+
#property copyright "David Monteagudo"

#include <Trade\Trade.mqh>    
#include <Trade\AccountInfo.mqh>
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int ma_period_fast=10;         
input int ma_period_slow = 18;  
input int ma_period_slowest = 4500;  
input int atr_period = 14;
input int BB_Period = 40;
input double BB_Dispersion = 2;


//--- Money and risk management input parameters

input int positions =2 ;
input double volP = 6; 
input double vol = 3; 
input double  dist = 2.5 ;
input double tp = 6;
input double Risk  = 0.1;
 

int  MaxNumberOrders  ; 
int  MA_handle_fast,MA_handle_slow,MA_handle_slowest, ATR_handle, BB_handle,RSI_Handle;

CTrade trade;  
CAccountInfo account ;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      MaxNumberOrders=0;
      
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

    RSI_Handle = iRSI(NULL,0,atr_period,PRICE_CLOSE);
     if(RSI_Handle==INVALID_HANDLE) Print(" Failed to get handle of the RSI indicator");
   return(0);
  }
  
/*
void OnDeinit(const int reason)
{
   IndicatorRelease(MA_handle_fast); 
   IndicatorRelease(MA_handle_slow); 
   IndicatorRelease(MA_handle_slowest); 
   IndicatorRelease(ATR_handle);  
   IndicatorRelease(RSI_Handle);  
   IndicatorRelease(BB_handle);  

}
*/

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
     {
   
    int Mybars=Bars(_Symbol,_Period);
      if(Mybars<100)
        {
         Alert("We have less than 100 bars on the chart, the Expert Advisor will exit!!!");
         return;
        }
   
      double MA_fast[],MA_slow[],MA_slowest[],  ATR[], Upper[], Lower[],RSI[];
     
      if(CopyBuffer(MA_handle_fast,0,0,3,MA_fast)<=0) return;
      if(CopyBuffer(MA_handle_slow,0,0,3,MA_slow)<=0) return;
      if(CopyBuffer(MA_handle_slowest,0,0,3,MA_slowest)<=0) return;
      if(CopyBuffer(ATR_handle,0,0,3,ATR)<=0) return;
      if(CopyBuffer(BB_handle,1,0,3,Upper)<=0) return;
      if(CopyBuffer(BB_handle,2,0,3,Lower)<=0) return;
      if(CopyBuffer(RSI_Handle,0,0,3,RSI)<=0) return;
      
       ArraySetAsSeries(MA_fast,true);
       ArraySetAsSeries(MA_slow,true);
       ArraySetAsSeries(MA_slowest,true);
	    ArraySetAsSeries(ATR,true);
	    ArraySetAsSeries(Upper,true);
	    ArraySetAsSeries(Lower,true);
	    ArraySetAsSeries(RSI,true);
      
    bool buy = false, sell= false, close= false, pyr = false;
    
    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5); 
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5); 
   
   
     HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));  
    int dir = PositionGetInteger(POSITION_TYPE);
    
		// if there is no open positions check signal
    if(!PositionSelect(_Symbol)) 
      {
         buy   =(MA_fast[0] > MA_slow[0] && MA_fast[1] < MA_slow[1]);
               if (buy){ printf("");  printf("Signal Buy"); }
         sell  = (MA_fast[0] < MA_slow[0] && MA_fast[1] > MA_slow[1]) ;
                 if (sell) {printf("");  printf("Signal Sell");}
         close = false;pyr = false;
       }
     else // check pyramiding
       {    
			  double cop =  LastDealOpenPrice(); 
			
			   if ((dir == ORDER_TYPE_BUY && (cop + ATR[0]*dist) < Ask)	||	 (dir == ORDER_TYPE_SELL && (cop - ATR[0]*dist) > Bid  )) 
				{ 
			   if( HistoryOrdersTotal() < MaxNumberOrders && PositionGetDouble(POSITION_VOLUME)<=14.9) 
		
				   {
						  if (dir == ORDER_TYPE_BUY)    
						   {
								pyr=(RSI[0] < 49);
								if (pyr) {
										printf("Buy another deal ");
										deal(dir,  NormalizeDouble(ATR[0]*volP,5),true);
										Sleep(1000);
										}		
							}
						   else if ( dir == ORDER_TYPE_SELL)
							 {
								pyr =( RSI[0] > 51);
								if (pyr)  {
											printf("Sell another deal " );
											deal(dir,   NormalizeDouble(ATR[0]*volP,5), true);
											Sleep(1000);
											}
							  }
							   
					}
					//  check close
			 else  if ((dir == ORDER_TYPE_BUY && (cop + ATR[0]*dist*2) < Ask) ||  (dir == ORDER_TYPE_SELL && (cop - ATR[0]*dist*2) > Bid  ))  
					   {
							if (dir == ORDER_TYPE_SELL)
								{
								  close =  ( Ask < Lower[0]);
									if (close)
									{
										printf("Position BUY close by signal ");
									   printf("Position volumen: "  + PositionGetDouble(POSITION_VOLUME) +" position profit: "  + PositionGetDouble(POSITION_PROFIT));
										trade.PositionClose(_Symbol,1);
									}
								}
							  else if (dir == ORDER_TYPE_BUY)
							  {
								close =( Bid > Upper[0] );
								  if (close)  
									{
										printf("Position SELL close by signal " );
										printf("position volumen: "  + PositionGetDouble(POSITION_VOLUME) +" position profit: "  + PositionGetDouble(POSITION_PROFIT));
										trade.PositionClose(_Symbol,1);
									}

							  }
						}  
				}
			}
      
      //Calculate the number of deals by position
      if (!PositionSelect(_Symbol) && (buy || sell)) 
      {
         if((buy && Bid  > MA_slowest[0])||( sell && Ask  < MA_slowest[0]  ) )
               {         
               if(buy) printf(  "Just one BUY "  );
                else if (sell) printf(  "Just one SELL "  );
                 MaxNumberOrders  = 1;
              }
         else if ((buy && Ask  < MA_slowest[0]) ||( sell && Bid > MA_slowest[0])) 
               { 
                if(buy) printf(  positions + " Positions BUY  "  );
                else if (sell) printf(  positions + " Positions SELL"  );
                 MaxNumberOrders  =  positions;
               }  
              
				if (buy)  deal(ORDER_TYPE_BUY, NormalizeDouble(ATR[0]*vol,5),false);
				else if (sell)deal(ORDER_TYPE_SELL, NormalizeDouble(ATR[0]*vol,5),false);
	
        }
         
     buy = false; sell = false; close = false; pyr = false;
   }   




bool deal(long dir,  double pips, bool pyr)
{

      printf( "Deal with " +pips  + " pips. Take profit : " + pips*tp);
      if(dir == ORDER_TYPE_BUY)      
                    {
                    trade.PositionOpen(_Symbol,                                          
                                        ORDER_TYPE_BUY,                                   
                                        Money_M(pips,pyr),                                        
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5),                                              
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5) - pips,                          
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5) + pips*tp,                        
                                        " BUY ");   
                       return true;                                          
                    }
                    else if (ORDER_TYPE_SELL)
                    {
                     trade.PositionOpen(_Symbol,                                          
                                        ORDER_TYPE_SELL,                                   
                                        Money_M(pips,pyr),                                        
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5),                                              
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5) + pips,                          
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5) - pips*tp,                        
                                        " SELL ");      
                        return true;
                    }
                    return false;
}


  
double getLot(double pips)
{
   double risk = account.FreeMargin()*Risk;
   pips = pips *100000 ;
   double lot = -1 ;
   lot = risk /pips ;
    if (PositionSelect(_Symbol))
    if ( (lot +PositionGetDouble(POSITION_VOLUME))  > 15.0 )
            lot = 14.99 -  PositionGetDouble(POSITION_VOLUME);
            return ((NormalizeDouble(lot,2)));
}

// filtro:
// Si la volatilidad de la vela es superior a la media de los ultimos x momentos
// la entrada no se considera una opcion
double fixedFractional(double pips )
{
   pips = pips *100000 ;
   double risk =  MathSqrt(account.FreeMargin()*pips*Risk);
   double lot = -1 ;
    printf("el riesgo que queremos es: " + risk +" pips " + pips);
   lot = risk /pips ;
   return ((NormalizeDouble(lot,2)));
}

double fixedRatio(double pips)
{
double DD = 16000;
  double Equity =AccountInfoDouble(ACCOUNT_FREEMARGIN);
  double DeltaNeutro = DD/2;
  double value = 1 + 8*(Equity/DeltaNeutro );
  double valuesqrt = sqrt(value);
  double N = 1 + ( valuesqrt / 2);
  N = N*0.1;
  printf( " N " + N + " valuesqrt " +  valuesqrt  );
  
  printf("el riesgo que queremos es: " + (pips*  N*100000)+" pips " + pips + " lot: " + N);

 return ((NormalizeDouble( N,2)));
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
  
  
