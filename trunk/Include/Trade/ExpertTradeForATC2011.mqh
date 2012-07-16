//+------------------------------------------------------------------+
//|                                        ExpertTradeForATC2011.mqh |
//|                      Copyright © 2011, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//|                                              Revision 2011.06.14 |
//+------------------------------------------------------------------+
#include <Expert\ExpertTrade.mqh>
//+------------------------------------------------------------------+
//| Class CExpertTradeForATC2011.                                    |
//| Purpose: A class of trade operations meeting the ATC 2011 Rules. |
//|             Derived from CExpertTrade.                           |
//+------------------------------------------------------------------+
class CExpertTradeForATC2011 : public CExpertTrade
  {
public:
   virtual bool      OrderCheck(MqlTradeRequest& request,MqlTradeCheckResult& check_result);

protected:
   bool              CheckOrders(MqlTradeRequest& request,MqlTradeCheckResult& check_result);
   bool              CheckVolumes(MqlTradeRequest& request,MqlTradeCheckResult& check_result);
  };
//+------------------------------------------------------------------+
//| Checks compliance with the ATC 2011 Rules.                       |
//| INPUT:  request      - a reference to the request structure,     |
//|         check_result - a reference to check result structure.    |
//| OUTPUT: true - if the rules are met, otherwise - false.          |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CExpertTradeForATC2011::OrderCheck(MqlTradeRequest& request,MqlTradeCheckResult& check_result)
  {
//--- Select action according to the request type
   switch(request.action)
     {
      //--- Place a pending order
      case TRADE_ACTION_PENDING:
         if(!CheckOrders(request,check_result))  return(false);
      //--- Instant execution of a deal
      case TRADE_ACTION_DEAL:
         if(!CheckVolumes(request,check_result)) return(false);
         break;
      //--- Place SL/TP
      case TRADE_ACTION_SLTP:
      //--- Modify a pending order
      case TRADE_ACTION_MODIFY:
      //--- Delete a pending order
      case TRADE_ACTION_REMOVE:
         break;
      default:
         Print(__FUNCTION__+": unknown action");
         break;
     }
//--- Return result of execution of a parent class method
   return(CExpertTrade::OrderCheck(request,check_result));
  }
//+------------------------------------------------------------------+
//| Checks compliance with the ATC 2011 Rules (in terms of the       |
//| number of pending orders).                                       |
//| INPUT:  request      - a reference to the request structure,     |
//|         check_result - a reference to check result structure.    |
//| OUTPUT: true - if the rules are met, otherwise - false.          |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CExpertTradeForATC2011::CheckOrders(MqlTradeRequest& request,MqlTradeCheckResult& check_result)
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
//+------------------------------------------------------------------+
//| Checks compliance with the ATC 2011 Rules (in terms of the total |
//| volume of pending orders and positions of a symbol).             |
//| INPUT:  request      - a reference to the request structure,     |
//|         check_result - a reference to check result structure.    |
//| OUTPUT: true - if the rules are met, otherwise - false.          |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CExpertTradeForATC2011::CheckVolumes(MqlTradeRequest& request,MqlTradeCheckResult& check_result)
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
