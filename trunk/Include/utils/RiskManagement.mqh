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
#include <utils\ServiceFunctions.mqh>

input int ATRPeriod =14;

class RiskManagement
  {
public:
   
    CSymbolInfo       m_symbol;              // symbol parameters
    CAccountInfo      m_account;              // object-deposit
    CTrade            m_trade;       // object to execute trade orders
    CExpertAdvisor ea;
    
   double            m_pnt;         // consider 5/3 digit quotes for stops
   double            m_lots;  
   double            m_percent;
   string            m_smb;         // symbol, on which expert works
   bool m_bInit;
   ENUM_TIMEFRAMES   m_tf;
    
   
 
   protected:
   double            m_decrease_factor;
   double            ATR[];
   int               ExtATRHandle;
   ulong             m_magic;       // magic number of expert
 
public:
    void              RiskManagement();
    void             ~RiskManagement();
   //--- Methods to set the parameters
   virtual bool              Init(long magic,string smb,ENUM_TIMEFRAMES tf);
   virtual bool Main();
   void              Lots(double lots) { m_lots=lots; }

   //--- Methods to define the volume

   virtual  double            getLotN();
   virtual  double            Optimize(double lots);
   virtual  double            getN();
    virtual double          getStopByRisk(long dir, double lot);
   virtual void      BEPosition(long dir,int BE);       // moving Stop Loss to break-even
   virtual void      TrailingPosition(long dir,int TS); // trailing position of Stop Loss
   ulong             DealOpen(long dir,double lot,double SL,double TP);     // execute deal with specified parameters
   ulong             DealOpenPyr(long dir,double lot,double SL,double TP);
   
   protected:
   double            CheckPrevLoss();
   
   
  };
