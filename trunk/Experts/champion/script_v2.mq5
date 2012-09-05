/*

Cambiar la piramidacion x el rsi o cualquier señal de alta frecuencia y subi el numero d piramidaciones
hay que cambiar el tipo de entrada meter

BB + filtro ... es decir igual que HAL !!!!!!!!!!!!		¿?¿?

*/
#include <Trade\Trade.mqh>    
                                
input int InpFastEMA       = 12;              	// InpFastEMA script
input int InpSlowEMA       = 25 ;            	// InpSlowEMA script
input int  InpSlowestEMA   = 850;            	// InpSlowestEMA script     
input int bands_period     = 90;            	// Bollinger Bands period
input double deviation     =2;              	// Standard deviation  

//---indicator parameters pyr 
   
input ENUM_TIMEFRAMES TFATR = PERIOD_D1;
input ENUM_TIMEFRAMES period = PERIOD_H1;
input int ATRPeriod  = 14 ;

// risk management
input double volP = 10; // volatilidad que arriesgamos en la entrada
input double vol = 5; 
input int MaxNOrders = 3;



class script   
  {
protected:
     
   int             Bands_handle, EMAFastMaHandle, EMASlowMaHandle , EMASlowestMaHandle,RSIHandle,ExtATRHandle;           
   double         	RSI[], Upper[],  Lower[], FastEma[],SlowEma[] , SlowestEma[],ATR[];   
   string         	m_smb; ENUM_TIMEFRAMES m_tf ; 
   int            	MaxNumberOrders  ; 
   double         	m_pnt;         // consider 5/3 digit quotes for stops
   CTrade 			trade;  
   CSymbolInfo      m_symbol;      
   
public:
  void        script();
//void       ~script();
  
	bool      Init(string smb,ENUM_TIMEFRAMES tf); // initialization
	bool      Main();                              // main function
	void      OpenPosition(long dir);              // open position on signal
	void      ClosePosition(long dir) ;
	long      CheckSignal(long type);            // check signal
	long      CheckFilter(long type);  
	long      CheckSignalClose(long dir, bool bEntry);
  
	// to piramiding
	void      PyrPosition() ;
	long      CheckSignalToPyr(long type);            // check signal
	long      CheckDistance(long type, bool bEntry);
    double    LastDealOpenPrice();
    bool      getMaxNumerOrders(long dir,bool pyr);

	// money management
	double 	getNVince();
	bool    Deal(long type, bool pyr); 
	ulong 	DealOpen(long dir,double lot,double SL,double TP);
   
    // aux functions
   bool   CopyBufferAsSeries (int handle, int bufer, int start,  int number,  bool asSeries,  double &M[]); 
   double BasePrice(long dir);
   double ReversPrice(long dir);
   double NormalTP(int dir,double op,double pr,int TP,double stop);
   double NormalSL(int dir,double op,double pr,double SL,double stop);
   double NormalLot(double lot);
   double NormalPrice(double d);
   double NormalDbl(double d,int n=-1) ;

  };
//------------------------------------------------------------------?  script
void script::script() { }
//------------------------------------------------------------------?  ~script
/*
void script::~script()
  {
   IndicatorRelease(Bands_handle); // delete indicators
   IndicatorRelease(EMAFastMaHandle); 
   IndicatorRelease(EMASlowMaHandle); 
   IndicatorRelease(Bands_handle_PYR);  
  }
  */

