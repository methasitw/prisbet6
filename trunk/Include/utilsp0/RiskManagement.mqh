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
#include <utilsp0\ServiceFunctions.mqh>

input int ATRPeriod =14;
input double margin = 0.0910;

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
   
   virtual void      TrailingPosition(long dir,int TS); // trailing position of Stop Loss
   
   ulong             DealOpen(long dir,double lot,double SL,double TP, bool pyr);    
   long              marginPerformance(int order);
   double            getLotN();
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
   
   ExtATRHandle = iATR(NULL,PERIOD_H4,ATRPeriod);
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

void RiskManagement::TrailingPosition(long dir,int TS)
  {
   double sl,apr,csl,cop,ctp;
   if(TS<=0) return;
   if(!PositionSelect(m_smb)) return;                       // if there is no positions or error, then exit
   m_symbol.Refresh(); m_symbol.RefreshRates();             // update symbol parameters
   double StopLvl=m_symbol.StopsLevel()*m_symbol.Point();   // Stop Level
   double FreezLvl=m_symbol.FreezeLevel()*m_symbol.Point(); // Freeze level
   apr=ea.ReversPrice(dir);
   cop=ea.NormalDbl(PositionGetDouble(POSITION_PRICE_OPEN));   // price of position opening
   csl=ea.NormalDbl(PositionGetDouble(POSITION_SL));           // Stop Loss
   ctp=ea.NormalDbl(PositionGetDouble(POSITION_TP));           // Take Profit
   if(MathAbs(ctp-apr)<=FreezLvl || MathAbs(csl-apr)<=FreezLvl) return;  // check freeze level
   sl=ea.NormalSL(dir,apr,apr,TS,StopLvl);                     // calculate Stop Loss
   if((dir==ORDER_TYPE_BUY && apr-cop>TS*m_pnt && (sl>cop && (sl>csl || csl==ea.NormalPrice(0)))) // check condition
      || (dir==ORDER_TYPE_SELL && cop-apr>TS*m_pnt && (sl<cop && (sl<csl || csl==ea.NormalPrice(0)))))
     {
      if(!m_trade.PositionModify(m_smb,sl,ctp))             // move Stop Loss to new place
         ea.ErrorHandle(GetLastError(),PositionGetInteger(POSITION_IDENTIFIER),"-TrailingPosition ");
     }
  }

 //------------------------------------------------------------------ 
//------------------------------------------------------------------  
  ulong RiskManagement::DealOpen(long dir,double lot,double SL,double TP, bool pyr)
  {
       if(lot<=0) return -1;
         double op, tp,apr,StopLvl;
       
         m_symbol.RefreshRates(); m_symbol.Refresh();
         StopLvl=m_symbol.StopsLevel()*m_symbol.Point(); // remember stop level
      
         apr=ea.ReversPrice(dir); 
         op=ea.BasePrice(dir);        // open price
         tp=ea.NormalTP(dir, op, apr, TP, StopLvl);         // Take Profit
         printf(__FUNCTION__+" open price: " + op + " reverse price: " + apr + " Stop Loss: " + SL + " StopLvl: " +  StopLvl); 
          
        if(!pyr)  m_trade.PositionOpen(m_smb,(ENUM_ORDER_TYPE)dir,ea.NormalLot(lot),op,ea.NormalSL(dir, op, apr, SL, StopLvl),tp);
              else    m_trade.PositionOpen(m_smb,(ENUM_ORDER_TYPE)dir,ea.NormalLot(lot),op,SL,tp);
                  
         ulong order=m_trade.ResultOrder(); if(order<=0) return(-6); // order ticket
         return(ea.GetDealByOrder(order));                  // return deal ticket
  }
  

