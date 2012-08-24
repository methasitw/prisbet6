//+------------------------------------------------------------------+
//|              Copyright hippie						 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <utilsv11\ServiceFunctions.mqh>
#include <utilsv11\RiskManagement.mqh>
#include <utilsv11\PyR.mqh>



//---indicator parameters
input int bands_period= 90;                  // Bollinger Bands period
input double deviation= 2.333;               // Standard deviation  // 2.33

input int InpFastEMA =7;                     // InpFastEMA hal
input int InpSlowEMA = 12 ;                  // InpSlowEMA HAL

input int PeakVolumen      = 5;


input int ATRPeriod =14;                         // para calcular el numero de pips adecuados para entrar en el mercado     

input ENUM_TIMEFRAMES TFATR = PERIOD_D1;        // periodo para calcular el maximo y minimo anual


input ENUM_TIMEFRAMES periodEMA = PERIOD_M6;    // periodo para el filtro  
input ENUM_TIMEFRAMES periodBB = PERIOD_H4;     // periodo para la señal

// Variables piramidacion
input int bands_periodPyr= 20;            // Bollinger Bands period PYR
input double deviationPyr= 1.66;         // Standard deviation  PYR // 2.33
input int riskPosition = 6;

// Variables Risk Management
input double Risk = 0.02;    // apostamos 90 euros x entrada
input int    TakeProfit        = 1000; 		// Take Profit distance
input double volP = 13; // volatilidad que arriesgamos en la entrada
input double vol = 4; 


class HAL   
  {
protected:
   double            sl, tp ;         
   int               m_pMA;           // MA period
   int               Bands_handle, EMAFastMaHandle, EMASlowMaHandle ;           
   double      		Base[], Upper[],  Lower[];     //  BASE_LINE, UPPER_BAND and LOWER_BAND  of iBands
   double      		FastEma[],SlowEma[] ;			// EMA lines
   string m_smb ; ENUM_TIMEFRAMES m_tf ; 

   RiskManagement rm;
   PyR pyr;


public:
	void              HAL();
	void             ~HAL();
	
	virtual bool      	Init(string smb,ENUM_TIMEFRAMES tf); // initialization
	virtual bool      	Main();                              // main function
	virtual void      	OpenPosition(long dir);              // open position on signal
	virtual void         ClosePosition(long dir) ;
	virtual long      	CheckSignal(long type, bool bEntry);            // check signal
	virtual long     	   CheckFilter(long type);  
	virtual void         Deal(long type, bool pyr); 
	virtual long      PyrPosition();
	
  };
  
//------------------------------------------------------------------	HAL
void HAL::HAL() { }
//------------------------------------------------------------------	~HAL
void HAL::~HAL()
  {
   IndicatorRelease(Bands_handle); // delete indicators
   IndicatorRelease(EMAFastMaHandle); 
   IndicatorRelease(EMASlowMaHandle); 
  }
  
//------------------------------------------------------------------	
//    Init
//------------------------------------------------------------------	
bool HAL::Init(string smb,ENUM_TIMEFRAMES tf)
  {
	 
	 m_smb=smb ; m_tf=tf ;
	 
	if (!rm.Init(0,m_smb,tf)) return(false);  // initialize object RiskManagement
	if (!pyr.Init(0,m_smb,tf)) return(false);  // initialize object RiskManagement
	
	      tp=TakeProfit;   sl=-1;
   	   Bands_handle=iBands(NULL,periodBB,bands_period,0,deviation,PRICE_CLOSE);
   	   EMAFastMaHandle=iMA(NULL,periodEMA,InpFastEMA,0,MODE_EMA,PRICE_CLOSE);
   	   EMASlowMaHandle=iMA(NULL,periodEMA,InpSlowEMA,0,MODE_EMA,PRICE_CLOSE);
   		  
	//--- report if there was an error in object creation
	   if(Bands_handle<0 || EMAFastMaHandle < 0 || EMASlowMaHandle < 0  )
		 {
		  printf(__FUNCTION__+"The creation of indicator has failed: Runtime error = " + GetLastError());
		  return(-1);
		 }

	   return(true);                         // "trade allowed"
  }
  
//------------------------------------------------------------------	
//    Mainfunction
//------------------------------------------------------------------	
bool HAL::Main()
  {
	   if(!rm.Main()) return(false); // call function of parent class
	    if(!pyr.Main()) return(false); // call function of parent class
	   if(Bars(m_smb,m_tf)<=m_pMA) return(false); // if there are insufficient number of bars

	   if (rm.m_account.FreeMargin()<1500) return false;
	   
	 if(!PositionSelect(m_smb)) 
	 {
	   OpenPosition(ORDER_TYPE_SELL); 
       OpenPosition(ORDER_TYPE_BUY); 
	 }
	  else 
         {
           if(PositionGetDouble(POSITION_VOLUME) <= PeakVolumen)
					{ 
					  PyrPosition(); 
				   }
				 else{
				  ClosePosition(PositionGetInteger(POSITION_TYPE));
				 }
		}		 
	   return(true);
  }
  

 long HAL::PyrPosition()
 
 {
                      
                       if(PositionGetInteger(POSITION_TYPE)!= pyr.CheckDistance(PositionGetInteger(POSITION_TYPE) )) return 0;        
                       if(PositionGetInteger(POSITION_TYPE)!=pyr.CheckSignalPyr(PositionGetInteger(POSITION_TYPE), true )) return 0;
                              printf("                       * piramida *  " );
                              printf(__FUNCTION__+ " Precio recorre la distacia adecuada" );
                              printf(__FUNCTION__+ " Dispersion Positiva tocada piramidacion" );
                              printf(__FUNCTION__+ " Number of order by the position " + HistoryOrdersTotal()  );
                  	   Deal(PositionGetInteger(POSITION_TYPE), true);
return 1;                     	   

 }
