#property copyright "hippie Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"


#include <utilsPris10\RiskManagement.mqh>

input double Percent      = 7;                 // el stop loose se calcula con el 0.08% de variacion del precio. puntos = basePrice * 8   1,49469 * 8 = 11 puntos
input double Risk         = 100;                 // apostamos 90 euros x entrada:  Vol = Risk/puntos = 0.88   : Risk =  Vol *puntos 
                                //Vol = Risk/puntos * 10
                                
input int    TakeProfit   = 1000; 		        // Take Profit distance solo se ejecuta si el volumen es menor q PeakVolumen
input int    PeakVolumen  = 17;              // Volumen considerado suficientemente grande como para cerrar una entrada si toca la dispersion contraria a su movimiento
input int MaxNumberOrders = 4 ;                // numero de ordenes maxima que pertenece a una posicion

//---indicator parameters
input int bands_period     = 90;             // Bollinger Bands period
input int bands_shift      = 0;              // Bollinger Bands shift
input double deviation     = 2.333;          // Standard deviation  // 2.33
input int InpFastEMA       = 7;              // InpFastEMA Pris
input int InpSlowEMA       = 12 ;            // InpSlowEMA Pris
   

input ENUM_TIMEFRAMES periodEMA = PERIOD_M6;
input ENUM_TIMEFRAMES periodBB = PERIOD_H4;

//---indicator parameters pyr 
input int bands_periodPyr= 25;            // Bollinger Bands period PYR
input double deviationPyr= 1.8;           // Standard deviation  PYR // 2.33

input double marginIN = 0.0610;
input double marginOUT = 0.0710;


class Pris   
  {
protected:
   double            sl, tp ;         
   int               m_pMA;                           // MA period
   int               Bands_handle_PYR, Bands_handle, EMAFastMaHandle, EMASlowMaHandle ;           
   double      		Base[], Upper[],  Lower[];     //  BASE_LINE, UPPER_BAND and LOWER_BAND  of iBands
   double      		FastEma[],SlowEma[] ;			// EMA lines
   string            m_smb; ENUM_TIMEFRAMES m_tf ; 
   RiskManagement rm;


public:
	void              Pris();
	void             ~Pris();
	
	 bool      Init(string smb,ENUM_TIMEFRAMES tf); // initialization
	 bool      Main();                              // main function
	 
	 void      OpenPosition(long dir);              // open position on signal
	 void      ClosePosition(long dir) ;
	 long      CheckSignal(long type, bool bEntry);            // check signal
	 long      CheckFilter(long type);  
	 void      Deal(long type, int order,bool pyr); 
	 long      LastClosePrice(int dir);
	 double   GetLastClosePrice();
	
	// to piramiding
	 long      	   CheckSignalPyr(long type, bool bEntry);            // check signal
	 long     	   CheckFilterPyr(long type);  
    long          CheckDistance(long type, bool bEntry);
    double        LastDealOpenPrice();
    
   
  };
//------------------------------------------------------------------	Pris
void Pris::Pris() { }
//------------------------------------------------------------------	~Pris
void Pris::~Pris()
  {
   IndicatorRelease(Bands_handle); // delete indicators
   IndicatorRelease(EMAFastMaHandle); 
   IndicatorRelease(EMASlowMaHandle); 
   IndicatorRelease(Bands_handle_PYR);  
  }
//------------------------------------------------------------------	
//    Init
//------------------------------------------------------------------	
bool Pris::Init(string smb,ENUM_TIMEFRAMES tf)
  {
	 
	 m_smb=smb ; m_tf=tf ; 
	if (!rm.Init(0,m_smb,tf)) return(false);  // initialize object RiskManagement

	      tp=TakeProfit;   sl=-1;

   	//--- creation of the indicator iBands
   	   Bands_handle=iBands(NULL,periodBB,bands_period,bands_shift,deviation,PRICE_CLOSE);
   	   Bands_handle_PYR=iBands(NULL,periodBB,bands_periodPyr,bands_shift,deviationPyr,PRICE_CLOSE);
   	   EMAFastMaHandle=iMA(NULL,periodEMA,InpFastEMA,0,MODE_EMA,PRICE_CLOSE);
   	   EMASlowMaHandle=iMA(NULL,periodEMA,InpSlowEMA,0,MODE_EMA,PRICE_CLOSE);
   		  
	//--- report if there was an error in object creation
	   if(Bands_handle<0 || EMAFastMaHandle < 0 || EMASlowMaHandle < 0 || Bands_handle_PYR <0 )
		 {
		  printf(__FUNCTION__+"The creation of indicator has failed: Runtime error = " + GetLastError());
		  return(-1);
		 }

	   return(true);                         // "trade allowed"
  }
