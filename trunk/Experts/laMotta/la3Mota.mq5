
#property copyright "hippie Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <IAMotta\RiskManagement.mqh>
                                
input int    TakeProfit   = 1200; 		     // Take Profit distance solo se ejecuta si el volumen es menor q PeakVolumen              


input int bands_period     = 90;            // Bollinger Bands period
input double deviation     = 2.33;          // Standard deviation  // 2.33

//---indicator parameters pyr 
input int bands_periodPyr= 25;            // Bollinger Bands period PYR
input int bands_periodThirdPyr= 60;            // Bollinger Bands period PYR

input int InpFastEMA       = 12;              // InpFastEMA LaMotta
input int InpSlowEMA       = 25 ;            // InpSlowEMA LaMotta
input int  InpSlowestEMA   = 850;            // InpSlowestEMA LaMotta
   
   
input ENUM_TIMEFRAMES period = PERIOD_H1;


// risk management
input double volP = 15; // volatilidad que arriesgamos en la entrada
input double vol = 6; 
input double risk = 0.15; // cantidad de la cuenta
input int MaxNOrders = 3;


class LaMotta   
  {
protected:
   double          sl, tp ;         
   int             m_pMA;                           // MA period
   int             Bands_handle_thirdPYR, Bands_handle_PYR, Bands_handle, EMAFastMaHandle, EMASlowMaHandle , EMASlowestMaHandle;           
   double      	   FastEma[],SlowEma[] , SlowestEma[];			// EMA lines
   string          m_smb; ENUM_TIMEFRAMES m_tf ; 
   RiskManagement rm;
   double      	  Base[], Upper[],  Lower[];     //  BASE_LINE, UPPER_BAND and LOWER_BAND  of iBands
   int            MaxNumberOrders  ; 
public:
	void        LaMotta();
	void       ~LaMotta();
	
	 bool      Init(string smb,ENUM_TIMEFRAMES tf); // initialization
	 bool      Main();                              // main function
	 
	void      OpenPosition(long dir);              // open position on signal
	void      ClosePosition(long dir) ;
	void      PyrPosition() ;
	long      CheckSignal(long type);            // check signal
	long      CheckFilter(long type);  
	void      Deal(long type, int order,bool pyr); 
	long      LastClosePrice(int dir);
   long       CheckSignalClose(long dir, bool bEntry);
   bool      getMaxNumerOrders(long dir);
	long          CheckSignalThirdPyr(long dir, bool bEntry);
	// to piramiding
	 long      	   CheckSignalPyr(long type, bool bEntry);            // check signal

	 long     	   CheckFilterPyr(long type);  
    long          CheckDistance(long type, bool bEntry);
    double        LastDealOpenPrice();
    
   
  };
//------------------------------------------------------------------	LaMotta
void LaMotta::LaMotta() { }
//------------------------------------------------------------------	~LaMotta
void LaMotta::~LaMotta()
  {
   IndicatorRelease(Bands_handle); // delete indicators
   IndicatorRelease(EMAFastMaHandle); 
   IndicatorRelease(EMASlowMaHandle); 
   IndicatorRelease(Bands_handle_PYR);  
   IndicatorRelease(Bands_handle_thirdPYR); 
   
  }
