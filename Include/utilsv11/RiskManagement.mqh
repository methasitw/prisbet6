//+------------------------------------------------------------------+
//|                                                  SampleMoney.mqh |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| Include files                                                    |
//+------------------------------------------------------------------+

#include <Trade\DealInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\Trade.mqh>
#include <utilsv11\ServiceFunctions.mqh>


class RiskManagement
  {
public:
   
    CSymbolInfo       m_symbol;                 // symbol parameters
    CAccountInfo      m_account;              // object-deposit
    CTrade            m_trade;               // object to execute trade orders
    CExpertAdvisor    ea;
    
   double            m_pnt;         // consider 5/3 digit quotes for stops
   string            m_smb;         // symbol, on which expert works
   bool m_bInit;
   ENUM_TIMEFRAMES   m_tf;
    
   
 
   protected:
   double            ATR[];
   int               ExtATRHandle, ExtATRHandleWeek;
   ulong             m_magic;       // magic number of expert
 
public:
    void              RiskManagement();
    void             ~RiskManagement();
   //--- Methods to set the parameters
   
   virtual bool Init(long magic,string smb,ENUM_TIMEFRAMES tf);
   virtual bool Main();
   
  
   ulong             DealOpen(long dir,double lot,double SL,double TP);    
   long              marginPerformance(int order);
   double            getPips();
   double            getN();
   double            getStopByRisk(long dir, double lot);
   double            getStopByPercent(long dir, double prct); 
   
  };
//+------------------------------------------------------------------+
//| Constructor RiskManagement.                                        |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void RiskManagement::RiskManagement()
  {

  }
  
  
  void RiskManagement::~RiskManagement()
  {
  IndicatorRelease(ExtATRHandle);
    IndicatorRelease(ExtATRHandleWeek);
  }
  
  
  bool RiskManagement::Init(long magic,string smb,ENUM_TIMEFRAMES tf)
  {
  
  if(!ea.Init(0,smb,tf)) return(false);  // initialize object CExpertAdvisor
  
   m_smb=smb; m_tf=tf;     // set initializing parameters
   m_symbol.Name(m_smb);                  // initialize symbol
   m_pnt=m_symbol.Point();                // calculate multiplier for 5/3 digit quote
   m_magic=magic;   
   m_trade.SetExpertMagicNumber(m_magic); // set magic number for expert
   
   if(m_symbol.Digits()==5 || m_symbol.Digits()==3) m_pnt*=10; // 
   
   ExtATRHandle = iATR(NULL,TFATR,ATRPeriod);
   ExtATRHandleWeek = iATR(NULL,PERIOD_W1,52);
   
      if(ExtATRHandle<0 || ExtATRHandleWeek <0 )
     {
      printf(__FUNCTION__+__FUNCTION__+"The creation of iBands has failed: Runtime error = " + GetLastError(), 0);
      //--- forced program termination
      return(-1);
     }

      m_bInit=true; return(true);            // trade allowed

   return(true);
  }
  
  
  bool RiskManagement::Main() // Main module
  {

   if(!m_bInit) return(false);
   if(!ea.Main()) return(false); // call function of parent class
   if(!MQL5InfoInteger(MQL5_TRADE_ALLOWED) || !TerminalInfoInteger(TERMINAL_CONNECTED))
      return(false);                            // if trade is not possible, then exit
   m_symbol.Refresh(); m_symbol.RefreshRates(); // update symbol parameters
   return(true);
  }
  
  
  



 //------------------------------------------------------------------ 
//------------------------------------------------------------------  
  ulong RiskManagement::DealOpen(long dir,double lot,double SL,double TP)
  {
       if(lot<=0) return -1;
         double op, tp,apr,StopLvl, sl;
       
         m_symbol.RefreshRates(); m_symbol.Refresh();
         StopLvl=m_symbol.StopsLevel()*m_symbol.Point(); // remember stop level
      
         apr=ea.ReversPrice(dir); 
         op=ea.BasePrice(dir);        // open price
         tp=ea.NormalTP(dir, op, apr, TP, StopLvl);         // Take Profit
         
         sl =  ea.NormalSL(dir, op, apr, SL, StopLvl) ;  //pasamos los puntos a stop
         printf(__FUNCTION__+" open price: " + op + " reverse price: " + apr + " Stop Loss: " + sl + " StopLvl: " +  StopLvl); 
          
          m_trade.PositionOpen(m_smb,(ENUM_ORDER_TYPE)dir,ea.NormalLot(lot),op,sl,tp);
      
         ulong order=m_trade.ResultOrder(); if(order<=0) return(-6); // order ticket
         return(ea.GetDealByOrder(order));                  // return deal ticket
  }
  




  
//------------------------------------------------------------------ 
//------------------------------------------------------------------   
long RiskManagement::marginPerformance(int dir)
  {
   double High[],Low[], ATR[];
      
   int high =  CopyHigh(NULL,PERIOD_W1,0,ATRPeriod,High);
   int low =  CopyLow(NULL,PERIOD_W1,0,ATRPeriod,Low);

   
     if(!CopyBufferAsSeries(ExtATRHandleWeek,0,0,ATRPeriod,true,ATR)) return(-1);
    double atr = ATR[0];
    double down = Low[ArrayMinimum(Low, 0, WHOLE_ARRAY)] +( atr/2)  ;
    double up =   High[ArrayMaximum(High, 0, WHOLE_ARRAY)] - ( atr/2);
   
   Print("El precio " + ea.BasePrice(dir)+ " se situa por encima del maximo relativo [  " +up+ " ] para la orden de venta  [ atr :" +  atr/2 +" ]" );
  
   if ( dir == ORDER_TYPE_BUY && ea.BasePrice(dir) <= down  )
    {
    printf("" );     
    Print("El precio " + ea.BasePrice(dir)+ " se situa por debajo del minimo relativo [ " +down+ " ] para la orden de compra [ atr :" +  atr/2 +" ]" );
    return ( ORDER_TYPE_BUY);
    }
    
   else if (  dir == ORDER_TYPE_SELL &&  ea.BasePrice(dir) >= up)
    {
      printf("" );     
      Print("El precio " + ea.BasePrice(dir)+ " se situa por encima del maximo relativo [  " +up+ " ] para la orden de venta  [ atr :" +  atr/2 +" ]" );
      return (ORDER_TYPE_SELL);
    }
    
return (WRONG_VALUE);
    
  }


//------------------------------------------------------------------ 
  
  double RiskManagement::getPips()
  {
   
      double pips = 10000*getN();  // lo pasamos a pips
      printf(__FUNCTION__+" Pips en base volatilidad: " +  pips , 0);
      return(pips);

  }
  



//------------------------------------------------------------------ 

  
  double RiskManagement::getN()
  {
   double atr = 0.0;
   if(!CopyBufferAsSeries(ExtATRHandle,0,0,ATRPeriod,true,ATR)) return(-1);
    atr = ATR[0];
    return(atr);
  }