//------------------------------------------------------------------	
//    Mainfunction
//------------------------------------------------------------------	
bool Pris::Main()
  {
 
	   if(!rm.Main()) return(false); // call function of parent class
	   
	   if(Bars(m_smb,m_tf)<=m_pMA) return(false); // if there are insufficient number of bars
  
	   long dir;
	   if (rm.m_account.FreeMargin()<4000) return false;
	   dir=ORDER_TYPE_SELL;  OpenPosition(dir); 
	
	   ClosePosition(dir); 
	   dir=ORDER_TYPE_BUY;  
	    OpenPosition(dir);  
	     
	    ClosePosition(dir);
	   
	   return(true);
  }

//------------------------------------------------------------------	
// Open Position
//------------------------------------------------------------------
  void Pris::OpenPosition(long dir)
  {
// if there is an order, try to pyr
 HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));
 
 
 if( PositionSelect(m_smb) && ( HistoryOrdersTotal()  == MaxNumberOrders)  )
                     {      
                       if(PositionGetInteger(POSITION_TYPE)!= CheckDistance(PositionGetInteger(POSITION_TYPE), true  )) return;              
                            if(PositionGetInteger(POSITION_TYPE)!=CheckSignal(PositionGetInteger(POSITION_TYPE), true)) return; 
                              if(PositionGetInteger(POSITION_TYPE)!=CheckFilter(PositionGetInteger(POSITION_TYPE)))return;
                              printf("                       * Ultima piramidacion *  " );
                              printf(__FUNCTION__+ " Precio recorre la distacia adecuada" );
                              printf(__FUNCTION__+ " Dispersion BB 90 tocada . Deal numero: " + HistoryOrdersTotal() );
                              
                  	   Deal(PositionGetInteger(POSITION_TYPE), HistoryOrdersTotal(),true);                 	   
                        return ;
                     }
                     
                     
  if( PositionSelect(m_smb) && ( HistoryOrdersTotal()  < MaxNumberOrders)  )
                     {                    
                        if(PositionGetInteger(POSITION_TYPE)!= CheckDistance(PositionGetInteger(POSITION_TYPE), true  )) return;
                                
                        if(PositionGetInteger(POSITION_TYPE)!=CheckSignalPyr(PositionGetInteger(POSITION_TYPE), true)) return;
                              printf("                       * piramida *  " );
                              printf(__FUNCTION__+ " Precio recorre la distacia adecuada" );                           
                              printf(__FUNCTION__+ " Dispersion BB 20 tocada . Deal numero: " + HistoryOrdersTotal() );
                              
                  	   Deal(PositionGetInteger(POSITION_TYPE), HistoryOrdersTotal(),true);                 	   
                        return ;
                     }

    if(PositionSelect(m_smb)) return; 
    
         if(dir!=CheckSignal(dir, true)) return;// if there is no signal for current direction
         if(dir!=CheckFilter(dir))return;
          
           if(dir!=rm.marginPerformance(dir, marginIN, true))return; // El Precio no está en un MAX / MIN absoluto  ###
   //  if( LastClosePrice(dir)!=0) 
    //   if (dir!=LastClosePrice(dir))return;    // El Precio no está en un Mayor / Menor que el anterior  ###
            printf(__FUNCTION__+ " ### EMA cruzada  y BB fuera de dispersion ### dir" + dir );      
            Deal(dir, 0,false);
  }
  
  
  

  
  
 //------------------------------------------------------------------	
