//+------------------------------------------------------------------+
//|              Copyright hippie Corp. 							 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

#property copyright "hippie Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"


#include <utilslittle\RiskManagement.mqh>
                                
input int    TakeProfit   = 1000; 		          // Take Profit distance solo se ejecuta si el volumen es menor q PeakVolumen
input int   MaxNumberOrders = 3 ;                // numero de ordenes maxima que pertenece a una posicion
input int    Risk    = 650;
input int    RiskP    = 1000;

input double marginIN = 0.011;
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
	 
	 void       OpenPosition(long dir);              // open position on signal
	 void        ClosePosition(long dir) ;
	 void       PyrPosition() ;
	 long        CheckSignal(long type, bool bEntry);            // check signal
	 long        CheckFilter(long type);  
	 void       Deal(long type, int order,bool pyr); 
	 long        LastClosePrice(int dir);

	
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
	  printf(__FUNCTION__+ " ### start ### "  );
	 m_smb=smb ; m_tf=tf ; 
	if (!rm.Init(0,m_smb,tf)) return(false);  // initialize object RiskManagement

	      tp=TakeProfit;   sl=-1;

   	//--- creation of the indicator iBands
   	   Bands_handle=iBands(_Symbol,periodBB,bands_period,bands_shift,deviation,PRICE_CLOSE);
   	   Bands_handle_PYR=iBands(_Symbol,periodBB,bands_periodPyr,bands_shift,deviationPyr,PRICE_CLOSE);
   	   EMAFastMaHandle=iMA(_Symbol,periodEMA,InpFastEMA,0,MODE_EMA,PRICE_CLOSE);
   	   EMASlowMaHandle=iMA(_Symbol,periodEMA,InpSlowEMA,0,MODE_EMA,PRICE_CLOSE);
   		  
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
	 
	 if(!PositionSelect(m_smb)) 
	 {
	   dir=ORDER_TYPE_SELL; 
	                        OpenPosition(dir); 
	       dir=ORDER_TYPE_BUY;  
	                          OpenPosition(dir); 
     }
     else 
         {
          PyrPosition(); 


         
          ClosePosition(PositionGetInteger(POSITION_TYPE)); 
           
         }
	   return(true);
  }

//------------------------------------------------------------------	
// Open Position
//------------------------------------------------------------------
  void Pris::OpenPosition(long dir)
  {

             if(dir!=CheckSignal(dir, true)) return;// if there is no signal for current direction
               if(dir!=CheckFilter(dir))return;
                  if(dir!=rm.marginPerformance(dir, marginIN, true))return; // El Precio no está en un MAX / MIN absoluto  ###
    
                printf(__FUNCTION__+ " ### EMA cruzada  y BB fuera de dispersion ### "  );      
 
                  Deal(dir, 0,false);
  }
 
 //------------------------------------------------------------------	
// Open Position
//------------------------------------------------------------------
  void Pris::PyrPosition()
  { 
  // if there is an order, try to pyr
 HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));   
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
  }

  
  
 //------------------------------------------------------------------	
// Close Position if the price touch the bollinger bands an the volumen is more than PeakVolumen
//------------------------------------------------------------------ 
  void Pris::ClosePosition(long dir)
  {       
    if( HistoryOrdersTotal()  < 2) return;
    

      if(dir!=CheckSignal(dir, false)) return;

         printf(__FUNCTION__+ "POSITION CERRADA: POSITION_VOLUME: "  + PositionGetDouble(POSITION_VOLUME) +" POSITION_PROFIT: "  + PositionGetDouble(POSITION_PROFIT));
         printf(__FUNCTION__+ "POSITION CERRADA: ACCOUNT_BALANCE: "  + AccountInfoDouble(ACCOUNT_BALANCE) +" ACCOUNT_EQUITY: "  + AccountInfoDouble(ACCOUNT_EQUITY));
         rm.m_trade.PositionClose(m_smb,1);
      
                    
   
  }

//------------------------------------------------------------------	
// Check Signal
//------------------------------------------------------------------ 
long Pris::CheckSignal(long dir, bool bEntry)
  {  
      if(!GetBandsBuffers(Bands_handle,0,90,Base,Upper,Lower,true)) return (-1);          
          if( rm.ea.BasePrice( dir) < Lower[0]   )
               {  

                 // printf(__FUNCTION__+ " Dispersion negativa tocada x S    ORDER_TYPE_BUY  Lower: " + NormalizeDouble(Lower[0],5)  + " Ask: " +NormalizeDouble(rm.ea.BasePrice(dir),5));
                     return(bEntry ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
               }
          else  if(  rm.ea.BasePrice( dir)  > Upper[0])
                   {  
                //   printf(__FUNCTION__+ " Dispersion Positivatocada x S    ORDER_TYPE_SELL      Upper: " +  NormalizeDouble(Upper[0],5)+ " Bid: "  + NormalizeDouble(rm.ea.BasePrice(dir),5) );
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
 // printf(__FUNCTION__+ " Ema Cruzada: to buy "  + rm.ea.BasePrice( type) );
    return(ORDER_TYPE_BUY);    }

 else if(type == ORDER_TYPE_SELL && FastEma[0] < SlowEma[0])
    {         
  //  printf(__FUNCTION__+ " Ema Cruzada: to sell "  + NormalizeDouble(rm.ea.BasePrice( type),5) );
     return(ORDER_TYPE_SELL);   }
   return(WRONG_VALUE);
}
  

//------------------------------------------------------------------	
//------------------------------------------------------------------ 
void Pris::Deal(long dir, int order,bool pyramiding)     // eliminado ratio, necesidad de dos deal diferentes para pir y para entrada inciial ¿?
{
   if (pyramiding == true)           //piramida
   {
            double pips= rm.getPips();
             pips = pips * 10 * 1.5 ; // pongo un stop de 3/2 del ATR
             double lot =(RiskP + PositionGetDouble(POSITION_PROFIT)) /pips;
             lot = lot - PositionGetDouble(POSITION_VOLUME);
             
             double totalVolumen   =  (PositionGetDouble(POSITION_VOLUME) + lot ) ;           
             printf(__FUNCTION__+ " Posicionamos con un stop de  " + pips/10  + " pips. Volumen de deal " +lot+ " totalVolumen : "+totalVolumen+" Risk : "  + (Risk + PositionGetDouble(POSITION_PROFIT)));
               
                  rm.DealOpen(dir,lot,pips/10,tp);
   }
   
   else
   {
          
            double pips= rm.getPips();
            pips = pips * 10 * 0.666; // ponemos el stop de 1/2 del ATR
            double lot = Risk /pips ;
            printf(__FUNCTION__+ " Abrimos posicion con un stop de  " +pips/10  + " pips. Volumen de " +lot+ " Risk de: "  + pips* lot);
            rm.DealOpen(dir,lot, pips/10, tp);
            
    }
 }   
 
 
 
//------------------------------------------------------------------	
// calculate the distance necessary to process a new deal
//------------------------------------------------------------------ 
  long Pris::CheckDistance(long dir, bool bEntry)
{   
      double atr,cop,apr;
         atr = rm.getN();                                                            // numero de points que tiene que distanciarse
        // cop = rm.ea.NormalDbl(PositionGetDouble(POSITION_PRICE_OPEN));             // precio de apertura de posicion
         cop = LastDealOpenPrice();
         apr = rm.ea.BasePrice( dir);                                             // precio objetivo actual


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
  
  

//------------------------------------------------------------------	
// Check Signal
//------------------------------------------------------------------ 
long Pris::CheckSignalPyr(long dir, bool bEntry)
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
