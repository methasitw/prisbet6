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
#include <util\GetIndicatorBuffers.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Expert\ExpertTrade.mqh>
input int ATRPeriod =14;

class RiskManagement : public CExpertTrade
  {
public:
   
    CSymbolInfo       m_symbol;              // symbol parameters
    CAccountInfo      m_account;              // object-deposit
   double            m_lots;  
   double            m_percent;
   bool m_bInit;
   ENUM_TIMEFRAMES   m_tf;
   
 
   protected:
   double            m_decrease_factor;
   double            ATR[];
   int               ExtATRHandle;
public:
    void              RiskManagement();
    void             ~RiskManagement();
   //--- Methods to set the parameters
   virtual bool              Init(long magic,string smb,ENUM_TIMEFRAMES tf);
   void              Lots(double lots) { m_lots=lots; }

   //--- Methods to define the volume
   virtual double    CheckOpenLong(double price,double sl);
   virtual double    CheckOpenShort(double price,double sl);
   virtual  double            getLotN(double iLot);
   virtual  double            Optimize(double lots);
   bool              CheckOrders(MqlTradeRequest& request,MqlTradeCheckResult& check_result);
   bool              CheckVolumes(MqlTradeRequest& request,MqlTradeCheckResult& check_result);
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
   m_tf=tf;     // set initializing parameters
   m_symbol.Name(smb);                  // initialize symbol
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
//--- Successful completion
   return(true);
   
   m_bInit=true; return(true);            // trade allowed
  }
  
  
  

//+------------------------------------------------------------------+
//| Defining the volume to open a long position.                     |
//| INPUT:  no.                                                      |
//| OUTPUT: lot-if successful, 0.0 otherwise.                        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
double RiskManagement::CheckOpenLong(double price,double sl)
  {
//--- Select the lot size
   double lot=2*CheckPrevLoss();
   if(lot==0.0) lot=m_lots;
//--- Check the limits
   double maxvol=m_symbol.LotsMax();
   if(lot>maxvol) lot=maxvol;
//--- Check the margin requirements
   if(price==0.0) price=m_symbol.Ask();
   maxvol=m_account.MaxLotCheck(m_symbol.Name(),ORDER_TYPE_BUY,price,m_percent);
   if(lot>maxvol) lot=maxvol;
//--- Return the trade volume
   return(lot);
  }
//+------------------------------------------------------------------+
//|Defining the volume to open a short position.                     |
//| INPUT:  no.                                                      |
//| OUTPUT: lot-if successful, 0.0 otherwise.                        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
double RiskManagement::CheckOpenShort(double price,double sl)
  {

//--- Select the lot size
   double lot=2*CheckPrevLoss();
   if(lot==0.0) lot=m_lots;
//--- Check the limits
   double maxvol=m_symbol.LotsMax();
   if(lot>maxvol) lot=maxvol;
//--- Check the margin requirements
   if(price==0.0) price=m_symbol.Bid();
   maxvol=m_account.MaxLotCheck(m_symbol.Name(),ORDER_TYPE_SELL,price,m_percent);
   if(lot>maxvol) lot=maxvol;
//--- Return the trade volume
   return(lot);
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

double RiskManagement::getLotN(double iLot)
  {
   double lot=0.0;

 if(!CopyBufferAsSeries(ExtATRHandle,0,0,20,true,ATR)) return(-1);
 
  printf(__FUNCTION__+" ATR = " + ATR[0], 0);
  
 
 
 // lot = (0.01 * m_account.FreeMargin()) /(ATR[0]*10000);//  10000 dolares x punto
  lot = (iLot * m_account.FreeMargin()) /(ATR[0]*10000);//  10000 dolares x punto
  
  printf(__FUNCTION__+" Lot normalizado = " +  lot , 0);
 // lot = Optimize(lot);
 // printf(__FUNCTION__+" Lot optimizado = " +  lot , 0);
  
   return(lot);
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
//| Checks compliance with the ATC 2011 Rules.                       |
//| INPUT:  request      - a reference to the request structure.     |
//|         check_result - a reference to check result structure.    |
//| OUTPUT: true - if the rules are met, otherwise - false.          |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+

bool RiskManagement::CheckVolumes(MqlTradeRequest& request,MqlTradeCheckResult& check_result)
  {
   CPositionInfo position;
   COrderInfo    order;
   string        symbol=m_request.symbol;
   double        summ=0.0;
//--- Check orders
   int           total=OrdersTotal();
   for(int i=0;i<total;i++)
      if(order.SelectByIndex(i) && order.Symbol()==symbol)
         summ+=order.VolumeInitial();
//--- Check a position
   if(position.Select(symbol))
     {
      //--- There is an open position for a symbol
      double volume=position.Volume();
      //--- Check the request
      if(request.action==TRADE_ACTION_DEAL)
        {
         //--- Request for instant execution of a deal
         //--- Check if the request will reduce the position volume
         if((position.PositionType()==POSITION_TYPE_BUY && request.type==ORDER_TYPE_SELL) ||
            (position.PositionType()==POSITION_TYPE_SELL && request.type==ORDER_TYPE_BUY))
           {
            //--- The request will reduce the position volume
            if(request.volume>volume) summ+=request.volume-volume;
            else                      summ+=volume-request.volume;
           }
         else
           {
            //--- The request will add to the position volume
            summ+=request.volume;
            summ+=volume;
           }
        }
      else
        {
         //--- A request to place a pending order
         summ+=request.volume;
         summ+=volume;
        }
     }
   else
     {
      //--- No open position for a symbol
      summ+=request.volume;
     }
//--- Check the total volume
   if(summ>=15.0)
     {
      string action;
      //--- Add an error info to the log
      if(m_log_level>LOG_LEVEL_NO)
         printf(__FUNCTION__+": %s (exceeded the max allowed volume for a symbol)",FormatRequest(action,m_request));
      m_check_result.retcode=TRADE_RETCODE_LIMIT_VOLUME;
      //--- Finished with an error
      return(false);
     }
//--- Finished without errors
   return(true);
  }


  //+------------------------------------------------------------------+
//| Checks compliance with the ATC 2011 Rules (in terms of the       |
//| number of pending orders).                                       |
//| INPUT:  request      - a reference to the request structure,     |
//|         check_result - a reference to check result structure.    |
//| OUTPUT: true - if the rules are met, otherwise - false.          |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool RiskManagement::CheckOrders(MqlTradeRequest& request,MqlTradeCheckResult& check_result)
  {
   if(OrdersTotal()>=12)
     {
      string action;
      //--- Add error info to the log
      if(m_log_level>LOG_LEVEL_NO)
         printf(__FUNCTION__+": %s (too many orders)",FormatRequest(action,m_request));
      m_check_result.retcode=TRADE_RETCODE_LIMIT_ORDERS;
      //--- Finished with an error
      return(false);
     }
//--- Finished without errors
   return(true);
  }