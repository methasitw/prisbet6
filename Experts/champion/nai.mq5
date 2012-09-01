#property copyright "hippie Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>    
                                
input int    TakeProfit   = 1200;          // Take Profit distance solo se ejecuta si el volumen es menor q PeakVolumen              
input int bands_period     = 90;            // Bollinger Bands period
input double deviation     =1.8;          // Standard deviation  // 2.0

//---indicator parameters pyr 
input int bands_periodPyr= 25;            // Bollinger Bands period PYR


input int InpFastEMA       = 12;              // InpFastEMA script
input int InpSlowEMA       = 25 ;            // InpSlowEMA script
input int  InpSlowestEMA   = 850;            // InpSlowestEMA script
   
input ENUM_TIMEFRAMES TFATR = PERIOD_D1;
input ENUM_TIMEFRAMES period = PERIOD_H1;
input int ATRPeriod  = 14 ;

// risk management
input double volP = 10; // volatilidad que arriesgamos en la entrada
input double vol = 5; 
input int MaxNOrders = 2;
input int DD = 5000;


class script   
  {
protected:
   double         sl, tp ;         
   int            Bands_handle_PYR, Bands_handle, EMAFastMaHandle, EMASlowMaHandle , EMASlowestMaHandle;           
   double         FastEma[],SlowEma[] , SlowestEma[];      // EMA lines
   string         m_smb; ENUM_TIMEFRAMES m_tf ; 
   double         Base[], Upper[],  Lower[];     //  BASE_LINE, UPPER_BAND and LOWER_BAND  of iBands
   int            MaxNumberOrders  ; 
   double         ATR[];
   int            ExtATRHandle;
   double            m_pnt;         // consider 5/3 digit quotes for stops
      
      
   CTrade trade;  
   CSymbolInfo       m_symbol;      
   
   
public:
  void        script();
//void       ~script();
  
   bool      Init(string smb,ENUM_TIMEFRAMES tf); // initialization
   bool      Main();                              // main function
   
  void      OpenPosition(long dir);              // open position on signal
  void      ClosePosition(long dir) ;
  void      PyrPosition() ;
  long      CheckSignal(long type);            // check signal
  long      CheckFilter(long type);  
  bool      Deal(long type, bool pyr); 
  long      LastClosePrice(int dir);
  long      CheckSignalClose(long dir, bool bEntry);
  bool      getMaxNumerOrders(long dir,bool pyr);

  // to piramiding
   long           CheckSignalPyr(long type, bool bEntry);            // check signal

  // long          CheckFilterPyr(long type);  
    long          CheckDistance(long type, bool bEntry);
    double        LastDealOpenPrice();
    
    // aux functions
   bool CopyBufferAsSeries (int handle, int bufer, int start,  int number,  bool asSeries,  double &M[]); 
   double  BasePrice(long dir);
   double ReversPrice(long dir);
   double getNVince();
   ulong DealOpen(long dir,double lot,double SL,double TP);
   
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

//------------------------------------------------------------------?  
//    Init
//------------------------------------------------------------------?  
bool script::Init(string smb,ENUM_TIMEFRAMES tf)
  {
    printf(__FUNCTION__+ " ### start ### "  );
   m_smb=smb ; m_tf=tf ; 
   tp=TakeProfit;   sl=-1; 
   MaxNumberOrders = 0;
   m_symbol.Name(smb);
   m_pnt=m_symbol.Point();  
 
     //--- creation of the indicator iBands
  Bands_handle=iBands(m_smb,period,bands_period,0,deviation,PRICE_CLOSE);
  Bands_handle_PYR=iBands(m_smb,period,bands_periodPyr,0,deviation,PRICE_CLOSE);
  
  ExtATRHandle = iATR(m_smb,TFATR,ATRPeriod);
  
  EMAFastMaHandle=iMA(m_smb,period,InpFastEMA,0,MODE_SMMA,PRICE_CLOSE);
  EMASlowMaHandle=iMA(m_smb,period,InpSlowEMA,0,MODE_SMMA,PRICE_CLOSE);
  EMASlowestMaHandle=iMA(m_smb,period,InpSlowestEMA,0,MODE_SMA,PRICE_CLOSE);
         
  //--- report if there was an error in object creation
     if(Bands_handle<0 || EMAFastMaHandle < 0 || EMASlowMaHandle < 0 || Bands_handle_PYR <0 || EMASlowestMaHandle < 0 )
     {
      printf(__FUNCTION__+"The creation of indicator has failed: Runtime error = " + GetLastError());
      return(-1);
     }

     return(true);                         // "trade allowed"
  }
//------------------------------------------------------------------?  
//    Mainfunction
//------------------------------------------------------------------?  
bool script::Main()
  {

     if(Bars(m_smb,m_tf)<=bands_period) return(false); // if there are insufficient number of bars
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
         else{
			(PositionGetInteger(POSITION_TYPE));
         }
    }
     return(true);
  }