// Close Position if the price touch the bollinger bands an the volumen is more than PeakVolumen
//------------------------------------------------------------------ 
  void Pris::ClosePosition(long dir)
  {       if( !PositionSelect(m_smb)) return;
          if(dir==rm.marginPerformance(dir, marginOUT, false))
          {  
               printf(__FUNCTION__+ "marginOUT POSITION CERRADA: POSITION_VOLUME: "  + PositionGetDouble(POSITION_VOLUME) +" POSITION_PROFIT: "  + PositionGetDouble(POSITION_PROFIT));
               printf(__FUNCTION__+ "marginOUT POSITION CERRADA: ACCOUNT_BALANCE: "  + AccountInfoDouble(ACCOUNT_BALANCE) +" ACCOUNT_EQUITY: "  + AccountInfoDouble(ACCOUNT_EQUITY));
               rm.m_trade.PositionClose(m_smb,1);
           }
      
         if(dir!=PositionGetInteger(POSITION_TYPE)) return;
         if(dir!=CheckSignal(dir, false)) return;


      if( PositionGetDouble(POSITION_VOLUME) > PeakVolumen) //PositionGetDouble(POSITION_PROFIT)>PositionGetDouble(POSITION_VOLUME)*AccountInfoDouble(ACCOUNT_BALANCE) &&
      {     
         printf(__FUNCTION__+ "POSITION CERRADA: POSITION_VOLUME: "  + PositionGetDouble(POSITION_VOLUME) +" POSITION_PROFIT: "  + PositionGetDouble(POSITION_PROFIT));
         printf(__FUNCTION__+ "POSITION CERRADA: ACCOUNT_BALANCE: "  + AccountInfoDouble(ACCOUNT_BALANCE) +" ACCOUNT_EQUITY: "  + AccountInfoDouble(ACCOUNT_EQUITY));
         rm.m_trade.PositionClose(m_smb,1);
      }
  }

//------------------------------------------------------------------	
// Check Signal
//------------------------------------------------------------------ 
long Pris::CheckSignal(long type, bool bEntry)
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
long Pris::CheckFilter(long type)
{   
   if(!CopyBufferAsSeries(EMAFastMaHandle,0,0,20,true,FastEma)) return(false);
   if(!CopyBufferAsSeries(EMASlowMaHandle,0,0,20,true,SlowEma)) return(false);

  if(type == ORDER_TYPE_BUY && FastEma[0] > SlowEma[0]) // cambiado
   
   {         
 //  printf(__FUNCTION__+ " Ema Cruzada: to buy "  + rm.ea.BasePrice( type) );
    return(ORDER_TYPE_BUY);    }

 else if(type == ORDER_TYPE_SELL && FastEma[0] < SlowEma[0])
    {         
 //    printf(__FUNCTION__+ " Ema Cruzada: to sell "  + rm.ea.BasePrice( type) );
     return(ORDER_TYPE_SELL);   }
   return(WRONG_VALUE);
}
  

//------------------------------------------------------------------	
// Deal
// //Vol = Risk/puntos * 10
//------------------------------------------------------------------ 
void Pris::Deal(long dir, int order,bool pyramiding)     // eliminado ratio, necesidad de dos deal diferentes para pir y para entrada inciial ¿?
{
   double puntos = 0.0 ;
   if (pyramiding == true)           //piramida
   {
     //double lot=rm.getLotN();    
      double lot = order +2 ;
         double totalVolumen   =  (PositionGetDouble(POSITION_VOLUME) + lot ) ; 
  
          puntos =  rm.getStopByRisk(dir, lot);      //calculamos el numero de puntos a apostar
                 if (puntos > 300) puntos = 300;
        
  //   puntos = puntos / order;    Podría recoger algo de beneficio en lugar de apostarlo todo

      printf(__FUNCTION__+ " posicionamos con un stop de  " + puntos  + " puntos. Volumen de deal " +lot+ " Risk : "  +puntos* totalVolumen*10);
            rm.DealOpen(dir,lot,puntos,tp, true);
   }
   
   else
   {
       puntos =  rm.getStopByPercent(dir,Percent);  // el numero de puntos es siempre un 0.8% del precio total del par
       
       double lot=Risk/(puntos*10.0);      
            printf(__FUNCTION__+ " Abrimos posicion con un stop de  " + puntos  + " puntos. Volumen de " +lot+ " Risk de: "  + puntos*lot*10 );
            rm.DealOpen(dir,lot, puntos, tp, false);
    }
 }   
 
 
 
