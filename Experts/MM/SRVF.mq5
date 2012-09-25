
#property copyright "Pablo Leon"

#include <Trade\Trade.mqh>    
#include <Trade\AccountInfo.mqh>
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+

input int Fast=25;
input int Slow=450;
input int Sign=35;
input int atr_period = 14;


input double sl = 0.009;
input double tp = 0.020;
input double bet  = 0.1;
 

int    MACD_handle,ATR_handle;
CAccountInfo account ;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
       MACD_handle=iMACD(NULL,0,Fast,Slow,Sign,PRICE_CLOSE);
        if(MACD_handle==INVALID_HANDLE)  return(0);
        
            ATR_handle = iATR(NULL,0,atr_period);
    if(ATR_handle==INVALID_HANDLE) Print(" Failed to get handle of the ATR indicator");

   return(0);
  }
  


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
     {
    int Mybars=Bars(_Symbol,_Period);
      if(Mybars<250) 
        {
         Alert(" less than 250 bars on the chart, the Expert Advisor will exit");
         return;
        }
    static bool sell,buy;
      double Ind[2],Sig[3],ATR[];
      sell=false;
      buy=false;
      
      
         


        if(CopyBuffer(ATR_handle,0,0,3,ATR)<=0) return;
      if(CopyBuffer(MACD,0,1,2,Ind)<=0)return;
      if(CopyBuffer(MACD,1,1,3,Sig)<=0)return;
      

      ArraySetAsSeries(Ind,true);
      ArraySetAsSeries(Sig,true);
      ArraySetAsSeries(ATR,true);

       
 if  (!PositionSelect(_Symbol)) 
 {
      if(Ind[0]>0 && Ind[1]<0) buy =true;
      if(Ind[0]<0 && Ind[1]>0) sell =true;
      if(Ind[1]<0 && Sig[0]<Sig[1] && Sig[1]>Sig[2]) buy=true;
      if(Ind[1]>0 && Sig[0]>Sig[1] && Sig[1]<Sig[2]) sell  =true;
          if (buy || sell)
          {
            double no = 0 ;
            double lot = fixedFractional(sl);
          double tmp = 0 ;
            if (lot>5)
                   {
                       no=lot/4.99;
                        for (int i =0; i<=no ; i++)
                          { 
                                if (lot > 5)
                                    tmp = 5;
                                    else tmp = lot;
                                     
            				if (buy)  PlaceOrder(ORDER_TYPE_BUY,tmp);
            				else if (sell)PlaceOrder(ORDER_TYPE_SELL,tmp);
            				Sleep(1000);
            				if (i == 2) break;
            				lot = lot -5;
            				}
            			}
         			else
         			{
         				if (buy)  PlaceOrder(ORDER_TYPE_BUY,lot);
         				else if (sell)PlaceOrder(ORDER_TYPE_SELL,lot);
         			}
         	}
               
     }
   }   


bool PlaceOrder(long dir,double lot)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);


      if(dir == ORDER_TYPE_BUY)       
                    {
                       request.type   = ORDER_TYPE_BUY;
                       request.price  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                       request.action = TRADE_ACTION_DEAL;
                       request.symbol = _Symbol;
                       request.volume = lot;
                       request.sl = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5) - sl;
                       request.tp = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5) + tp;
                       request.type_filling=ORDER_FILLING_FOK;
                    }
                    else if (ORDER_TYPE_SELL)
                    {
                       request.type   = ORDER_TYPE_SELL;
                       request.price  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                       request.action = TRADE_ACTION_DEAL;
                       request.symbol = _Symbol;
                       request.volume = lot;
                       request.sl = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5) + sl;
                       request.tp = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5) - tp;
                       request.type_filling=ORDER_FILLING_FOK;               
  
                        
                    }
    if(!OrderSend(request,result) || result.deal==0)
        {
         Print(ResultRetcodeDescription(result.retcode));
         return(false);
        }
   return(true);
}



double fixedFractional(double pips )
{
   pips = pips *100000 ;
   double risk =  MathSqrt(account.FreeMargin()*pips*bet);
   double lot = -1 ;
    printf("el riesgo que queremos es: " + risk +" pips " + pips);
   lot = risk /pips ;
   return ((NormalizeDouble(lot,2)));
}




  string ResultRetcodeDescription(int retcode)
  {
   string str;
//---
   switch(retcode)
     {
      case TRADE_RETCODE_REQUOTE:
         str="Requote";
         break;
      case TRADE_RETCODE_REJECT:
         str="Request rejected";
         break;
      case TRADE_RETCODE_CANCEL:
         str="Request cancelled by trader";
         break;
      case TRADE_RETCODE_PLACED:
         str="Order placed";
         break;
      case TRADE_RETCODE_DONE:
         str="Request done";
         break;
      case TRADE_RETCODE_DONE_PARTIAL:
         str="Request done partially";
         break;
      case TRADE_RETCODE_ERROR:
         str="Common error";
         break;
      case TRADE_RETCODE_TIMEOUT:
         str="Request cancelled by timeout";
         break;
      case TRADE_RETCODE_INVALID:
         str="Invalid request";
         break;
      case TRADE_RETCODE_INVALID_VOLUME:
         str="Invalid volume in request";
         break;
      case TRADE_RETCODE_INVALID_PRICE:
         str="Invalid price in request";
         break;
      case TRADE_RETCODE_INVALID_STOPS:
         str="Invalid stop(s) request";
         break;
      case TRADE_RETCODE_TRADE_DISABLED:
         str="Trade is disabled";
         break;
      case TRADE_RETCODE_MARKET_CLOSED:
         str="Market is closed";
         break;
      case TRADE_RETCODE_NO_MONEY:
         str="No enough money";
         break;
      case TRADE_RETCODE_PRICE_CHANGED:
         str="Price changed";
         break;
      case TRADE_RETCODE_PRICE_OFF:
         str="No quotes for query processing";
         break;
      case TRADE_RETCODE_INVALID_EXPIRATION:
         str="Invalid expiration time in request";
         break;
      case TRADE_RETCODE_ORDER_CHANGED:
         str="Order state changed";
         break;
      case TRADE_RETCODE_TOO_MANY_REQUESTS:
         str="Too frequent requests";
         break;
      case TRADE_RETCODE_NO_CHANGES:
         str="No changes in request";
         break;
      case TRADE_RETCODE_SERVER_DISABLES_AT:
         str="Autotrading disabled by server";
         break;
      case TRADE_RETCODE_CLIENT_DISABLES_AT:
         str="Autotrading disabled by client terminal";
         break;
      case TRADE_RETCODE_LOCKED:
         str="Request locked for processing";
         break;
      case TRADE_RETCODE_FROZEN:
         str="Order or position frozen";
         break;
      case TRADE_RETCODE_INVALID_FILL:
         str="Invalid order filling type";
         break;
      case TRADE_RETCODE_CONNECTION:
         str="No connection with the trade server";
         break;
      case TRADE_RETCODE_ONLY_REAL:
         str="Operation is allowed only for live accounts";
         break;
      case TRADE_RETCODE_LIMIT_ORDERS:
         str="The number of pending orders has reached the limit";
         break;
      case TRADE_RETCODE_LIMIT_VOLUME:
         str="The volume of orders and positions for the symbol has reached the limit";
         break;
      default:
         str="Unknown result";
     }
//---
   return(str);
  }
  

    
    
    