//------------------------------------------------------------------  
// Open Position
//------------------------------------------------------------------
  void script::OpenPosition(long dir)
  {
       if(dir!=CheckSignal(dir)) return;// if there is no signal for current direction
                 printf(__FUNCTION__+ " ### EMA cruzada   ### "  );      
                  Deal(dir, false);
   }
 
  //------------------------------------------------------------------  
 // Pyr Position
//------------------------------------------------------------------
  void script::PyrPosition()
  {                                                                  
                        if(PositionGetInteger(POSITION_TYPE)!=CheckSignalPyr(PositionGetInteger(POSITION_TYPE), true)) return;
                               printf("                       * piramida *  " );
                               printf(__FUNCTION__+ " Dispersion BB 20 tocada . Deal numero: " + HistoryOrdersTotal() );
                         Deal(PositionGetInteger(POSITION_TYPE), true);                      
                        return ;
  }

 //------------------------------------------------------------------?  
// Close Position if the price touch the bollinger bands an the volumen is more than PeakVolumen
//------------------------------------------------------------------ 
  void script::ClosePosition(long dir)
  {       
      if(dir!=CheckSignalClose(dir, false)) return;       
         printf(__FUNCTION__+ "MaxNumberOrders " +MaxNumberOrders+ "POSITION CERRADA: POSITION_VOLUME: "  + PositionGetDouble(POSITION_VOLUME) +" POSITION_PROFIT: "  + PositionGetDouble(POSITION_PROFIT));
         printf(__FUNCTION__+ "HistoryOrdersTotal " +HistoryOrdersTotal()+ "POSITION CERRADA: ACCOUNT_BALANCE: "  + AccountInfoDouble(ACCOUNT_BALANCE) +" ACCOUNT_EQUITY: "  + AccountInfoDouble(ACCOUNT_EQUITY));
         trade.PositionClose(m_smb,1);
  }


//------------------------------------------------------------------?  
// Check Signal
//------------------------------------------------------------------ 
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

//------------------------------------------------------------------   
// Check Filter  !!! atencion hay que conseguir el UPPER y el LOWER 
//------------------------------------------------------------------ 
 
long script::CheckSignalClose(long dir, bool bEntry)
  {  
      
       if(!CopyBufferAsSeries(Bands_handle,1,0,0,true,Upper)) return(false);
       if(!CopyBufferAsSeries(Bands_handle,2,0,0,true,Lower)) return(false);
              
          if( BasePrice( dir) < Lower[0]   )
               {  
          // printf(__FUNCTION__+ " Dispersion negativa tocada x S    ORDER_TYPE_BUY  Lower: " + NormalizeDouble(Lower[0],5)  + " Ask: " +NormalizeDouble(BasePrice(dir),5));
                     return(bEntry  ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
               }
          else  if(  BasePrice( dir)  > Upper[0])
                   {  
          //?  printf(__FUNCTION__+ " Dispersion Positivatocada x S    ORDER_TYPE_SELL      Upper: " +  NormalizeDouble(Upper[0],5)+ " Bid: "  + NormalizeDouble(BasePrice(dir),5) );
                        return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);
                   }
   return(WRONG_VALUE);
  }
  


