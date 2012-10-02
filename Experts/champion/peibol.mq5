
input string            Symb1 = "AUDCAD";
input int                Per1 = 100;                     //periodo de la EMA
input ENUM_APPLIED_PRICE ApPrice1 = PRICE_CLOSE;
input ENUM_MA_METHOD MaMethod1    = MODE_SMA;
input int             StLoss1 = 0;
input int           TkProfit1 = 0;
input double            Lots1 = 0.1;
input int           Slippage1 = 30;
//+-----------------------------------+
input string            Symb2 = "AUDNZD";
input int                Per2 = 100;                       //periodo de la EMA
input ENUM_APPLIED_PRICE ApPrice2 = PRICE_CLOSE;
input ENUM_MA_METHOD MaMethod2    = MODE_SMA;
input int             StLoss2 = 0;
input int           TkProfit2 = 0;
input double            Lots2 = 0.1;
input int           Slippage2 = 30;


//+------------------------------------------------------------------+
//| Custom TradeSignalCounter() function                             |
//+------------------------------------------------------------------+
bool TradeSignalCounter(int Number,
                        string Symbol_,
                        int period,
                        ENUM_APPLIED_PRICE ApPrice,
                        ENUM_MA_METHOD MaMethod,
                        bool &UpSignal[],
                        bool &DnSignal[],
                        bool &UpStop[],
                        bool &DnStop[])
  {

   static int Size_=0;
   static int Handle[];
   static int Recount[],MinBars[];
  
   double SMA[4],dsma1,dsma2;

//--- initialization
   if(Number+1>Size_) // Initalization only at first start
     {
      Size_=Number+1;

      //---- Resize arrays
      ArrayResize(Handle,Size_);
      ArrayResize(Recount,Size_);
      ArrayResize(MinBars,Size_);
      
      ArrayInitialize(Handle,0);
      ArrayInitialize(Recount,0);
      ArrayInitialize(MinBars,0);

      //---- determine minimal number of bars, sufficient for the calculation
      MinBars[Number]=3*period;

      //---- fill arrays with initial values
      DnSignal[Number] = false;
      UpSignal[Number] = false;
      DnStop  [Number] = false;
      UpStop  [Number] = false;

      //---- set as timeseries
      ArraySetAsSeries(SMA,true);

      //--- get handle of the indicator
      Handle[Number]=iMA(Symbol_,0,period,0,MODE_SMA,ApPrice);
     }


   //printf("Symbol_ " + Symbol_ );
 
//--- check the number of bars
   if(Bars(Symbol_,0)<MinBars[Number])return(true);
//printf("Symbol_1 " + Symbol_ );
//--- get trade signals
   if(IsNewBar(Number,Symbol_,0) || Recount[Number]) // Only at new bar or in the case of copy failed
     {
     //printf("Symbol_2 " + Symbol_ );
      DnSignal[Number] = false;
      UpSignal[Number] = false;
      DnStop  [Number] = false;
      UpStop  [Number] = false;

      //--- using indicator handles, copying the values of the indicator buffer
      //--- to special static array
      if(CopyBuffer(Handle[Number],0,0,4,SMA)<0)
        {
         Recount[Number]=true; // we haven't a data yet, so go here at new tick

         return(false); // return from the TradeSignalCounter() without trading signals
        }

      //---- All data from the indicator's buffers have been copied successfully
      Recount[Number]=false; // don't go here until the new bar

      dsma2 = NormalizeDouble(SMA[2] - SMA[3], _Digits);      // MA for 2-3
      dsma1 = NormalizeDouble(SMA[1] - SMA[2], _Digits);      // MA for 1-2

      //---- Determine entry signals
      if(dsma2 > 0 && dsma1 > 0) DnSignal[Number] = true;    // buy if MA is falling at 1-2 and 2-3
      if(dsma2 < 0 && dsma1 < 0) UpSignal[Number] = true;    // buy if MA is growing at 1-2 and 2-3

      //---- Determine exist signals
      if(dsma1 < 0) DnStop[Number] = true;                   // sell if MA is growing at 1-2
      if(dsma1 > 0) UpStop[Number] = true;                   // sell if MA is falling at 1-2
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Custom TradePerformer() function                                 |
//+------------------------------------------------------------------+
bool TradePerformer(int    Number,
                    string Symbol_,
                    int    StLoss,
                    int    TkProfit,
                    double Lots,
                    int    Slippage,
                    bool  &UpSignal[],
                    bool  &DnSignal[],
                    bool  &UpStop[],
                    bool  &DnStop[])
  {


//---- Close opened positions
   if(UpStop[Number])BuyPositionClose(Symbol_,Slippage);
   if(DnStop[Number])SellPositionClose(Symbol_,Slippage);

//---- Open new positions
   if(UpSignal[Number])
      if(BuyPositionOpen(Symbol_,Slippage,Lots,StLoss,TkProfit))
         UpSignal[Number]=false; //We will not use the signal on this bar!
//----  
   if(DnSignal[Number])
      if(SellPositionOpen(Symbol_,Slippage,Lots,StLoss,TkProfit))
         DnSignal[Number]=false; //We will not use the signal on this bar!
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Open buy position.                                               |
//| INPUT:  symbol    -symbol for fish,                              |
//|         deviation -deviation for price close.                    |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool BuyPositionOpen(const string symbol,
                     ulong deviation,
                     double volume,
                     int StopLoss,
                     int Takeprofit)
  {
//--- declare structures for trade request
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

//--- is there any opened position?
   if(!PositionSelect(symbol))
     {
      //--- initialize the MqlTradeRequest structure to open BUY position
      request.type   = ORDER_TYPE_BUY;
      request.price  = SymbolInfoDouble(symbol, SYMBOL_ASK);
      request.action = TRADE_ACTION_DEAL;
      request.symbol = symbol;
      request.volume = Money_M();
      request.sl = 0;
      request.tp = 0;
      request.deviation=(deviation==ULONG_MAX) ? deviation : deviation;
      request.type_filling=ORDER_FILLING_FOK;
      //---
      string word="";
      StringConcatenate(word,
                        "<<< ============ BuyPositionOpen():   Open Buy position on ",
                        symbol," ============ >>>");
      Print(word);

      //--- open BUY position and check trade server return code
      if(!OrderSend(request,result) || result.deal==0)
        {
         Print(ResultRetcodeDescription(result.retcode));
         return(false);
        }
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Open sell position.                                              |
//| INPUT:  symbol    -symbol for fish,                              |
//|         deviation -deviation for price close.                    |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool SellPositionOpen(const string symbol,
                      ulong deviation,
                      double volume,
                      int StopLoss,
                      int Takeprofit)
  {
//--- declare structures for trade request
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

//--- is there any opened position?
   if(!PositionSelect(symbol))
     {
      //--- Initialize the MqlTradeRequest structure to open SELL position
      request.type   = ORDER_TYPE_SELL;
      request.price  = SymbolInfoDouble(symbol, SYMBOL_BID);
      request.action = TRADE_ACTION_DEAL;
      request.symbol = symbol;
      request.volume = Money_M();
      request.sl = 0;
      request.tp = 0;
      request.deviation=(deviation==ULONG_MAX) ? deviation : deviation;
      request.type_filling=ORDER_FILLING_FOK;

      //---
      string word="";
      StringConcatenate(word,
                        "<<< ============ SellPositionOpen():   Open Sell position on ",
                        symbol," ============ >>>");
      Print(word);

      //--- open SELL position and check trade server return code
      if(!OrderSend(request,result) || result.deal==0)
        {
         Print(ResultRetcodeDescription(result.retcode));
         return(false);
        }
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Close specified opened buy position.                             |
//| INPUT:  symbol    -symbol for fish,                              |
//|         deviation -deviation for price close.                    |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool BuyPositionClose(const string symbol,ulong deviation)
  {
//---
//--- declare a variables for trade request
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

//--- check opened BUY position
   if(PositionSelect(symbol))
     {
      if(PositionGetInteger(POSITION_TYPE)!=POSITION_TYPE_BUY) return(false);
     }
   else  return(false);

//--- Prepare the structure of MqlTradeRequest type for BUY position close
   request.type   = ORDER_TYPE_SELL;
   request.price  = SymbolInfoDouble(symbol, SYMBOL_BID);
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = PositionGetDouble(POSITION_VOLUME);
   request.sl = 0.0;
   request.tp = 0.0;
   request.deviation=(deviation==ULONG_MAX) ? deviation : deviation;
   request.type_filling=ORDER_FILLING_FOK;
//---
   string word="";
   StringConcatenate(word,
                     "<<< ============ BuyPositionClose():   Close Buy position on ",
                     symbol," ============ >>>");
   Print(word);

//--- send order to close position to trade server
   if(!OrderSend(request,result))
     {
      Print(ResultRetcodeDescription(result.retcode));
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Close specified sell opened position.                            |
//| INPUT:  symbol    -symbol for fish,                              |
//|         deviation -deviation for price close.                    |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool SellPositionClose(const string symbol,ulong deviation)
  {
//---
//--- declare a variables for trade request
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

//--- check opened Sell position
   if(PositionSelect(symbol))
     {
      if(PositionGetInteger(POSITION_TYPE)!=POSITION_TYPE_SELL)return(false);
     }
   else return(false);

//--- prepare the structure of MqlTradeRequest type for SELL position close
   request.type   = ORDER_TYPE_BUY;
   request.price  = SymbolInfoDouble(symbol, SYMBOL_ASK);
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = PositionGetDouble(POSITION_VOLUME);
   request.sl = 0.0;
   request.tp = 0.0;
   request.deviation=(deviation==ULONG_MAX) ? deviation : deviation;
   request.type_filling=ORDER_FILLING_FOK;
//---
   string word="";
   StringConcatenate(word,
                     "<<< ============ SellPositionClose():   Close Sell position on",
                     symbol," ============ >>>");
   Print(word);

//--- send order to close position to trade server
   if(!OrderSend(request,result))
     {
      Print(ResultRetcodeDescription(result.retcode));
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- 

//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
//---   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- 
//--- declare arrays for trading signals
   static bool UpSignal[2],DnSignal[2],UpStop[2],DnStop[2];


   TradeSignalCounter(0,Symb1,Per1,ApPrice1,MaMethod1,UpSignal,DnSignal,UpStop,DnStop);
   TradeSignalCounter(1,Symb2,Per2,ApPrice2,MaMethod2,UpSignal,DnSignal,UpStop,DnStop);

   //printf("Symbol_  after" + Symb1 );


   TradePerformer(0,Symb1,StLoss1,TkProfit1,Lots1,Slippage1,UpSignal,DnSignal,UpStop,DnStop);
   TradePerformer(1,Symb2,StLoss2,TkProfit2,Lots2,Slippage2,UpSignal,DnSignal,UpStop,DnStop);

//---   
  }
//+------------------------------------------------------------------+
//| IsNewBar() function                                              |
//+------------------------------------------------------------------+
bool IsNewBar(int Number,string symbol,ENUM_TIMEFRAMES timeframe)
  {
//---
   static datetime Told[];
   datetime Tnew[1];
//--- declare a variable for array sizes
   static int Size_=0;

//--- resize arrrays
   if(Number+1>Size_)
     {
      uint size=Number+1;
      //----
      if(ArrayResize(Told,size)==-1)
        {
         string word="";
         StringConcatenate(word,"IsNewBar( ",Number,
                           " ): Error!!! Array resize failed!!!");
         Print(word);
         //----          
         int error=GetLastError();
         ResetLastError();
         if(error>4000)
           {
            StringConcatenate(word,"IsNewBar( ",Number," ): Error code ",error);
            Print(word);
           }
         //----                                                                                                                                                                                                  
         Size_=-2;
         return(false);
        }
     }

   CopyTime(symbol,timeframe,0,1,Tnew);
   if(Tnew[0]!=Told[Number])
     {
      Told[Number]=Tnew[0];
      return(true);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Get the retcode value as string.                                 |
//| INPUT:  no.                                                      |
//| OUTPUT: the retcode value as string.                             |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//| Returns volume of the position                                   |
//+------------------------------------------------------------------+
double Money_M()
  {
   double Lots=AccountInfoDouble(ACCOUNT_FREEMARGIN)/100000*10;
   Lots=MathMin(5,MathMax(0.1,Lots));
   if(Lots<0.1)
      Lots=NormalizeDouble(Lots,2);
   else
     {
      if(Lots<1) Lots=NormalizeDouble(Lots,1);
      else       Lots=NormalizeDouble(Lots,0);
     }
   return(Lots);
  }