//------------------------------------------------------------------	
//    Init
//------------------------------------------------------------------	
bool LaMotta::Init(string smb,ENUM_TIMEFRAMES tf)
  {
	  printf(__FUNCTION__+ " ### start ### "  );
	 m_smb=smb ; m_tf=tf ; 
	if (!rm.Init(0,m_smb,tf)) return(false);  // initialize object RiskManagement

	tp=TakeProfit;   sl=-1; 
	MaxNumberOrders = 0;
    m_pMA = bands_period;
   	//--- creation of the indicator iBands
	Bands_handle=iBands(_Symbol,period,bands_period,0,deviation,PRICE_CLOSE);
	Bands_handle_PYR=iBands(_Symbol,period,bands_periodPyr,0,deviation,PRICE_CLOSE);
	Bands_handle_thirdPYR=iBands(_Symbol,period,bands_periodThirdPyr,0,deviation,PRICE_CLOSE);
   	
	EMAFastMaHandle=iMA(_Symbol,period,InpFastEMA,0,MODE_SMMA,PRICE_CLOSE);
	EMASlowMaHandle=iMA(_Symbol,period,InpSlowEMA,0,MODE_SMMA,PRICE_CLOSE);
	EMASlowestMaHandle=iMA(_Symbol,period,InpSlowestEMA,0,MODE_SMMA,PRICE_CLOSE);
   		  
	//--- report if there was an error in object creation
	   if(Bands_handle<0 || EMAFastMaHandle < 0 || EMASlowMaHandle < 0 || Bands_handle_PYR <0 || EMASlowestMaHandle < 0 )
		 {
		  printf(__FUNCTION__+"The creation of indicator has failed: Runtime error = " + GetLastError());
		  return(-1);
		 }

	   return(true);                         // "trade allowed"
  }
//------------------------------------------------------------------	
//    Mainfunction
//------------------------------------------------------------------	
bool LaMotta::Main()
  {
 	   if(!rm.Main()) return(false); // call function of parent class
	   if(Bars(m_smb,m_tf)<=m_pMA) return(false); // if there are insufficient number of bars
	   if (rm.m_account.FreeMargin()<2000) return false;

	 
	 if(!PositionSelect(m_smb)) 
	 {
	   OpenPosition(ORDER_TYPE_SELL); 
       OpenPosition(ORDER_TYPE_BUY); 
	 }
     else 
         {
		  if(PositionGetInteger(POSITION_TYPE)!= CheckDistance(PositionGetInteger(POSITION_TYPE), true  )) return false;
		  
			HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));   
				if(  HistoryOrdersTotal()  < MaxNumberOrders  )
				{
					 
					  PyrPosition(); 
				 }
				 else{
				  ClosePosition(PositionGetInteger(POSITION_TYPE));
				 }
		}		 
	   return(true);
  }

//------------------------------------------------------------------	
// Open Position
//------------------------------------------------------------------
  void LaMotta::OpenPosition(long dir)
  {
           
             if(dir!=CheckSignal(dir)) return;// if there is no signal for current direction
                 if(dir!=CheckFilter(dir)) return;// if there is no signal for current direction     
                printf(__FUNCTION__+ " ### EMA cruzada   ### "  );      
                  Deal(dir, 0,false);
                
                }
 
 //------------------------------------------------------------------	
// Open Position
//------------------------------------------------------------------
  void LaMotta::PyrPosition()
  { 
                   if (HistoryOrdersTotal()  < MaxNumberOrders -1)	// solo existe una posicion
                        if(PositionGetInteger(POSITION_TYPE)==CheckSignalPyr(PositionGetInteger(POSITION_TYPE), true)) 
                        {
                        printf("  * piramida *  " );
                        printf(__FUNCTION__+ " Dispersion BB 20 tocada . Deal numero: " + HistoryOrdersTotal() );
                  	   Deal(PositionGetInteger(POSITION_TYPE), HistoryOrdersTotal(),true);                 	   
                        return ;
                        }
					 if (HistoryOrdersTotal()  < MaxNumberOrders )	// existen dos posiciones
						if(PositionGetInteger(POSITION_TYPE)==CheckSignalThirdPyr(PositionGetInteger(POSITION_TYPE), true))  // aunq parezca extraño el checksignalclose sirve
					           {
                        printf("  * piramida *  " );
                        printf(__FUNCTION__+ " Dispersion BB 90 tocada . Deal numero: " + HistoryOrdersTotal() );
                  	   Deal(PositionGetInteger(POSITION_TYPE), HistoryOrdersTotal(),true);                 	   
                        return ;
                        }
			

  }

  
  
 //------------------------------------------------------------------	