//------------------------------------------------------------------    
//------------------------------------------------------------------  
// funciones gestion de ordenes
//------------------------------------------------------------------
//------------------------------------------------------------------
bool script::Init(string smb,ENUM_TIMEFRAMES tf)
  {
    printf(__FUNCTION__+ " ### start ### "  );
   m_smb=smb ; m_tf=tf ; 

   MaxNumberOrders = 0;
   m_symbol.Name(smb);
   m_pnt=m_symbol.Point();  

  Bands_handle=iBands(m_smb,period,bands_period,0,deviation,PRICE_CLOSE);
  RSIHandle = iRSI(m_smb,period,ATRPeriod,PRICE_CLOSE);
  ExtATRHandle = iATR(m_smb,TFATR,ATRPeriod);
  EMAFastMaHandle=iMA(m_smb,period,InpFastEMA,0,MODE_SMMA,PRICE_CLOSE);
  EMASlowMaHandle=iMA(m_smb,period,InpSlowEMA,0,MODE_SMMA,PRICE_CLOSE);
  EMASlowestMaHandle=iMA(m_smb,period,InpSlowestEMA,0,MODE_SMA,PRICE_CLOSE);

     if(Bands_handle<0 || EMAFastMaHandle < 0 || EMASlowMaHandle < 0 || RSIHandle <0 || EMASlowestMaHandle < 0 || ExtATRHandle <0)
     {
      printf(__FUNCTION__+"The creation of indicator has failed: Runtime error = " + GetLastError());
      return(-1);
     }
     return(true); 
  }
  
  
bool script::Main()
  {

     if(Bars(m_smb,m_tf)<=100) return(false); // if there are insufficient number of bars
     if (AccountInfoDouble(ACCOUNT_FREEMARGIN)<2000) return false;
  
   if(!PositionSelect(m_smb)) 
   {
         OpenPosition(ORDER_TYPE_BUY); 
         OpenPosition(ORDER_TYPE_SELL); 
   }
     else 
         {
      if(PositionGetInteger(POSITION_TYPE)!= CheckDistance(PositionGetInteger(POSITION_TYPE), true  )) return false;
			HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));   
        if(  HistoryOrdersTotal()  < MaxNumberOrders  )
			{
            PyrPosition(); 
			}
         else
         {
			ClosePosition(PositionGetInteger(POSITION_TYPE));
         }
    }
     return(true);
  }


  void script::OpenPosition(long dir)
  {
       if(dir!=CheckSignal(dir)) return;// if there is no signal for current direction
                 printf(__FUNCTION__+ " ### EMA cruzada   ### "  );      
                  Deal(dir, false);
   }
   

  void script::ClosePosition(long dir)
  {       
      if(dir!=CheckSignalClose(dir, false)) return;       
         printf(__FUNCTION__+ "MaxNumberOrders " +MaxNumberOrders+ "POSITION CERRADA: POSITION_VOLUME: "  + PositionGetDouble(POSITION_VOLUME) +" POSITION_PROFIT: "  + PositionGetDouble(POSITION_PROFIT));
         printf(__FUNCTION__+ "HistoryOrdersTotal " +HistoryOrdersTotal()+ "POSITION CERRADA: ACCOUNT_BALANCE: "  + AccountInfoDouble(ACCOUNT_BALANCE) +" ACCOUNT_EQUITY: "  + AccountInfoDouble(ACCOUNT_EQUITY));
         trade.PositionClose(m_smb,1);
  }
  


long script::CheckSignal(long dir)
  {  
 if(!CopyBufferAsSeries(EMAFastMaHandle,0,2,InpFastEMA,true,FastEma)) return(false);
 if(!CopyBufferAsSeries(EMASlowMaHandle,0,2,InpSlowEMA,true,SlowEma)) return(false);
     

  if(dir == ORDER_TYPE_BUY && FastEma[0] > SlowEma[0] && FastEma[1] < SlowEma[1]) // cambiado
   
   {         
   printf(__FUNCTION__+ " Ema Cruzada: to buy "  +  NormalizeDouble(BasePrice( dir),5) );
    return(ORDER_TYPE_BUY);    }

 else if(dir == ORDER_TYPE_SELL && FastEma[0] < SlowEma[0] &&  FastEma[1] > SlowEma[1])
    {         
     printf(__FUNCTION__+ " Ema Cruzada: to sell "  + NormalizeDouble(BasePrice( dir),5) );
     return(ORDER_TYPE_SELL);   }
   return(WRONG_VALUE);
  }


