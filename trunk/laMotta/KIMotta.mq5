//+------------------------------------------------------------------+
//|              Copyright hippie Corp. 							 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

#property copyright "hippie Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"


#include <MIAMotta\RiskManagement.mqh>
                                
input int    TakeProfit   = 1500; 		          // Take Profit distance solo se ejecuta si el volumen es menor q PeakVolumen
               
input int bands_period     = 90;             // Bollinger Bands period
input double deviation     = 2.33;          // Standard deviation  // 2.33

input int InpFastEMA       = 12;              // InpFastEMA Pris
input int InpSlowEMA       = 25 ;            // InpSlowEMA Pris
input int  InpSlowestEMA   = 850;            // InpSlowestEMA Pris
   
input ENUM_TIMEFRAMES periodEMA = PERIOD_H1;
input ENUM_TIMEFRAMES periodBB = PERIOD_H1;

//---indicator parameters pyr 
input int bands_periodPyr= 25;            // Bollinger Bands period PYR

//---indicator parameters pyr 
input int bands_periodThirdPyr= 60;            // Bollinger Bands period PYR

// risk management
input double volP = 15; // volatilidad que arriesgamos en la entrada
input double vol = 6; 
input int MaxNOrders = 3;

input int n = 15;


class Pris   
  {
protected:
   double            sl, tp ;         
   int               m_pMA;                           // MA period
   int               Bands_handle_thirdPYR, Bands_handle_PYR, Bands_handle, EMAFastMaHandle, EMASlowMaHandle , EMASlowestMaHandle;           
   double      		FastEma[],SlowEma[] , SlowestEma[];			// EMA lines
   string            m_smb; ENUM_TIMEFRAMES m_tf ; 
   RiskManagement rm;
   bool            IAB,IAS;
   double      		Base[], Upper[],  Lower[];     //  BASE_LINE, UPPER_BAND and LOWER_BAND  of iBands
   int               MaxNumberOrders  ; 
public:
	void              Pris();
	void             ~Pris();
	
	 bool      Init(string smb,ENUM_TIMEFRAMES tf); // initialization
	 bool      Main();                              // main function
	 
	void      OpenPosition(long dir);              // open position on signal
	void      ClosePosition(long dir) ;
	void      PyrPosition() ;
	long      CheckSignal(long type, bool bEntry);            // check signal
	long      CheckFilter(long type);  
	bool      setIA(long dir);
	void      Deal(long type, int order,bool pyr); 
	long      LastClosePrice(int dir);
   long      CheckSignalClose(long dir, bool bEntry);
   bool      getMaxNumerOrders(long dir);
	
	// to piramiding
	 long      	   CheckSignalPyr(long type, bool bEntry);            // check signal
	 long          CheckSignalThirdPyr(long dir, bool bEntry);
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
   IndicatorRelease(Bands_handle_thirdPYR);  
   
  }
