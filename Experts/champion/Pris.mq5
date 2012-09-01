//+------------------------------------------------------------------+
//      
//Consideraciones generales
//Sistema tipo swing ==> escasas oportunidades de podium pero altas top ten

// probar errores 
// Algo guay para este sistema es que si el precio ha recorrido mucha distancia
// y no ha metido su segunda orden se mete y punto !!!

//+------------------------------------------------------------------+
#property copyright "hippie Corp."

#include <Trade\Trade.mqh>    
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int ma_period_fast=12;         
input int ma_period_slow = 24;  
input int ma_period_slowest = 850;  
input int atr_period = 14;
input int DD = 5000;
input int positions = 2 ;

input int BB_Period = 40;
input double BB_Dispersion = 1.8;


//--- input parameters
input double Volatility       =  3; // SL
input double VolatilityP      =  6;// SLP
input int  dist = 6 ;


int            MaxNumberOrders  ; 
int  MA_handle_fast,MA_handle_slow,MA_handle_slowest, ATR_handle, BB_handle;

CTrade trade;  

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

   return(0);
  }
  
  /**
void OnDeinit(const int reason)
{
   IndicatorRelease(MA_handle_fast); // delete indicators
   IndicatorRelease(MA_handle_slow); 
   IndicatorRelease(MA_handle_slowest); 
   IndicatorRelease(ATR_handle);  
   IndicatorRelease(BB_handle);  

}
*/
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
      
       ArraySetAsSeries(MA_fast,true);
       ArraySetAsSeries(MA_slow,true);
       ArraySetAsSeries(MA_slowest,true);
	    ArraySetAsSeries(ATR,true);
	    ArraySetAsSeries(Upper,true);
	    ArraySetAsSeries(Lower,true);
      
    bool buy = false, sell= false, close= false, pyr = false;
    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5); 
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5); 
   
   
     HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));  
    int dir = PositionGetInteger(POSITION_TYPE);
    
		// Si no hay posiciones abiertas Analisis de señales de  buy, sell 
    if(!PositionSelect(_Symbol)) 
      {
         buy   =(MA_fast[0] > MA_slow[0] && MA_fast[1] < MA_slow[1]);
               if (buy) printf(" Signal Buy");
         sell  = (MA_fast[0] < MA_slow[0] && MA_fast[1] > MA_slow[1]) ;
                 if (sell) printf(" Signal Sell");
         close = false;pyr = false;
       }
     else // Si existen posiciones abiertas buscamos piramidar o cerrar 
       {    
			  double cop =  LastDealOpenPrice(); // precio último deal
			  //Si el precio esta a una distancia adecuada seguimos para cerrar o piramidar
			   if ((dir == ORDER_TYPE_BUY && (cop + ATR[0]*dist) < Ask)	// BUY && C + ATR < S
									||
				 (dir == ORDER_TYPE_SELL && (cop - ATR[0]*dist) > Bid  ))  // SELL && C - ATR > S
				{ 
			   if( HistoryOrdersTotal() < MaxNumberOrders ) 
		
				   {
						// printf(" Precio ya esta a una distancia adecuada  Bid: " + Bid + " cop: "  + cop );
						  if (dir == ORDER_TYPE_BUY)    
						   {
								pyr=(Bid < Lower[0]);
								if (pyr) {
										printf(" pyr position  by signal : Bid  : " + Bid + " Lower[0] "  + Lower[0]);
										deal(dir,  ATR[0]*VolatilityP);
										Sleep(50);
										deal(dir,  ATR[0]*VolatilityP);
										}		
							}
						   else if (dir == ORDER_TYPE_SELL)
							 {
								pyr =( Ask > Upper[0]);
								if (pyr)  {
											printf(" pyr position  by signal : Ask  : " + Ask + " Upper[0] "  + Upper[0]);
											//Atencion con apalancarse demasiado !! hay que hacer un control de esto
											//porque el volumen y los pips se calculan independientemente
											deal(dir,  ATR[0]*VolatilityP);
											Sleep(50);
											deal(dir,  ATR[0]*VolatilityP);
											}
							  }
							   
					}
					   else
					   { //cerramos  
							if (dir == ORDER_TYPE_SELL)
								{
								  close =  ( Ask < Lower[0]);
									if (close)
									{
										printf(" position BUY close by signal : Ask  : " + Ask + " Lower[0] "  + Lower[0]);
									    printf( "MaxNumberOrders " +MaxNumberOrders+ "POSITION CERRADA: POSITION_VOLUME: "  + PositionGetDouble(POSITION_VOLUME) +" POSITION_PROFIT: "  + PositionGetDouble(POSITION_PROFIT));
										printf( "HistoryOrdersTotal " +HistoryOrdersTotal()+ "POSITION CERRADA: ACCOUNT_BALANCE: "  + AccountInfoDouble(ACCOUNT_BALANCE) +" ACCOUNT_EQUITY: "  + AccountInfoDouble(ACCOUNT_EQUITY));
										trade.PositionClose(_Symbol,1);
									}
								}
							  else if (dir == ORDER_TYPE_BUY)
							  {
								close =( Bid > Upper[0] );
								  if (close)  
									{
										printf(" position SELL close by signal :Bid  : " + Bid + " Upper[0] "  + Upper[0]);
										printf( "MaxNumberOrders " +MaxNumberOrders+ "POSITION CERRADA: POSITION_VOLUME: "  + PositionGetDouble(POSITION_VOLUME) +" POSITION_PROFIT: "  + PositionGetDouble(POSITION_PROFIT));
										printf( "HistoryOrdersTotal " +HistoryOrdersTotal()+ "POSITION CERRADA: ACCOUNT_BALANCE: "  + AccountInfoDouble(ACCOUNT_BALANCE) +" ACCOUNT_EQUITY: "  + AccountInfoDouble(ACCOUNT_EQUITY));
										trade.PositionClose(_Symbol,1);
									}
							  }
						}  
				}
			}
      
      /*
      PRocesamos el deal y calculamos el numero de posiciones q va a tener
      */
      if (!PositionSelect(_Symbol) && (buy || sell)) 
      {
      // Determina el numero de piramidaciones dependiendo de la situacion del cruce de medias cortas respecto la larga
       if((buy && Bid  > MA_slowest[0])||( sell && Ask  < MA_slowest[0]  ) )
               {         
               if(buy) printf(__FUNCTION__+  " just one BUY AND bid > MA " + Bid +" > "+  MA_slowest[0]   );
                else if (sell) printf(__FUNCTION__+  " just one SELL AND Ask < MA " + Ask +" < "+  MA_slowest[0]   );
                 MaxNumberOrders  = 1;
              }
         else if ((buy && Ask  < MA_slowest[0]) ||( sell && Bid > MA_slowest[0])) 
               { 
                if(buy) printf(__FUNCTION__+  " two BUY AND bid > MA " + Bid +" > "+  MA_slowest[0]   );
                else if (sell) printf(__FUNCTION__+  " two SELL AND Ask < MA " + Ask +" < "+  MA_slowest[0]   );
                 MaxNumberOrders  =  positions;
               }  
				if (buy)  deal(ORDER_TYPE_BUY, ATR[0]*Volatility);
				else if (sell)deal(ORDER_TYPE_SELL, ATR[0]*Volatility);
        }
         
     buy = false; sell = false; close = false; pyr = false;
   }   