long script::CheckSignalClose(long dir, bool bEntry)
  {  
      
       if(!CopyBufferAsSeries(Bands_handle,1,0,0,true,Upper)) return(false);
       if(!CopyBufferAsSeries(Bands_handle,2,0,0,true,Lower)) return(false);
              
          if( dir == ORDER_TYPE_BUY && BasePrice( dir) < Lower[0]  && BasePrice( dir) < Lower[1] )
               {  
					 printf(__FUNCTION__+ " S out dispersion:  dispersion :" + NormalizeDouble(Lower[0],5)  + " S: " +NormalizeDouble(BasePrice(dir),5));
                     return(bEntry  ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
               }
          else  if( dir == ORDER_TYPE_SELL  &&  BasePrice( dir)  > Upper[0] && BasePrice( dir) < Upper[1]  )
                   {  
						 printf(__FUNCTION__+ " S out dispersion:  dispersion :" + NormalizeDouble(Lower[0],5)  + " S: " +NormalizeDouble(BasePrice(dir),5));
                        return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);
                   }
   return(WRONG_VALUE);
  }
  
//------------------------------------------------------------------    
//------------------------------------------------------------------  
// funciones piramidacion
//------------------------------------------------------------------
//------------------------------------------------------------------  

  void script::PyrPosition()
  {                                                                  
                        if(PositionGetInteger(POSITION_TYPE)!=CheckSignalToPyr(PositionGetInteger(POSITION_TYPE))) return;
                               printf("  * piramida *  " );
                         Deal(PositionGetInteger(POSITION_TYPE), true);                      
                        return ;
  }