//------------------------------------------------------------------	
// calculate the distance necessary to process a new deal
//------------------------------------------------------------------ 
  long Pris::CheckDistance(long type, bool bEntry)
{   
      double atr,cop,apr;
         atr = rm.getN();                                                            // numero de points que tiene que distanciarse
        // cop = rm.ea.NormalDbl(PositionGetDouble(POSITION_PRICE_OPEN));             // precio de apertura de posicion
         cop = LastDealOpenPrice();
         apr = rm.ea.BasePrice( type);                                             // precio objetivo actual

        if( cop + atr <  rm.ea.BasePrice( type))      
            {  
                 return(bEntry ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
           }
       else if( cop - atr >  rm.ea.BasePrice( type))
          {       
               return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for sell
          }
         return(WRONG_VALUE);
}
//------------------------------------------------------------------	
// Last deal open price to calculate the distance necessary to process a new deal
//------------------------------------------------------------------ 
double Pris::LastDealOpenPrice()
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
  
  
long Pris::LastClosePrice(int dir)
  {
      
      if ( rm.ea.BasePrice(ORDER_TYPE_BUY) <= GetLastClosePrice()  && dir ==ORDER_TYPE_BUY )
       {
        Print(__FUNCTION__ +" El precio "+ rm.ea.BasePrice(ORDER_TYPE_BUY)+" es menor que el anterior  "+ GetLastClosePrice() +" ORDER_TYPE_BUY " );
        return ORDER_TYPE_BUY;
       }
       else if (rm.ea.BasePrice(ORDER_TYPE_BUY) >= GetLastClosePrice() &&  dir ==ORDER_TYPE_BUY)
       {
          
        Print(__FUNCTION__ +" El precio "+ rm.ea.BasePrice(ORDER_TYPE_BUY)+" es mayor que el anterior  "+ GetLastClosePrice() +" ORDER_TYPE_SELL " );
         return ORDER_TYPE_SELL;
       }
       return(WRONG_VALUE);
  }
  
  
//------------------------------------------------------------------	
// Last close price to calculate the distance necessary to process a new deal
//------------------------------------------------------------------ 
  double Pris::GetLastClosePrice() // find price of last Deal OUT of last closed position
{
   uint total=0;
   long ticket;
   string symbol;
   double LCprice=0;

   if(!PositionSelect(_Symbol)) // no open position for symbol
    {
   HistorySelect(0,TimeCurrent());
   total=HistoryDealsTotal();

   for(uint i=1;i <total; i++)
      {
         ticket=HistoryDealGetTicket(i);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         if( symbol==_Symbol && HistoryDealGetInteger(ticket,DEAL_ENTRY)==DEAL_ENTRY_OUT)
            {
               LCprice=HistoryDealGetDouble(ticket,DEAL_PRICE);
            }
      }
    }

return(LCprice);
}

//------------------------------------------------------------------	
// Check Signal
//------------------------------------------------------------------ 
long Pris::CheckSignalPyr(long type, bool bEntry)
  {  
      if(!GetBandsBuffers(Bands_handle_PYR,0,bands_periodPyr,Base,Upper,Lower,true)) return (-1);
           if( rm.ea.BasePrice( ORDER_TYPE_BUY) < Lower[0]   )
               {  
                     return(bEntry ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
               }

          else  if(  rm.ea.BasePrice( ORDER_TYPE_SELL)  > Upper[0])
                   {  
                        return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for buy
                   }

   return(WRONG_VALUE);
  }



    
Pris prisEURUSD; // class instance
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
