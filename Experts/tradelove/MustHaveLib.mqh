//+------------------------------------------------------------------+
//|                                                  MustHaveLib.mqh |
//+------------------------------------------------------------------+
string              fn;                  // File name
int                 handle;              // The link to the file being opened
string              f;                   // The log string written to the file
string              s="EURUSD";          // Pair
ENUM_TIMEFRAMES     tf=PERIOD_D1;        // Timeframe
MqlDateTime         dt;                  // Date-time as a structure instead of a solid int-digit
datetime            d[];                 // Date-time as int-digit
double              o[];                 // Openings
double              h[];                 // Highs
double              l[];                 // Lows
double              c[];                 // Closings
long                v[];                 // Actual volumes
datetime            prevBT[1],curBT[1];  // Bar beginning time in a numeric format
MqlDateTime         prevT,curT;          // Bar beginning time in a structure format
MqlTradeRequest     request;             // Trade request
MqlTradeCheckResult check;               // Trade request verification 
MqlTradeResult      result;              // Trade request result
double              maxBalance;          // Maximum balance
//+------------------------------------------------------------------+
//|  isNewBars()                                                     |
//|  Define whether a new bar has opened                             |
//+------------------------------------------------------------------+
bool isNewBars()
  {
   CopyTime(s,tf,0,1,curBT);
   TimeToStruct(curBT[0],curT);
   if(tf==PERIOD_M1||
      tf==PERIOD_M2||
      tf==PERIOD_M3||
      tf==PERIOD_M4||
      tf==PERIOD_M5||
      tf==PERIOD_M6||
      tf==PERIOD_M10||
      tf==PERIOD_M12||
      tf==PERIOD_M15||
      tf==PERIOD_M20||
      tf==PERIOD_M30)
      if(curT.min!=prevT.min)
        {
         prevBT[0]=curBT[0];
         TimeToStruct(prevBT[0],prevT);
         return(true);
        };
   if(tf==PERIOD_H1||
      tf==PERIOD_H2||
      tf==PERIOD_H3||
      tf==PERIOD_H4||
      tf==PERIOD_H6||
      tf==PERIOD_H8||
      tf==PERIOD_M12)
      if(curT.hour!=prevT.hour)
        {
         prevBT[0]=curBT[0];
         TimeToStruct(prevBT[0],prevT);
         return(true);
        };
   if(tf==PERIOD_D1||
      tf==PERIOD_W1)
      if(curT.day!=prevT.day)
        {
         prevBT[0]=curBT[0];
         TimeToStruct(prevBT[0],prevT);
         return(true);
        };
   if(tf==PERIOD_MN1)
      if(curT.mon!=prevT.mon)
        {
         prevBT[0]=curBT[0];
         TimeToStruct(prevBT[0],prevT);
         return(true);
        };
   return(false);
  }
//+------------------------------------------------------------------+
//| InitRelDD()                                                      |
//+------------------------------------------------------------------+
void InitRelDD()
  {
   ulong DealTicket;
   double curBalance;
   prevBT[0]=D'2000.01.01 00:00:00';
   TimeToStruct(prevBT[0],prevT);
   curBalance=AccountInfoDouble(ACCOUNT_BALANCE);
   maxBalance=curBalance;
   HistorySelect(D'2000.01.01 00:00:00',TimeCurrent());
   for(int i=HistoryDealsTotal();i>0;i--)
     {
      DealTicket=HistoryDealGetTicket(i);
      curBalance=curBalance+HistoryDealGetDouble(DealTicket,DEAL_PROFIT);
      if(curBalance>maxBalance) maxBalance=curBalance;
     }
  }
//+------------------------------------------------------------------+
//| GetRelDD()                                                       |
//+------------------------------------------------------------------+
double GetRelDD()
  {
   if(AccountInfoDouble(ACCOUNT_BALANCE)>maxBalance) maxBalance=AccountInfoDouble(ACCOUNT_BALANCE);
   return((maxBalance-AccountInfoDouble(ACCOUNT_BALANCE))/maxBalance);
  }
//+------------------------------------------------------------------+
//| GetPossibleLots()                                                |
//+------------------------------------------------------------------+
double GetPossibleLots()
  {
   request.volume=1.0;
   if(request.type==ORDER_TYPE_SELL) request.price=SymbolInfoDouble(s,SYMBOL_BID); else request.price=SymbolInfoDouble(s,SYMBOL_ASK);
   OrderCheck(request,check);
   return(NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN)/check.margin,2));
  }