//------------------------------------------------------------------	
// Open Position
//------------------------------------------------------------------
  void HAL::OpenPosition(long dir)
  {
    
         if(dir!=CheckSignal(dir, true)) return;// if there is no signal for current direction
         if(dir!=CheckFilter(dir))return;
      //    if(dir!=rm.marginPerformance(dir))return; // El Precio no está en un MAX / MIN absoluto  ###
         printf(__FUNCTION__+ " ### EMA cruzada  y BB fuera de dispersion ### dir" + dir );      
         Deal(dir, false);
  }
 //------------------------------------------------------------------	
// Close Position if the price touch the bollinger bands an the volumen is more than PeakVolumen
//------------------------------------------------------------------ 
  void HAL::ClosePosition(long dir)
  {
         if(dir!=PositionGetInteger(POSITION_TYPE)) return;
         if(dir!=CheckSignal(dir, false)) return;

    
         printf(__FUNCTION__+ "POSITION CERRADA: POSITION_VOLUME: "  + PositionGetDouble(POSITION_VOLUME) +" POSITION_PROFIT: "  + PositionGetDouble(POSITION_PROFIT));
         printf(__FUNCTION__+ "POSITION CERRADA: ACCOUNT_BALANCE: "  + AccountInfoDouble(ACCOUNT_BALANCE) +" ACCOUNT_EQUITY: "  + AccountInfoDouble(ACCOUNT_EQUITY));
         rm.m_trade.PositionClose(m_smb,1);

         
  }

//------------------------------------------------------------------	
// Check Signal
//------------------------------------------------------------------ 
long HAL::CheckSignal(long type, bool bEntry)
  {  
      if(!GetBandsBuffers(Bands_handle,0,90,Base,Upper,Lower,true)) return (-1);          
          if( rm.ea.BasePrice( type) < Lower[0]   )
               {  
                //    printf(__FUNCTION__+ " Dispersion negativa tocada x S    ORDER_TYPE_BUY  Upper: " + Lower[0]  + " Ask: " + rm.ea.BasePrice( type) );
                     return(bEntry ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
               }
          else  if(  rm.ea.BasePrice( type)  > Upper[0])
                   {  
                //      printf(__FUNCTION__+ " Dispersion Positivatocada x S    ORDER_TYPE_SELL      Upper: " + Lower[0]+ " Bid: "  + rm.ea.BasePrice( type));
                        return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for buy
                   }
   return(WRONG_VALUE);
  }

//------------------------------------------------------------------	
// Check Filter
//------------------------------------------------------------------ 
long HAL::CheckFilter(long type)
{   
   if(!CopyBufferAsSeries(EMAFastMaHandle,0,0,20,true,FastEma)) return(false);
   if(!CopyBufferAsSeries(EMASlowMaHandle,0,0,20,true,SlowEma)) return(false);

  if(type == ORDER_TYPE_BUY && FastEma[0] > SlowEma[0]) // cambiado
   
   {         
   //printf(__FUNCTION__+ " Ema Cruzada: to buy "   );
    return(ORDER_TYPE_BUY);    }

 else if(type == ORDER_TYPE_SELL && FastEma[0] < SlowEma[0])
    {       
    // printf(__FUNCTION__+ " Ema Cruzada: to sell "   );
     return(ORDER_TYPE_SELL);   }
   return(WRONG_VALUE);
}
  

//------------------------------------------------------------------	
// Deal
//------------------------------------------------------------------ 
void HAL::Deal(long dir, bool pyramiding)     // eliminado ratio, necesidad de dos deal diferentes para pir y para entrada inciial ¿?
{
 
 double risk = rm.m_account.FreeMargin()*Risk;

   if (risk > 1500)
      risk = 1500;
      
   double pips=rm.getPips();  
   if (pyramiding == true)           //piramida
   {
      
          pips = pips * volP ; // pongo un stop de 3/2 del ATR
          double riesgo = risk * (riskPosition - HistoryOrdersTotal() ) ;
           
           
             double lot =(riesgo + PositionGetDouble(POSITION_PROFIT)) /pips;
             
              printf(__FUNCTION__+ " riesgo:  " + riesgo  + " pips " +pips+ " POSITION_PROFIT " + PositionGetDouble(POSITION_PROFIT));
              
             lot = lot - PositionGetDouble(POSITION_VOLUME);
              double totalVolumen   =  (PositionGetDouble(POSITION_VOLUME) + lot ) ;           
             printf(__FUNCTION__+ " Posicionamos con un stop de  " + pips/10  + " pips. Volumen de deal " +lot+ " totalVolumen : "+totalVolumen+" Risk : "  + pips* totalVolumen );
               
             rm.DealOpen(dir,lot,pips/10,tp);
   }
   
   else
   {
     
            pips = pips * vol; // multiplicamos x 6
            double lot = risk /pips ;
            printf(__FUNCTION__+ " Abrimos posicion con un stop de  " +pips/10  + " pips. Volumen de " +lot+ " Risk de: "  + pips* lot);
            rm.DealOpen(dir,lot, pips/10, tp);
    }
 }   
    
    
HAL ScriptH; // class instance
//------------------------------------------------------------------	OnInit
int OnInit()
  {
   ScriptH.Init(Symbol(),Period()); // initialize expert


   return(0);
  }
//------------------------------------------------------------------	OnDeinit
void OnDeinit(const int reason) { }
//------------------------------------------------------------------	OnTick
void OnTick()
  {
   ScriptH.Main(); // process incoming tick
  }
//+------------------------------------------------------------------+