long script::CheckSignalToPyr(long dir)
  {  
        if(!CopyBufferAsSeries(RSIHandle,0,0,2,true,RSI))return(WRONG_VALUE);

           if(dir == ORDER_TYPE_SELL &&   RSI[0] > 51  )
               {  
                     printf(__FUNCTION__+ "  RSI[0]: " +  RSI[0]  );
                     return(ORDER_TYPE_SELL);
               }

          else  if( dir == ORDER_TYPE_BUY &&  RSI[0] < 49 )
                   {  
                        printf(__FUNCTION__+ "  RSI[0]: " +  RSI[0]  );
                        return(ORDER_TYPE_BUY);
                   }

   return(WRONG_VALUE);
  }
  
  
 bool script::getMaxNumerOrders(long dir, bool pyr) //calclula el número de ordenees para piramidar
 {
 if(!CopyBufferAsSeries(EMASlowestMaHandle,0,0,InpSlowestEMA,true,SlowestEma)) return(false);

 if(dir == ORDER_TYPE_BUY && BasePrice(dir)  > SlowestEma[0]) 
   
   {         
     printf(__FUNCTION__+ " ORDER_TYPE_buy  MaxNumberOrders = 1 "   );
     MaxNumberOrders  = 1;
   return(true);
  }
   else if(dir == ORDER_TYPE_BUY && BasePrice(dir)  < SlowestEma[0]) 
   
   {         
     printf(__FUNCTION__+ "  ORDER_TYPE_BUY MaxNumberOrders =  " + MaxNOrders   );
     MaxNumberOrders  =  MaxNOrders;
   return(true);
   }

 else if(dir == ORDER_TYPE_SELL && BasePrice(dir) < SlowestEma[0])
    {         
       printf(__FUNCTION__+ " ORDER_TYPE_SELL MaxNumberOrders   =1 "   );
      MaxNumberOrders   =1;
    return(true);
      } 
   else  if(dir == ORDER_TYPE_SELL && BasePrice(dir) > SlowestEma[0])
    {         
       printf(__FUNCTION__+ " ORDER_TYPE_SELL MaxNumberOrders   = "  + MaxNOrders );
       MaxNumberOrders   = MaxNOrders;
     return(true);
   } 
    return(true);
 }
 

  long script::CheckDistance(long dir, bool bEntry)  //calculate the distance necessary to process a new deal
{   
    double atr,cop,apr;
     if(!CopyBufferAsSeries(ExtATRHandle,0,0,14,true,ATR)) return(-1);
       atr = ATR[0];    
                               
         cop = LastDealOpenPrice();            // precio del último deal
         apr = BasePrice(dir);                  // precio objetivo actual

        if( dir == ORDER_TYPE_BUY && (cop + atr) <  BasePrice( dir))      
            {  
                // printf(__FUNCTION__+ " LastDealOpenPrice  " +cop  + " atr: " +atr+ " BasePrice: "  + NormalizeDouble( BasePrice( dir),4));
                 return(bEntry  ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
           }
       else if(dir == ORDER_TYPE_SELL &&  (cop - atr) >  BasePrice( dir))
          {       
              // printf(__FUNCTION__+ " LastDealOpenPrice  " +cop  + " atr: -" +atr+ " BasePrice: "  + NormalizeDouble(BasePrice( dir),4));
               return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for sell
          }
         return(WRONG_VALUE);
}

double script::LastDealOpenPrice() //Last deal open price to calculate the distance necessary to process a new deal
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
//------------------------------------------------------------------  
//gestion de ordenes y money management
//------------------------------------------------------------------
//------------------------------------------------------------------ 
bool script::Deal(long dir, bool pyramiding) 
{

   if(!CopyBufferAsSeries(ExtATRHandle,0,0,14,true,ATR)) return(-1);
    double pips = ATR[0]*10000;              //pips 

    if (pyramiding == true)           //piramida
   {
    pips = pips * volP ; // pongo un stop de 3/2 del ATR

    double lot = getNVince()*2;  
    if ( (lot +PositionGetDouble(POSITION_VOLUME))  > 15.0 )
            lot = 14.99 -  PositionGetDouble(POSITION_VOLUME);
          
    double lot2 = lot/2;
    lot = lot/2; 
      
    if ( lot   > 5.0 )  lot = 5.0;   
    DealOpen(dir,lot,pips*2,pips*4);
    return true;
   }
   
   else
   {    
          if ( !getMaxNumerOrders(dir,false)) return false;

            pips = pips * vol; 
            double lot =  getNVince();
            
              if ( lot   > 5.0 )
                      lot = lot = 5.0;
                      
            printf(__FUNCTION__+ " Abrimos posicion con un stop de  " +pips  + " pips. y lot de "  + lot  );
            DealOpen(dir,lot, pips*2, pips*6);
       return true;
    }
   return false;
 }   


 ulong script::DealOpen(long dir,double lot,double SL,double TP)
  {
       if(lot<=0) return -1;
         double op, tp,apr,StopLvl, sl;
       
         m_symbol.RefreshRates(); m_symbol.Refresh();
         StopLvl=m_symbol.StopsLevel()*m_symbol.Point(); // remember stop level
         apr=ReversPrice(dir); 
         op=BasePrice(dir);        // open price
         tp=NormalTP(dir, op, apr, TP, StopLvl);         // Take Profit
         
         sl =  NormalSL(dir, op, apr, SL, StopLvl) ;  //pasamos los puntos a stop
       //  printf(__FUNCTION__+" open price: " + op + " reverse price: " + apr + " sl: " + sl + " SL: " +  SL); 
          
          trade.PositionOpen(m_smb,(ENUM_ORDER_TYPE)dir,NormalLot(lot),op,sl,tp);
      
         ulong order=trade.ResultOrder(); if(order<=0) return(-6); // order ticket
         return(order);                  // return deal ticket
  }

double script::getNVince()
{
	long Equity = AccountInfoDouble(ACCOUNT_FREEMARGIN);;
	long DeltaNeutro = 2500;		// 5000/2 (quitamos parametros de entrada)
	long value = 1 + 8*(Equity/DeltaNeutro );
	long valuesqrt = sqrt(value);
	long N = 1 + ( valuesqrt / 2);
	Print(__FUNCTION__+" El Equity "+ Equity+"  DeltaNeutro: " +DeltaNeutro+ " N: " + N + " value" + value  + " valuesqrt "  + valuesqrt );
 
 return N;
}


//------------------------------------------------------------------    
//------------------------------------------------------------------  
// AUX FUNCTIONS
//------------------------------------------------------------------
//------------------------------------------------------------------
   
 /*  
 handle, buffer number, start from, number of elements to copy, is as series, target array for data
 */                
bool script::CopyBufferAsSeries( int handle, int bufer, int start, int number,  bool asSeries,  double &M[] )
  {
   if(CopyBuffer(handle,bufer,start,number,M)<=0) return(false);
   ArraySetAsSeries(M,asSeries);
   return(true);
  }
  
   //---------------------------------------------------------------   BP 
   double script:: BasePrice(long dir)
  {
   m_symbol.Refresh();
   m_symbol.RefreshRates();
   
   if(dir==(long)ORDER_TYPE_BUY) return(NormalizeDouble(m_symbol.Ask(),5));
   if(dir==(long)ORDER_TYPE_SELL) return(NormalizeDouble(m_symbol.Bid(),5));
   return(WRONG_VALUE);
  }
  //---------------------------------------------------------------   RP
double script::ReversPrice(long dir)
  {
   if(dir==(long)ORDER_TYPE_BUY) return(m_symbol.Bid());
   if(dir==(long)ORDER_TYPE_SELL) return(m_symbol.Ask());
   return(WRONG_VALUE);
  }
  //---------------------------------------------------------------   NTP
double script::NormalTP(int dir,double op,double pr,int TP,double stop)
  {
   if(TP==0) return(NormalPrice(0));
   if(dir==ORDER_TYPE_BUY || dir==ORDER_TYPE_BUY_STOP || dir==ORDER_TYPE_BUY_LIMIT) return(NormalPrice(MathMax(op+TP*m_pnt,pr+stop)));
   if(dir==ORDER_TYPE_SELL || dir==ORDER_TYPE_SELL_STOP || dir==ORDER_TYPE_SELL_LIMIT) return(NormalPrice(MathMin(op-TP*m_pnt,pr-stop)));
   return(WRONG_VALUE);
  }
//---------------------------------------------------------------   NSL

//direccion, BasePrice , reverse, SL (points), stop level
double script::NormalSL(int dir,double op,double pr,double SL,double stop)
  { 
   if(SL==0) return(NormalPrice(-1));
   if(dir==ORDER_TYPE_BUY || dir==ORDER_TYPE_BUY_STOP || dir==ORDER_TYPE_BUY_LIMIT) return(NormalPrice(MathMin(op-SL*m_pnt,pr-stop)));
   if(dir==ORDER_TYPE_SELL || dir==ORDER_TYPE_SELL_STOP || dir==ORDER_TYPE_SELL_LIMIT) return(NormalPrice(MathMax(op+SL*m_pnt,pr+stop)));
   return(WRONG_VALUE);
  }
//---------------------------------------------------------------   NL
double script::NormalLot(double lot)
  {
   int k=0;
   double ll=lot,ls=m_symbol.LotsStep();
   
   if(ls<=0.001) k=3; else if(ls<=0.01) k=2; else if(ls<=0.1) k=1;
   ll=NormalDbl(MathMin(m_symbol.LotsMax(),MathMax(m_symbol.LotsMin(),ll)),k);
   return(ll);
  }
  
double script::NormalPrice(double d) { return(NormalDbl(MathRound(d/m_symbol.TickSize())*m_symbol.TickSize())); }

double script::NormalDbl(double d,int n=-1) {  if(n<0) return(::NormalizeDouble(d,m_symbol.Digits())); return(NormalizeDouble(d,n)); }

   
 //------------------------------------------------------------------    
//------------------------------------------------------------------  
// Handle events
//------------------------------------------------------------------
//------------------------------------------------------------------  
script EURUSD; // class instance

int OnInit()
  { 
   EURUSD.Init("GBPUSD",period); // initialize expert
   return(0);
  }

void OnTick()
  {
  EURUSD.Main();
  }