/*
Necesito una función que me diga en base a la direccion el precio base ! do I 
*/

bool deal(long dir,  double pips)
{
if(dir == ORDER_TYPE_BUY)        // cuanto es lo minimo para apostar ??
              {
              printf("BUY ### pips : " + pips );
              trade.PositionOpen(_Symbol,                                          
                                  ORDER_TYPE_BUY,                                   
                                  Money_M(),                                        
                                    NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5),                                              
                                    NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5) - pips,                          
                                    NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5) + pips*10,                        
                                  " BUY ");   
                 return true;                                          
              }
              else if (ORDER_TYPE_SELL)
              {
               printf("SELL ### pips : " + pips );
               trade.PositionOpen(_Symbol,                                          
                                  ORDER_TYPE_SELL,                                   
                                  Money_M(),                                        
                                    NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5),                                              
                                    NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5) + pips,                          
                                    NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5) - pips*10,                        
                                  " SELL ");      
                  return true;
              }
              return false;
}

double Money_M()
{
  long Equity =AccountInfoDouble(ACCOUNT_FREEMARGIN);
  long DeltaNeutro = DD/2;
  long value = 1 + 8*(Equity/DeltaNeutro );
  long valuesqrt = sqrt(value);
  long N = 1 + ( valuesqrt / 2);
  printf(__FUNCTION__  + "N " + N + " valuesqrt " +  valuesqrt );
if (N > 5)  N = 4.99;
 
 if (PositionSelect(_Symbol))
    if ( (N +PositionGetDouble(POSITION_VOLUME))  > 15.0 )
            N = 14.99 -  PositionGetDouble(POSITION_VOLUME);
            
  printf(__FUNCTION__  + "N " + N + " valuesqrt " +  valuesqrt + " PositionGetDouble(POSITION_VOLUME) "  +PositionGetDouble(POSITION_VOLUME) );
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
  
  