//------------------------------------------------------------------?  
//------------------------------------------------------------------ 
bool script::Deal(long dir, bool pyramiding)     // eliminado ratio, necesidad de dos deal diferentes para pir y para entrada inciial ¿
{

   if(!CopyBufferAsSeries(ExtATRHandle,0,0,14,true,ATR)) return(-1);
    double pips = ATR[0];

    if (pyramiding == true)           //piramida
   {
   

    pips = pips * volP ; // pongo un stop de 3/2 del ATR

    double lot = getNVince()*2;  
    if ( (lot +PositionGetDouble(POSITION_VOLUME))  > 15.0 )
            lot = 14.99 -  PositionGetDouble(POSITION_VOLUME);
          
    double lot2 = lot/2;
    lot = lot/2; 
      
    if ( lot   > 5.0 )                            lot = 5.0;   
         
    DealOpen(dir,lot,pips/10,tp);
    Sleep(50);
    DealOpen(dir,lot2,pips/10,tp);
      return true;
   }
   
   else
   {    
          if ( !getMaxNumerOrders(dir,false)) return false;
   
            pips = pips * vol; 
            double lot =  getNVince();
            
              if ( lot   > 5.0 )
                      lot = lot = 5.0;
                      
            printf(__FUNCTION__+ " Abrimos posicion con un stop de  " +pips /10 + " pips. y lot de "  + lot  );

            DealOpen(dir,lot, pips/10, tp);
       return true;
    }
   return false;
 }   
 /*
 -------------------------FUNCIONES PIRAMIDACION --------------------------
 */
 
