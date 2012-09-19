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
#include <Trade\ExpertTradeForATC2011.mqh>
#include <IAMotta\ServiceFunctions.mqh>

input int ATRPeriod =14;
input ENUM_TIMEFRAMES TFATR = PERIOD_D1;
class RiskManagement
  {
public:
   
    CSymbolInfo       m_symbol;                 // symbol parameters
    CAccountInfo      m_account;              // object-deposit
    CExpertTradeForATC2011   m_trade;           // object to execute trade orders
    CExpertAdvisor    ea;
    
   double            m_pnt;         // consider 5/3 digit quotes for stops
   string            m_smb;         // symbol, on which expert works
   bool m_bInit;
   ENUM_TIMEFRAMES   m_tf;
    
   
 
   protected:
   double            ATR[];
   int               ExtATRHandle;
   ulong             m_magic;       // magic number of expert
 
public:
    void              RiskManagement();
    void             ~RiskManagement();
   //--- Methods to set the parameters
   
   virtual bool Init(long magic,string smb,ENUM_TIMEFRAMES tf);
   virtual bool Main();

   long           getNVince();
   ulong             DealOpen(long dir,double lot,double SL,double TP);    
   long              marginPerformance(int order, double margin, bool bEntry);
   long              MaxMinAbsolut(long dir);
   double            getN();
   double            getStopByPercent(long dir, double prct); 

     double       getPips();
   
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
   
   ExtATRHandle = iATR(m_smb,TFATR,ATRPeriod);
   
      if(ExtATRHandle<0  )
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


  /*
  Reducción Absoluta de la Equidad:			13 537,00		

  
  */
  
long RiskManagement::getNVince()
{
//N = [(1 + 8 * Equity / Delta) 0,5 +1] / 2
//Delta neutro = DD / 2
//N =  [ 1+ (1 + 8 * 50.000 / 7.000) ^ 0,5 ] / 2 = 4 contratos.

long Equity = m_account.FreeMargin();
long DeltaNeutro = DD/2;
long value = 1 + 8*(Equity/DeltaNeutro );
long valuesqrt = sqrt(value);
long N = 1 + ( valuesqrt / 2);

 Print(__FUNCTION__+" El Equity "+ Equity+"  DeltaNeutro: " +DeltaNeutro+ " N: " + N + " value" + value  + " valuesqrt "  + valuesqrt );
 
 return N;
}
  
  


  
  
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

    return(atr);
  }