// Close Position if the price touch the bollinger bands an the volumen is more than PeakVolumen
//------------------------------------------------------------------ 
  void LaMotta::ClosePosition(long dir)
  {       

      if(dir!=CheckSignalClose(dir, false)) return;
         printf(__FUNCTION__+ "MaxNumberOrders " +MaxNumberOrders+ "POSITION CERRADA: POSITION_VOLUME: "  + PositionGetDouble(POSITION_VOLUME) +" POSITION_PROFIT: "  + PositionGetDouble(POSITION_PROFIT));
         printf(__FUNCTION__+ "HistoryOrdersTotal " +HistoryOrdersTotal()+ "POSITION CERRADA: ACCOUNT_BALANCE: "  + AccountInfoDouble(ACCOUNT_BALANCE) +" ACCOUNT_EQUITY: "  + AccountInfoDouble(ACCOUNT_EQUITY));
         rm.m_trade.PositionClose(m_smb,1);
  }


//------------------------------------------------------------------	
// Check Signal
//------------------------------------------------------------------ 
long LaMotta::CheckSignal(long dir)
  {  
   if(!CopyBufferAsSeries(EMAFastMaHandle,0,0,InpFastEMA,true,FastEma)) return(false);
   if(!CopyBufferAsSeries(EMASlowMaHandle,0,0,InpSlowEMA,true,SlowEma)) return(false);

  if(dir == ORDER_TYPE_BUY && FastEma[0] > SlowEma[0] && FastEma[1] < SlowEma[1]) // cambiado
   
   {         
   printf(__FUNCTION__+ " Ema Cruzada: to buy "  + rm.ea.BasePrice( dir) );
    return(ORDER_TYPE_BUY);    }

 else if(dir == ORDER_TYPE_SELL && FastEma[0] < SlowEma[0] &&  FastEma[1] > SlowEma[1])
    {         
     printf(__FUNCTION__+ " Ema Cruzada: to sell "  + NormalizeDouble(rm.ea.BasePrice( dir),5) );
     return(ORDER_TYPE_SELL);   }
   return(WRONG_VALUE);
  }

//------------------------------------------------------------------	
// Check Filter
//------------------------------------------------------------------ 
 