//------------------------------------------------------------------?  
// Check Signal
//------------------------------------------------------------------ 
long script::CheckSignalPyr(long dir, bool bEntry)
  {  
     
       if(!CopyBufferAsSeries(Bands_handle_PYR,1,0,0,true,Upper)) return(false);
       if(!CopyBufferAsSeries(Bands_handle_PYR,2,0,0,true,Lower)) return(false);
       
       
           if( BasePrice( dir) < Lower[0]   )
               {  
                   //  printf(__FUNCTION__+ " Dispersion negativa tocada x S    ORDER_TYPE_BUY  Lower: " + NormalizeDouble(Lower[0],5)  + " Ask: " +NormalizeDouble(BasePrice(dir),5));
                     return(bEntry  ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
               }

          else  if(  BasePrice( dir)  > Upper[0])
                   {  
                     //    printf(__FUNCTION__+ " Dispersion Positivatocada x S    ORDER_TYPE_SELL      Upper: " +  NormalizeDouble(Upper[0],5)+ " Bid: "  + NormalizeDouble(BasePrice(dir),5) );
                        return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for buy
                   }

   return(WRONG_VALUE);
  }
  


//------------------------------------------------------------------?  
// calcula el número máximo de ordenes de piramidación.
// Si todos devuelven true, significa que entrará al mercado buscando piramidar y no piramidar.
// Si devuleven false cuando  MaxNumberOrders  = 1 significa que el sistema solo piramidará.
// que ocurre si el programa se para durante el fin de semana  la variable del contexto
// MaxNumberOrders volvería a ser 1 o 2 
//------------------------------------------------------------------?  
 bool script::getMaxNumerOrders(long dir, bool pyr) 
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
 
//------------------------------------------------------------------?  
// calculate the distance necessary to process a new deal
//------------------------------------------------------------------ 
  long script::CheckDistance(long dir, bool bEntry)
{   
      double atr,cop,apr;
     if(!CopyBufferAsSeries(ExtATRHandle,0,0,14,true,ATR)) return(-1);
     atr = ATR[0];                            
         cop = LastDealOpenPrice();            // precio del último deal
         apr = BasePrice(dir);                  // precio objetivo actual

        if( cop + atr <  BasePrice( dir))      
            {  
      //  printf(__FUNCTION__+ " LastDealOpenPrice  " +cop  + " atr: " +atr+ " BasePrice: "  + NormalizeDouble( BasePrice( dir),4));
                 return(bEntry  ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
           }
       else if( cop - atr >  BasePrice( dir))
          {       
      //   printf(__FUNCTION__+ " LastDealOpenPrice  " +cop  + " atr: -" +atr+ " BasePrice: "  + NormalizeDouble(BasePrice( dir),4));
               return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for sell
          }
         return(WRONG_VALUE);
}
//------------------------------------------------------------------?  
// Last deal open price to calculate the distance necessary to process a new deal
//------------------------------------------------------------------ 
double script::LastDealOpenPrice()
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
  
  
/*
AUX FUNCTIONS
*/
    
double script::getNVince()
{
//N = [(1 + 8 * Equity / Delta) 0,5 +1] / 2
//Delta neutro = DD / 2
//N =  [ 1+ (1 + 8 * 50.000 / 7.000) ^ 0,5 ] / 2 = 4 contratos.

long Equity = AccountInfoDouble(ACCOUNT_FREEMARGIN);;
long DeltaNeutro = DD/2;
long value = 1 + 8*(Equity/DeltaNeutro );
long valuesqrt = sqrt(value);
long N = 1 + ( valuesqrt / 2);

 Print(__FUNCTION__+" El Equity "+ Equity+"  DeltaNeutro: " +DeltaNeutro+ " N: " + N + " value" + value  + " valuesqrt "  + valuesqrt );
 
 return N;
}
  
    

  
bool script::CopyBufferAsSeries( int handle, int bufer, int start, int number,  bool asSeries,  double &M[] )
  {
   if(CopyBuffer(handle,bufer,start,number,M)<=0) return(false);
   ArraySetAsSeries(M,asSeries);
   return(true);
  }
  
   //------------------------------------------------------------------ 
//------------------------------------------------------------------  
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
         printf(__FUNCTION__+" open price: " + op + " reverse price: " + apr + " sl: " + sl + " SL: " +  SL); 
          
          trade.PositionOpen(m_smb,(ENUM_ORDER_TYPE)dir,NormalLot(lot),op,sl,tp);
      
         ulong order=trade.ResultOrder(); if(order<=0) return(-6); // order ticket
         return(order);                  // return deal ticket
  }
  
   double script:: BasePrice(long dir)
  {
   m_symbol.Refresh(); // refresh symbol info
   m_symbol.RefreshRates();
   
   if(dir==(long)ORDER_TYPE_BUY) return(NormalizeDouble(m_symbol.Ask(),5));
   if(dir==(long)ORDER_TYPE_SELL) return(NormalizeDouble(m_symbol.Bid(),5));
   return(WRONG_VALUE);
  }

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
//(dir,apr,apr,Puntos,StopLvl); 

//direccion, BasePrice , reverse, SL (points), stop level
double script::NormalSL(int dir,double op,double pr,double SL,double stop)
  {
  
  printf("op " + op +" SL " + SL + " m_pnt "  +m_pnt +" el maximo tiene que ser el reverse mas el stop level reverse " +  pr + " stop level "+ stop);
  
  printf("op+SL*m_pnt  " + (op+SL*m_pnt) +" pr+stop " + (pr+stop) );
    
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

    
script EURUSD; // class instance
//------------------------------------------------------------------?  OnInit
int OnInit()
  { 
   EURUSD.Init("EURUSD",period); // initialize expert
   return(0);
  }


//------------------------------------------------------------------?  OnTick
void OnTick()
  {
  EURUSD.Main();
  }
//+------------------------------------------------------------------+