//------------------------------------------------------------------ 
//------------------------------------------------------------------   
double RiskManagement::getStopByRisk(long dir, double lot)
{
   double sl,apr,csl,cop,ctp;
    if(!PositionSelect(m_smb)) return -2;        							             // if there is no positions or error, then exit
   m_symbol.Refresh(); m_symbol.RefreshRates();                                     // update symbol parameters
    double Margin = (m_account.FreeMargin()*0.05+PositionGetDouble(POSITION_PROFIT));
    double totalVolumen   =  (PositionGetDouble(POSITION_VOLUME) + lot ) ;       
	double Puntos = Margin /(totalVolumen * 10);   //10 dolares x punto
	printf(__FUNCTION__+ " Margin: " +Margin+ " totalVolumen " + totalVolumen + " puntos " + Puntos);

   double StopLvl=m_symbol.StopsLevel()*m_symbol.Point();                      // Stop Level
   double FreezLvl=m_symbol.FreezeLevel()*m_symbol.Point();                 // Freeze level
   apr=ea.ReversPrice(dir);                                          
   cop=ea.NormalDbl(PositionGetDouble(POSITION_PRICE_OPEN));          // price of position opening
   csl=ea.NormalDbl(PositionGetDouble(POSITION_SL));                  // Stop Loss
   ctp=ea.NormalDbl(PositionGetDouble(POSITION_TP));                // Take Profit

  if(MathAbs(ctp-apr)<=FreezLvl || MathAbs(csl-apr)<=FreezLvl) return -3;          // check freeze level
   
   sl=ea.NormalSL(dir,apr,apr,Puntos,StopLvl);                                                                                                                                                                                               // calculate Stop Loss
   
 printf(__FUNCTION__+ " Reverse price " + apr + " NEW Stop Loss: " +sl+ " price of position opening: " + cop + " Stop Loss: " + csl);
   if((dir==ORDER_TYPE_BUY &&  (sl>cop && (sl>csl )))  || (dir==ORDER_TYPE_SELL  && (sl<cop && (sl<csl ))))
     {
		return sl;
     }
     else return csl;
     
	return -4;
  }

//------------------------------------------------------------------ 
//------------------------------------------------------------------ 
double RiskManagement::getStopByPercent(long dir, double prct)
{							             // if there is no positions or error, then exit
   m_symbol.Refresh(); m_symbol.RefreshRates();                                     // update symbol parameters
   //double sl = (MathAbs(1 - ea.BasePrice(dir)) * (prct)*10);      
   double sl = (MathAbs( ea.BasePrice(dir)) * (prct));      
	printf(__FUNCTION__+ " El stop correspondiente a el 0.008 % del precio es : " + sl  );
  return sl;
  }
  
//------------------------------------------------------------------ 
//------------------------------------------------------------------   
long RiskManagement::marginPerformance(int dir)
  {
   double High[],Low[];

      int high =  CopyHigh(NULL,PERIOD_W1,0,52,High);
      int low =  CopyLow(NULL,PERIOD_W1,0,52,Low);

          double down = Low[ArrayMinimum(Low, 0, WHOLE_ARRAY)]   ;
          double up =   High[ArrayMaximum(High, 0, WHOLE_ARRAY)] ;

               double  down1 = down + down*margin;
               double up1 = up - up*margin;

   if ( ea.BasePrice(ORDER_TYPE_BUY) <= down1  && dir ==ORDER_TYPE_BUY )
    {
   
     Print("El precio "+ ea.BasePrice(ORDER_TYPE_BUY)+" se situa fuera del margen [ " +down+ " : " +up+ " ] [ " +down1+ " : " +up1+ " ] ORDER_TYPE_BUY " );
     return ORDER_TYPE_BUY;
    }
    else if (ea.BasePrice(ORDER_TYPE_SELL)>= up1 &&  dir ==ORDER_TYPE_SELL)
    {
       
     Print("El precio "+ ea.BasePrice(ORDER_TYPE_BUY)+" se situa fuera del margen [ " +down+ " : " +up+ " ] [ " +down1+ " : " +up1+ " ] ORDER_TYPE_SELL " );
      return ORDER_TYPE_SELL;
    }
    return(WRONG_VALUE);
  }


//------------------------------------------------------------------ 
//------------------------------------------------------------------ 
//------------------------------------------------------------------ 
//------------------------------------------------------------------ 
double RiskManagement::getLotN()
  {
   double lot=0.0;
   double atr = 0.0;
    atr = getN();
 
  lot = (0.01 * m_account.FreeMargin()) /(ATR[0]*10000);//  10000 dolares x punto
  
  printf(__FUNCTION__+" Lot normalizado = " +  lot , 0);
   if (lot >5)
      lot = 4;
   return(lot);
  }
  
  
  double RiskManagement::getN()
  {
   double atr = 0.0;
   if(!CopyBufferAsSeries(ExtATRHandle,0,0,20,true,ATR)) return(-1);
    atr = ATR[0];
    return(atr);
  }
  
  
  