long LaMotta::CheckSignalClose(long dir, bool bEntry)
  {  
      if(!GetBandsBuffers(Bands_handle,0,bands_period,Base,Upper,Lower,true)) return (-1);          
          if( rm.ea.BasePrice( dir) < Lower[0]   )
               {  
					// printf(__FUNCTION__+ " Dispersion negativa tocada x S    ORDER_TYPE_BUY  Lower: " + NormalizeDouble(Lower[0],5)  + " Ask: " +NormalizeDouble(rm.ea.BasePrice(dir),5));
                     return(bEntry ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
               }
          else  if(  rm.ea.BasePrice( dir)  > Upper[0])
                   {  
					//	printf(__FUNCTION__+ " Dispersion Positivatocada x S    ORDER_TYPE_SELL      Upper: " +  NormalizeDouble(Upper[0],5)+ " Bid: "  + NormalizeDouble(rm.ea.BasePrice(dir),5) );
                        return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for buy
                   }
   return(WRONG_VALUE);
  }
  
  
//------------------------------------------------------------------	
// Check Filter
//------------------------------------------------------------------ 
long LaMotta::CheckFilter(long dir)
{   
   if(!CopyBufferAsSeries(EMAFastMaHandle,0,0,InpFastEMA,true,FastEma)) return(false);
   if(!CopyBufferAsSeries(EMASlowMaHandle,0,0,InpSlowEMA,true,SlowEma)) return(false);

  if(dir == ORDER_TYPE_BUY && FastEma[0] > SlowEma[0]) // cambiado
   
   {         
  printf(__FUNCTION__+ " Ema Cruzada: to buy "  + NormalizeDouble(rm.ea.BasePrice( dir),5)  );
    return(ORDER_TYPE_BUY);    }

 else if(dir == ORDER_TYPE_SELL && FastEma[0] < SlowEma[0])
    {         
    printf(__FUNCTION__+ " Ema Cruzada: to sell "  + NormalizeDouble(rm.ea.BasePrice( dir),5) );
     return(ORDER_TYPE_SELL);   }
   return(WRONG_VALUE);
}
  

//------------------------------------------------------------------	
//------------------------------------------------------------------ 
void LaMotta::Deal(long dir, int order,bool pyramiding)     // eliminado ratio, necesidad de dos deal diferentes para pir y para entrada inciial ¿?
{
 double Risk = rm.m_account.FreeMargin()*risk;
 
   if (pyramiding == true)           //piramida
   {
    double pips= rm.getPips();
    pips = pips * volP ; // pongo un stop de 3/2 del ATR
    double riesgo = Risk*2;
    double lot =(riesgo + PositionGetDouble(POSITION_PROFIT)) /pips;
             
    printf(__FUNCTION__+ " riesgo:  " + riesgo  + " pips " +pips+ " POSITION_PROFIT " + PositionGetDouble(POSITION_PROFIT));
              
    lot = lot - PositionGetDouble(POSITION_VOLUME);
             
    if ( (lot +PositionGetDouble(POSITION_VOLUME))  > 15.0 )	      lot = 14.9 -  PositionGetDouble(POSITION_VOLUME);
    if ( lot   > 5.0 )    											  lot = 5.0;
          
    double totalVolumen   =  (PositionGetDouble(POSITION_VOLUME) + lot ) ;           
    printf(__FUNCTION__+ " Posicionamos con un stop de  " + pips/10  + " pips. Volumen de deal " +lot+ " totalVolumen : "+totalVolumen+" Risk : "  + pips* lot );
               
    rm.DealOpen(dir,lot,pips/10,tp);
   }
   
   else
   {    
          if ( !getMaxNumerOrders(dir)) return;
            double pips=   rm.getPips();
            pips = pips * vol; 
            double lot = Risk /pips ;
            
              if ( lot   > 5.0 )
                      lot = lot = 5.0;
                      
            printf(__FUNCTION__+ " Abrimos posicion con un stop de  " +pips/10  + " pips. Volumen de " +lot+ " Risk de: "  + pips* lot);
            rm.DealOpen(dir,lot, pips/10, tp);
            
    }
 }   
 /*
 -------------------------FUNCIONES PIRAMIDACION --------------------------
 */
 
//------------------------------------------------------------------	
// Check Signal
//------------------------------------------------------------------ 
long LaMotta::CheckSignalPyr(long dir, bool bEntry)
  {  
      if(!GetBandsBuffers(Bands_handle_PYR,0,bands_periodPyr,Base,Upper,Lower,true)) return (-1);
           if( rm.ea.BasePrice( dir) < Lower[0]   )
               {  
                   //  printf(__FUNCTION__+ " Dispersion negativa tocada x S    ORDER_TYPE_BUY  Lower: " + NormalizeDouble(Lower[0],5)  + " Ask: " +NormalizeDouble(rm.ea.BasePrice(dir),5));
                     return(bEntry ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
               }

          else  if(  rm.ea.BasePrice( dir)  > Upper[0])
                   {  
                     //    printf(__FUNCTION__+ " Dispersion Positivatocada x S    ORDER_TYPE_SELL      Upper: " +  NormalizeDouble(Upper[0],5)+ " Bid: "  + NormalizeDouble(rm.ea.BasePrice(dir),5) );
                        return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for buy
                   }

   return(WRONG_VALUE);
  }
  
  //------------------------------------------------------------------	
// Check Signal
//------------------------------------------------------------------ 
long LaMotta::CheckSignalThirdPyr(long dir, bool bEntry)
  {  
      if(!GetBandsBuffers(Bands_handle_thirdPYR,0,bands_periodPyr,Base,Upper,Lower,true)) return (-1);
           if( rm.ea.BasePrice( dir) < Lower[0]   )
               {  
                     printf(__FUNCTION__+ " third pyr : " + NormalizeDouble(Lower[0],5)  + " Ask: " +NormalizeDouble(rm.ea.BasePrice(dir),5));
                     return(bEntry ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
               }

          else  if(  rm.ea.BasePrice( dir)  > Upper[0])
                   {  
                        printf(__FUNCTION__+ "third pyr " +  NormalizeDouble(Upper[0],5)+ " Bid: "  + NormalizeDouble(rm.ea.BasePrice(dir),5) );
                        return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for buy
                   }

   return(WRONG_VALUE);
  }

//------------------------------------------------------------------	
// calcula el número máximo de ordenes de piramidación.
// Si todos devuelven true, significa que entrará al mercado buscando piramidar y no piramidar.
// Si devuleven false cuando  MaxNumberOrders  = 1 significa que el sistema solo piramidará.
// que ocurre si el programa se para durante el fin de semana ? la variable del contexto
// MaxNumberOrders volvería a ser 1 o 2 ?
//------------------------------------------------------------------	
 bool LaMotta::getMaxNumerOrders(long dir) 
 {
 
 if(!CopyBufferAsSeries(EMASlowestMaHandle,0,0,InpSlowestEMA,true,SlowestEma)) return(false);

 if(dir == ORDER_TYPE_BUY && rm.ea.BasePrice(dir)  > SlowestEma[0]) 
   
   {         
     printf(__FUNCTION__+ " ORDER_TYPE_buy  MaxNumberOrders = 1 "   );
     MaxNumberOrders  = 1;
	 return(true);
  }
   else if(dir == ORDER_TYPE_BUY && rm.ea.BasePrice(dir)  < SlowestEma[0]) 
   
   {         
     printf(__FUNCTION__+ "  ORDER_TYPE_BUY MaxNumberOrders =  " + MaxNOrders   );
     MaxNumberOrders  =  MaxNOrders;
	 return(true);
   }


 else if(dir == ORDER_TYPE_SELL && rm.ea.BasePrice(dir) < SlowestEma[0])
    {         
       printf(__FUNCTION__+ " ORDER_TYPE_SELL MaxNumberOrders   =1 "   );
      MaxNumberOrders   =1;
	  return(true);
      } 
   else  if(dir == ORDER_TYPE_SELL && rm.ea.BasePrice(dir) > SlowestEma[0])
    {         
       printf(__FUNCTION__+ " ORDER_TYPE_SELL MaxNumberOrders   = "  + MaxNOrders );
       MaxNumberOrders   = MaxNOrders;
	   return(true);
   } 
    return(true);
 }
 
//------------------------------------------------------------------	
// calculate the distance necessary to process a new deal
//------------------------------------------------------------------ 
  long LaMotta::CheckDistance(long dir, bool bEntry)
{   
      double atr,cop,apr;
         atr = rm.getN();                              // numero de points que tiene que distanciarse
         cop = LastDealOpenPrice();						// precio del último deal
         apr = rm.ea.BasePrice( dir);                  // precio objetivo actual

        if( cop + atr <  rm.ea.BasePrice( dir))      
            {  
			//  printf(__FUNCTION__+ " LastDealOpenPrice  " +cop  + " atr: " +atr+ " BasePrice: "  + NormalizeDouble( rm.ea.BasePrice( dir),4));
                 return(bEntry ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
           }
       else if( cop - atr >  rm.ea.BasePrice( dir))
          {       
			//   printf(__FUNCTION__+ " LastDealOpenPrice  " +cop  + " atr: -" +atr+ " BasePrice: "  + NormalizeDouble(rm.ea.BasePrice( dir),4));
               return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for sell
          }
         return(WRONG_VALUE);
}
//------------------------------------------------------------------	
// Last deal open price to calculate the distance necessary to process a new deal
//------------------------------------------------------------------ 
double LaMotta::LastDealOpenPrice()
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
  
  




    
LaMotta prisEURUSD; // class instance
//------------------------------------------------------------------	OnInit
int OnInit()
  {
   prisEURUSD.Init(Symbol(),Period()); // initialize expert

   return(0);
  }
//------------------------------------------------------------------	OnDeinit
void OnDeinit(const int reason) { }
//------------------------------------------------------------------	OnTick
void OnTick()
  {
   prisEURUSD.Main(); // process incoming tick
  }
//+------------------------------------------------------------------+