//------------------------------------------------------------------	
//    Init
//------------------------------------------------------------------	
bool Pris::Init(string smb,ENUM_TIMEFRAMES tf)
  {
	  printf(__FUNCTION__+ " ### start ### "  );
	 m_smb=smb ; m_tf=tf ; 
	if (!rm.Init(0,m_smb,tf)) return(false);  // initialize object RiskManagement

	tp=TakeProfit;   sl=-1; IAB = false ; IAS=false;
	MaxNumberOrders = 0;
    m_pMA = bands_period;
   	//--- creation of the indicator iBands
	Bands_handle=iBands(_Symbol,periodBB,bands_period,0,deviation,PRICE_CLOSE);
	Bands_handle_PYR=iBands(_Symbol,periodBB,bands_periodPyr,0,deviation,PRICE_CLOSE);
	Bands_handle_thirdPYR=iBands(_Symbol,periodBB,bands_periodThirdPyr,0,deviation,PRICE_CLOSE);
   	
	EMAFastMaHandle=iMA(_Symbol,periodEMA,InpFastEMA,0,MODE_SMMA,PRICE_CLOSE);
	EMASlowMaHandle=iMA(_Symbol,periodEMA,InpSlowEMA,0,MODE_SMMA,PRICE_CLOSE);
	EMASlowestMaHandle=iMA(_Symbol,periodEMA,InpSlowestEMA,0,MODE_SMMA,PRICE_CLOSE);
   		  
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
	   if (rm.m_account.FreeMargin()<1000) return false;
	 
	 if (!IAS) setIA(ORDER_TYPE_SELL);
	 if (!IAB) setIA(ORDER_TYPE_BUY);
	 
	 if(!PositionSelect(m_smb)) 
	 {
	 
	 if (IAS) 
	   {
	   dir=ORDER_TYPE_SELL; 
	   OpenPosition(dir); 
	    }
	    else if (IAB)
	   {
	       dir=ORDER_TYPE_BUY;  
	       OpenPosition(dir); 
	     }
     }
     else 
         {
         if(PositionGetInteger(POSITION_TYPE)!= CheckDistance(PositionGetInteger(POSITION_TYPE), true  )) return false;
        
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
                 if(dir!=CheckFilter(dir)) return;// if there is no signal for current direction     
                printf(__FUNCTION__+ " ### EMA cruzada   ### "  );      
                  Deal(dir, 0,false);
                  IAB=false; IAS =false;
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
                        if(PositionGetInteger(POSITION_TYPE)!=CheckSignalPyr(PositionGetInteger(POSITION_TYPE), true)) return;
                            if( (HistoryOrdersTotal()+1  == MaxNumberOrders) && PositionGetInteger(POSITION_TYPE)!=CheckSignalThirdPyr(PositionGetInteger(POSITION_TYPE), true)) return;
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
    if( HistoryOrdersTotal()  < MaxNumberOrders) return;
      if(dir!=CheckSignalClose(dir, false)) return;

         printf(__FUNCTION__+ "MaxNumberOrders " +MaxNumberOrders+ "POSITION CERRADA: POSITION_VOLUME: "  + PositionGetDouble(POSITION_VOLUME) +" POSITION_PROFIT: "  + PositionGetDouble(POSITION_PROFIT));
         printf(__FUNCTION__+ "HistoryOrdersTotal " +HistoryOrdersTotal()+ "POSITION CERRADA: ACCOUNT_BALANCE: "  + AccountInfoDouble(ACCOUNT_BALANCE) +" ACCOUNT_EQUITY: "  + AccountInfoDouble(ACCOUNT_EQUITY));
         rm.m_trade.PositionClose(m_smb,1);
  }


bool Pris::setIA(long dir)
   {  
   if(!GetBandsBuffers(Bands_handle,0,bands_period,Base,Upper,Lower,true)) return (-1);          
          if( rm.ea.BasePrice( dir) < Lower[0] && dir ==  ORDER_TYPE_BUY )
               {  
                  IAB = true;
                   printf(__FUNCTION__+ " Dispersion negativa tocada, listo para comprar" );
               }
          else  if(  rm.ea.BasePrice( dir)  > Upper[0] && dir ==  ORDER_TYPE_SELL )
                   {  
                   IAS = true;
                    printf(__FUNCTION__+ " Dispersion positiva tocada, listo para comprar" );
                   }
   return(WRONG_VALUE);  
   }


//------------------------------------------------------------------	
// Check Signal
//------------------------------------------------------------------ 
long Pris::CheckSignal(long dir, bool bEntry)
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
 
long Pris::CheckSignalClose(long dir, bool bEntry)
  {  
      if(!GetBandsBuffers(Bands_handle,0,bands_period,Base,Upper,Lower,true)) return (-1);          
          if( rm.ea.BasePrice( dir) < Lower[0]   )
               {  

                 printf(__FUNCTION__+ " Dispersion negativa tocada x S    ORDER_TYPE_BUY  Lower: " + NormalizeDouble(Lower[0],5)  + " Ask: " +NormalizeDouble(rm.ea.BasePrice(dir),5));
                     return(bEntry ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
               }
          else  if(  rm.ea.BasePrice( dir)  > Upper[0])
                   {  
                   printf(__FUNCTION__+ " Dispersion Positivatocada x S    ORDER_TYPE_SELL      Upper: " +  NormalizeDouble(Upper[0],5)+ " Bid: "  + NormalizeDouble(rm.ea.BasePrice(dir),5) );
                        return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for buy
                   }
   return(WRONG_VALUE);
  }
  
  
//------------------------------------------------------------------	
// Check Filter
//------------------------------------------------------------------ 
long Pris::CheckFilter(long dir)
{   
   if(!CopyBufferAsSeries(EMAFastMaHandle,0,0,InpFastEMA,true,FastEma)) return(false);
   if(!CopyBufferAsSeries(EMASlowMaHandle,0,0,InpSlowEMA,true,SlowEma)) return(false);

  if(dir == ORDER_TYPE_BUY && FastEma[0] > SlowEma[0]) // cambiado
   
   {         
 // printf(__FUNCTION__+ " Ema Cruzada: to buy "  + rm.ea.BasePrice( type) );
    return(ORDER_TYPE_BUY);    }

 else if(dir == ORDER_TYPE_SELL && FastEma[0] < SlowEma[0])
    {         
  //  printf(__FUNCTION__+ " Ema Cruzada: to sell "  + NormalizeDouble(rm.ea.BasePrice( type),5) );
     return(ORDER_TYPE_SELL);   }
   return(WRONG_VALUE);
}
  

//------------------------------------------------------------------	
//------------------------------------------------------------------ 
void Pris::Deal(long dir, int order,bool pyramiding)     // eliminado ratio, necesidad de dos deal diferentes para pir y para entrada inciial ¿?
{
 
 
      double risky = rm.kelly(n);
      double Risk = rm.m_account.FreeMargin()*risky;
      
   if (pyramiding == true)           //piramida
   {
         double riesgo = -1;
         double pips= rm.getPips();
         pips = pips * volP ; // pongo un stop de 3/2 del ATR   
        
         if (order ==1)  //primera piramidacion
         {
         riesgo=Risk*3;
         tp=pips;
         }
         
         else if  (order==2)
         {
         riesgo=Risk;
         tp=pips/3;
         }
         
         
         double lot =(riesgo + PositionGetDouble(POSITION_PROFIT)) /pips;
         printf(__FUNCTION__+" order: " + order +   " riesgo:  " + riesgo  + " pips " +pips+ " POSITION_PROFIT " + PositionGetDouble(POSITION_PROFIT));
         lot = lot - PositionGetDouble(POSITION_VOLUME);
        
         if ( (lot +PositionGetDouble(POSITION_VOLUME))  > 15.0 )  lot = 14.9 -  PositionGetDouble(POSITION_VOLUME);
         if ( lot   > 5.0 )    lot = lot = 5.0;
  
         printf(__FUNCTION__+ " Posicionamos con un stop de  " + pips/10  + " pips. Volumen de deal " +lot+ " totalVolumen : "+PositionGetDouble(POSITION_VOLUME) + lot+" Risk : "  + pips* (PositionGetDouble(POSITION_VOLUME) + lot) );
         rm.DealOpen(dir,lot,pips/10,tp);
   }
   
   else
   {    
   
          if ( !getMaxNumerOrders(dir)) return;
            double pips=   rm.getPips();
            pips = pips * vol; // ponemos el stop de 1/4 del ATR
            double lot = Risk /pips ;
            
              if ( lot   > 5.0 )
                      lot = lot = 5.0;
                                  
            printf(__FUNCTION__+ " Abrimos posicion con un stop de  " +pips/10  + " pips. Volumen de " +lot+ " Risk de: "  + pips* lot);
            rm.DealOpen(dir,lot, pips/10, tp);
            
    }
 }   
 
 
 bool Pris::getMaxNumerOrders(long dir) 
 {
 
 if(!CopyBufferAsSeries(EMASlowestMaHandle,0,0,InpSlowestEMA,true,SlowestEma)) return(false);

 if(dir == ORDER_TYPE_BUY && rm.ea.BasePrice(dir)  > SlowestEma[0]) // cambiado
   
   {         
     printf(__FUNCTION__+ " ORDER_TYPE_buy  MaxNumberOrders = 1 "   );
     MaxNumberOrders  = 1;
	 return(true);
  }
   else if(dir == ORDER_TYPE_BUY && rm.ea.BasePrice(dir)  < SlowestEma[0]) // cambiado
   
   {         
     printf(__FUNCTION__+ "  ORDER_TYPE_BUY MaxNumberOrders = 3 "   );
     MaxNumberOrders  =  MaxNOrders;
	 return(true);
   }


 else if(dir == ORDER_TYPE_SELL && rm.ea.BasePrice(dir) < SlowestEma[0])
    {         
       printf(__FUNCTION__+ " ORDER_TYPE_SELL MaxNumberOrders   =1 "  + NormalizeDouble(rm.ea.BasePrice( dir),5) );
      MaxNumberOrders   =1;
	  return(true);
      } 
   else  if(dir == ORDER_TYPE_SELL && rm.ea.BasePrice(dir) > SlowestEma[0])
    {         
       printf(__FUNCTION__+ " ORDER_TYPE_SELL MaxNumberOrders   =3 "  + NormalizeDouble(rm.ea.BasePrice( dir),5) );
       MaxNumberOrders   = MaxNOrders;
	   return(true);
   } 
    return(true);
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
  
  
  //------------------------------------------------------------------	
// Check Signal
//------------------------------------------------------------------ 
long Pris::CheckSignalThirdPyr(long dir, bool bEntry)
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