//+------------------------------------------------------------------+
//| ClosePosition()                                                  |
//+------------------------------------------------------------------+
void ClosePosition()
  {
   request.action=TRADE_ACTION_DEAL;
   request.symbol=PositionGetSymbol(0);
   if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) request.type=ORDER_TYPE_SELL; else request.type=ORDER_TYPE_BUY;
   request.type_filling=ORDER_FILLING_AON;
   if(SymbolInfoInteger(PositionGetSymbol(0),SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_REQUEST||
      SymbolInfoInteger(PositionGetSymbol(0),SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_INSTANT)
     {
      request.sl=NULL;
      request.tp=NULL;
      request.deviation=100;
     }
   while(PositionsTotal()>0)
     {
      request.volume=NormalizeDouble(MathMin(PositionGetDouble(POSITION_VOLUME),SymbolInfoDouble(PositionGetSymbol(0),SYMBOL_VOLUME_MAX)),2);
      if(SymbolInfoInteger(PositionGetSymbol(0),SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_REQUEST||
         SymbolInfoInteger(PositionGetSymbol(0),SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_INSTANT)
        {
         if(request.type==ORDER_TYPE_SELL) request.price=SymbolInfoDouble(s,SYMBOL_BID); else request.price=SymbolInfoDouble(s,SYMBOL_ASK);
        }
      OrderSend(request,result);
      Sleep(10000);
     }
  }
//+------------------------------------------------------------------+
//| OpenPosition()                                                   |
//+------------------------------------------------------------------+
void OpenPosition()
  {
   double vol;
   request.action=TRADE_ACTION_DEAL;
   request.symbol=s;
   request.type_filling=ORDER_FILLING_AON;
   if(SymbolInfoInteger(s,SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_REQUEST||
      SymbolInfoInteger(s,SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_INSTANT)
     {
      request.sl=NULL;
      request.tp=NULL;
      request.deviation=100;
     }
   vol=MathFloor(AccountInfoDouble(ACCOUNT_FREEMARGIN)*optF*AccountInfoInteger(ACCOUNT_LEVERAGE)/(SymbolInfoDouble(s,SYMBOL_TRADE_CONTRACT_SIZE)*SymbolInfoDouble(s,SYMBOL_VOLUME_STEP)))*SymbolInfoDouble(s,SYMBOL_VOLUME_STEP);
   vol=MathMax(vol,SymbolInfoDouble(s,SYMBOL_VOLUME_MIN));
   vol=MathMin(vol,GetPossibleLots()*0.95);
   if(SymbolInfoDouble(s,SYMBOL_VOLUME_LIMIT)!=0) vol=NormalizeDouble(MathMin(vol,SymbolInfoDouble(s,SYMBOL_VOLUME_LIMIT)),2);
   vol=NormalizeDouble(MathMin(vol,SymbolInfoDouble(s,SYMBOL_VOLUME_MAX)),2);
   request.volume=vol;
   while(PositionSelect(s)==false)
     {
      if(SymbolInfoInteger(s,SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_REQUEST||
         SymbolInfoInteger(s,SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_INSTANT)
        {
         if(request.type==ORDER_TYPE_SELL) request.price=SymbolInfoDouble(s,SYMBOL_BID); else request.price=SymbolInfoDouble(s,SYMBOL_ASK);
        }
      OrderSend(request,result);
      Sleep(10000);
      PositionSelect(s);
     }
   while(PositionGetDouble(POSITION_VOLUME)<vol)
     {
      request.volume=NormalizeDouble(MathMin(vol-PositionGetDouble(POSITION_VOLUME),SymbolInfoDouble(s,SYMBOL_VOLUME_MAX)),2);
      if(SymbolInfoInteger(PositionGetSymbol(0),SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_REQUEST||
         SymbolInfoInteger(PositionGetSymbol(0),SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_INSTANT)
        {
         if(request.type==ORDER_TYPE_SELL) request.price=SymbolInfoDouble(s,SYMBOL_BID); else request.price=SymbolInfoDouble(s,SYMBOL_ASK);
        }
      OrderSend(request,result);
      Sleep(10000);
      PositionSelect(s);
     }
  }
//+------------------------------------------------------------------+