//+------------------------------------------------------------------+
//| Constructor RiskManagement.                                        |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void RiskManagement::RiskManagement()
  {
   m_decrease_factor=3.0;
   m_lots=0.1;
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
   
   ExtATRHandle = iATR(NULL,PERIOD_H4,ATRPeriod);
   

      if(ExtATRHandle<0 )
     {
      printf(__FUNCTION__+__FUNCTION__+"The creation of iBands has failed: Runtime error = " + GetLastError(), 0);
      //--- forced program termination
      return(-1);
     }
     

//--- Validating the parameters
   if(m_lots<m_symbol.LotsMin() || m_lots>m_symbol.LotsMax())
     {
      printf(__FUNCTION__+__FUNCTION__+": The deal volume must be in the range "+m_symbol.LotsMin()+" to "+m_symbol.LotsMax(),0);
      return(false);
     }
   if(MathAbs(m_lots/m_symbol.LotsStep()-MathRound(m_lots/m_symbol.LotsStep()))>1.0E-10)
     {
      printf(__FUNCTION__+__FUNCTION__+": The deal volume must be multiple of  %f",m_symbol.LotsStep());
      return(false);
     }

   m_bInit=true; return(true);            // trade allowed
//--- Successful completion
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
  
  
  
  //--- Trade modules
void RiskManagement::BEPosition(long dir,int BE)
  {
   double sl,apr,csl,cop,ctp;
   if(!PositionSelect(m_smb)) return;                       // if there is no positions or error, then exit
   m_symbol.Refresh(); m_symbol.RefreshRates();             // update symbol parameters
   double StopLvl=m_symbol.StopsLevel()*m_symbol.Point();   // Stop Level
   double FreezLvl=m_symbol.FreezeLevel()*m_symbol.Point(); // Freeze level
   apr=ea.ReversPrice(dir);
   cop=ea.NormalDbl(PositionGetDouble(POSITION_PRICE_OPEN));   // price of position opening
   csl=ea.NormalDbl(PositionGetDouble(POSITION_SL));           // Stop Loss
   ctp=ea.NormalDbl(PositionGetDouble(POSITION_TP));           // Take Profit
   if(MathAbs(ctp-apr)<=FreezLvl || MathAbs(csl-apr)<=FreezLvl) return;          // check freeze level
   sl=ea.NormalPrice(dir==ORDER_TYPE_BUY ? cop+BE*m_pnt:cop-BE*m_pnt);              // calculate new value of Stop Loss
   if((dir==ORDER_TYPE_BUY && sl<apr+StopLvl && (sl>csl || csl==ea.NormalPrice(0))) // check fulfillment of condition
      || (dir==ORDER_TYPE_SELL && sl>apr-StopLvl && (sl<csl || csl==ea.NormalPrice(0))))
     {
      if(!m_trade.PositionModify(m_smb,sl,ctp))             // modify Stop Loss 
         ea.ErrorHandle(GetLastError(),PositionGetInteger(POSITION_IDENTIFIER),"-BEPosition ");
     }
  }
//------------------------------------------------------------------ TralPos
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

  
  ulong RiskManagement::DealOpen(long dir,double lot,double SL,double TP)
  {
   double op,sl,tp,apr,StopLvl;
 
   m_symbol.RefreshRates(); m_symbol.Refresh();
   StopLvl=m_symbol.StopsLevel()*m_symbol.Point(); // remember stop level

   apr=ea.ReversPrice(dir); 
   op=ea.BasePrice(dir);        // open price
   sl=ea.NormalSL(dir, op, apr, SL, StopLvl);         // Stop Loss
   tp=ea.NormalTP(dir, op, apr, TP, StopLvl);         // Take Profit
 
   printf(__FUNCTION__+" open price: " + op + " reverse price: " + apr + " Stop Loss: " + sl + " StopLvl: " +  StopLvl);                                                // open position
   m_trade.PositionOpen(m_smb,(ENUM_ORDER_TYPE)dir,ea.NormalLot(lot),op,sl,tp);
   ulong order=m_trade.ResultOrder(); if(order<=0) return(-6); // order ticket
   return(ea.GetDealByOrder(order));                  // return deal ticket
  }
  
   ulong RiskManagement::DealOpenPyr(long dir,double lot,double SL,double TP)
  {
   double op,tp,apr,StopLvl;
   
// determine price parameters
   printf(__FUNCTION__+" Stop Loss: " + SL  + " dir " + dir + " " + ORDER_TYPE_SELL);   
   
   m_symbol.RefreshRates(); m_symbol.Refresh();
   StopLvl=m_symbol.StopsLevel()*m_symbol.Point(); // remember stop level

   apr=ea.ReversPrice(dir); 
   op=ea.BasePrice(dir);        // open price
  
   tp=ea.NormalTP(dir, op, apr, TP, StopLvl);         // Take Profit
 
   printf(__FUNCTION__+" open price: " + op + " reverse price: " + apr +  " StopLvl: " +  StopLvl);                                                // open position
   m_trade.PositionOpen(m_smb,(ENUM_ORDER_TYPE)dir,ea.NormalLot(lot),op,SL,tp);
   ulong order=m_trade.ResultOrder(); if(order<=0) return(-6); // order ticket
   return(ea.GetDealByOrder(order));                  // return deal ticket
  }
  
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


//+------------------------------------------------------------------+
//| Defines whether the prev. deal was losing.                       |
//| INPUT:  no.                                                      |
//| OUTPUT: Volume of the prev. deal if it's losing, otherwise 0.0   |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
double RiskManagement::CheckPrevLoss()
  {
   double lot=0.0;
//--- Request the history of deals and orders
   HistorySelect(0,TimeCurrent());
//--- variables
   int       deals=HistoryDealsTotal();  // Total number of deals in the history
   CDealInfo deal;
//--- Find the previous deal
   for(int i=deals-1;i>=0;i--)
     {
      if(!deal.SelectByIndex(i))
        {
         printf(__FUNCTION__+": Error of deal selection by index");
         break;
        }
      //--- Check the symbol
      if(deal.Symbol()!=m_symbol.Name()) continue;
      //---Check the profit
      if(deal.Profit()<0.0) lot=deal.Volume();
      break;
     }
//--- Return the volume
   return(lot);
  }
//+------------------------------------------------------------------+

double RiskManagement::getLotN()
  {
   double lot=0.0;
   double atr = 0.0;
    atr = getN();
 
  lot = (0.01 * m_account.FreeMargin()) /(ATR[0]*10000);//  10000 dolares x punto
  
  printf(__FUNCTION__+" Lot normalizado = " +  lot , 0);
   if (lot >5)
      lot = 5;
   return(lot);
  }
  
  
  double RiskManagement::getN()
  {
   double atr = 0.0;
   if(!CopyBufferAsSeries(ExtATRHandle,0,0,20,true,ATR)) return(-1);
    atr = ATR[0];
    return(atr);
  }
  
  
  
  //+------------------------------------------------------------------+
//| Optimizing lot size for open.                                    |
//| INPUT:  no.                                                      |
//| OUTPUT: lot-if successful, 0.0 otherwise.                        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
double RiskManagement::Optimize(double lots)
  {
   double lot=lots;
//--- calculate number of losses orders without a break
   if(m_decrease_factor>0)
     {
      //--- select history for access
      HistorySelect(0,TimeCurrent());
      //---
      int    orders=HistoryDealsTotal();  // total history deals
      int    losses=0;                    // number of consequent losing orders
      CDealInfo deal;
      //---
      for(int i=orders-1;i>=0;i--)
        {
         deal.Ticket(HistoryDealGetTicket(i));
         if(deal.Ticket()==0)
           {
            Print("RiskManagement::Optimize: HistoryDealGetTicket failed, no trade history");
            break;
           }
         //--- check symbol
         if(deal.Symbol()!=m_symbol.Name()) continue;
         //--- check profit
         double profit=deal.Profit();
         if(profit>0.0) break;
         if(profit<0.0) losses++;
        }
      //---
      if(losses>1) lot=NormalizeDouble(lot-lot*losses/m_decrease_factor,2);
     }

//---
   double minvol=m_symbol.LotsMin();
   if(lot<minvol) lot=minvol;
//---
   double maxvol=m_symbol.LotsMax();
   if(lot>maxvol) lot=maxvol;
//---
   return(lot);
  }
//+------------------------------------------------------------------+

