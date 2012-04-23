//+------------------------------------------------------------------+
//|  	                                   	         Price Action Test |
//|                                                    Andriy Moraru |
//|                                         http://www.earnforex.com |
//|            							                            2011 |
//+------------------------------------------------------------------+
#property copyright "www.EarnForex.com, 2011"
#property link      "http://www.earnforex.com"
#property version   "1.3"

#property description "Trades using trailing stop with reverse. Initial direction is random."
#property description " + Fixed ratio position sizing."
#property description " + Z-Score optimization."
#property description " + Multi-currency trading."
#property description " + ATC-compliant position sizing."
#property description " + works with ATC trading conditions."
#property description " + save & load for Virtual Trading variables."

#include <TradeATC__1.mqh>
#include <Trade/PositionInfo.mqh>

input string CurrencyPair1 = "EURAUD";
input string CurrencyPair2 = "EURUSD";

input ENUM_TIMEFRAMES TimeFrame1 = PERIOD_H1;
input ENUM_TIMEFRAMES TimeFrame2 = PERIOD_H1;

// Period of ATR
input int ATRper1 = 24;
input int ATRper2 = 24;

// Basic lot size
input double iLots1 = 3;
input double iLots2 = 3;

// Additional log output muting
input bool Mute1 = true; 	
input bool Mute2 = true;

// Tolerated slippage in pips, pips are fractional
input int Slippage1 = 100; 	
input int Slippage2 = 100;

// Implement Z-Score Optimization
input bool ZScoreOptimization1 = false;
input bool ZScoreOptimization2 = false;

// Text Strings
input string OrderComment = "Price Action Test";

int fh; // File handle

struct virtual_trading
{
      bool              TradeBlock;
      ENUM_POSITION_TYPE VirtualDirection;
      bool              VirtualOpen;
      double            VirtualOP;
      double            VirtualSL;
};

class CMCPriceAction
{
   private:
      bool              HaveLongPosition;
      bool              HaveShortPosition;
      bool              Initialized;
      void              GetPositionStates();
      void              ClosePrevious();           // Close previous position
      ENUM_POSITION_TYPE LastPosition;
      // Z-Score optimization
      bool              ZScore;
      virtual_trading   VirtualTrading;
      uint              number;                    // The number of this pair (used to store Virtual Trading data in the save file)
   
   protected:
      string            symbol;                    // Currency pair to trade 
      ENUM_TIMEFRAMES   timeframe;                 // Timeframe
      int               digits;                    // Number of digits after dot in the quote
      double            point;                     // Single point
      double            iLots;                     // Position size
      int               ATRper;                    // ATR Period
      int               myATR;                     // Indicator handle
      bool              Mute;                      // Mute the additional log output
      CTrade            Trade;                     // Trading object
      CPositionInfo     PositionInfo;              // Position Info object
      void              SaveFile();
      void              LoadFile();
      int               fh;                        
   
   public:
                        CMCPriceAction();               // Constructor
                       ~CMCPriceAction() { Deinit(); }  // Destructor
      bool              Init(string Pair, ENUM_TIMEFRAMES Timeframe, int ATR, double PositionSize, bool Muting, int Slip, bool ZScoreOpt, uint n);
      bool              Validated();
      void              AdjustSLTP(double SLparam);            // Trailing Stop function
      void              CheckEntry();                          // Main trading function
      void              Deinit();
};

//+------------------------------------------------------------------+
//| Constructor                                                     |
//+------------------------------------------------------------------+
CMCPriceAction::CMCPriceAction()
{
   Initialized = false;
}

//+------------------------------------------------------------------+
//| Performs object initialization                                   |
//+------------------------------------------------------------------+
bool CMCPriceAction::Init(string Pair, ENUM_TIMEFRAMES Timeframe, int ATR, double PositionSize, bool Muting, int Slip, bool ZScoreOpt, uint n)
{
   symbol = Pair;
   timeframe = Timeframe;
   digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   iLots = PositionSize;
   
   ZScore = ZScoreOpt;
   LastPosition = POSITION_TYPE_BUY;
   VirtualTrading.TradeBlock = false;
   VirtualTrading.VirtualOpen = false;
   VirtualTrading.VirtualOP = 0;
   VirtualTrading.VirtualSL = 0;
   number = n;

   if ((ZScore) && (FileIsExist("atc.txt"))) LoadFile();

   Trade.SetDeviationInPoints(Slip);

   ATRper = ATR;
   Mute = Muting;
   
   myATR = iATR(symbol, timeframe, ATRper);
   
   // Used to generate chart events on all used currency pairs' charts for this EA
   if(iCustom(symbol, PERIOD_M1, "MCSpy", ChartID(), 1) == INVALID_HANDLE)
   {
      Print("Error in setting of spy on ", symbol);
      return(false);
   }
   
   Initialized = true;

   Print(symbol, " initialized.");

   return(true);
}

//+------------------------------------------------------------------+
//| Object deinitialization                                          |
//+------------------------------------------------------------------+
CMCPriceAction::Deinit()
{
   Initialized = false;
   
   Print(symbol, " deinitialized.");
}

//+------------------------------------------------------------------+
//| Checks if everything initialized successfully                    |
//+------------------------------------------------------------------+
bool CMCPriceAction::Validated()
{
   return (Initialized);
}

//+------------------------------------------------------------------+
//| Saves Virtual Trading data to a file                             |
//+------------------------------------------------------------------+
void CMCPriceAction::SaveFile()
{
   FileSeek(fh, (number - 1) * sizeof(VirtualTrading), SEEK_SET);
   FileWriteStruct(fh, VirtualTrading, sizeof(VirtualTrading));
}

//+------------------------------------------------------------------+
//| Loads Virtual Trading data from a file                           |
//+------------------------------------------------------------------+
void CMCPriceAction::LoadFile()
{
   fh = FileOpen("atc.txt", FILE_READ|FILE_BIN);
   FileSeek(fh, (number - 1) * sizeof(VirtualTrading), SEEK_SET);
   FileReadStruct(fh, VirtualTrading, sizeof(VirtualTrading));
   FileClose(fh);
}

//+------------------------------------------------------------------+
//| Checks for entry to a trade                                      |
//+------------------------------------------------------------------+
void CMCPriceAction::CheckEntry()
{
   if (ZScore)
   {
      if (!VirtualTrading.TradeBlock)
      {
         // Looking back for 1 week, but in fact, 1 day would be enough
         HistorySelect(TimeCurrent() - 7 * 24 * 3600, TimeCurrent());
         int total = HistoryDealsTotal();
         for (int i = total - 1; i >= 0; i--)
         {
            ulong deal = HistoryDealGetTicket(i);
            if (deal > 0)
            {
               if (HistoryDealGetString(deal, DEAL_SYMBOL) == symbol)
               {
                  if (HistoryDealGetInteger(deal, DEAL_ENTRY) == DEAL_ENTRY_OUT)
                  {
                     if (HistoryDealGetDouble(deal, DEAL_PROFIT) > 0)
                     {
                        VirtualTrading.TradeBlock = true;
                        SaveFile();
                        if (!Mute) Print("Real trading blocked for ", symbol, " on: ", deal, " ", HistoryDealGetInteger(deal, DEAL_ENTRY), " ", HistoryDealGetDouble(deal, DEAL_PROFIT));
                     }
                  }
                  break;
               }
            }
         }
      }
      else if (VirtualTrading.VirtualOpen)
      {
         if (VirtualTrading.VirtualSL != 0) // Track stop-loss trigger
         {
            if (VirtualTrading.VirtualDirection == POSITION_TYPE_BUY)
            {
               double Bid = SymbolInfoDouble(symbol, SYMBOL_BID);
               if (Bid <= VirtualTrading.VirtualSL)
               {
                  if (!Mute) Print(symbol, " - Virtual SL Triggered.");
                  ClosePrevious();
               }
      
            }
            else if (VirtualTrading.VirtualDirection == POSITION_TYPE_SELL)
            {
             	double Ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
             	if (Ask >= VirtualTrading.VirtualSL)
             	{
             	   if (!Mute) Print(symbol, " - Virtual SL Triggered.");
             	   ClosePrevious();
             	}
            }
         }
      }
   }
   
   // Getting the ATR values
   double ATR[1];
   ArraySetAsSeries(ATR, true);
   if (CopyBuffer(myATR, 0, 0, 1, ATR) != 1) return;
   // You can uncomment this line if you want to use ATR-based position sizing
   //Lots = NormalizeDouble(0.01 * AccountInfoDouble(ACCOUNT_BALANCE) / (ATR[0] * 100000), 1);
   // Reverse-Martingale position sizing
   double Lots = iLots;//NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE) / 10000 * 1, 1);
   ATR[0] *= 3;

   if (ATR[0] <= (SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL) + SymbolInfoInteger(symbol, SYMBOL_SPREAD)) * point) ATR[0] = (SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL) + SymbolInfoInteger(symbol, SYMBOL_SPREAD)) * point;

  	// Check what position is currently open
 	GetPositionStates();
   
 	// Adjust SL and TP of the current position
 	if ((HaveLongPosition) || (HaveShortPosition)) AdjustSLTP(ATR[0]);
   else
	{
      double Ask, Bid;
   
   	// Buy condition
   	if (LastPosition == POSITION_TYPE_SELL)
   	{
  			for (int i = 0; i < 10; i++)
  			{
  		   	Ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  				Bid = SymbolInfoDouble(symbol, SYMBOL_BID);
  				// Bid and Ask are swapped to preserve the probabilities and decrease/increase profit/loss size
  		   	double SL = NormalizeDouble(Bid - ATR[0], digits);
  		   	
            if ((VirtualTrading.TradeBlock) && (ZScore)) // Virtual Entry
            {
               VirtualTrading.VirtualDirection = POSITION_TYPE_BUY;
               VirtualTrading.VirtualOpen = true;
               VirtualTrading.VirtualOP = Ask;
               VirtualTrading.VirtualSL = SL;
               SaveFile();
               if (!Mute) Print(symbol, " - Entered Virtual Long at ", VirtualTrading.VirtualOP, " with SL at", VirtualTrading.VirtualSL);
               return;
            }

  				Trade.PositionOpen(symbol, ORDER_TYPE_BUY, Lots, Ask, SL, 0);
  				Sleep(7000);
  				if ((Trade.ResultRetcode() != 10008) && (Trade.ResultRetcode() != 10009) && (Trade.ResultRetcode() != 10010))
  					Print(symbol, " - Long Position Open Return Code: ", Trade.ResultRetcodeDescription());
  				else return;
  			}
   	}
   	// Sell condition
   	else if (LastPosition == POSITION_TYPE_BUY)
   	{
  			for (int i = 0; i < 10; i++)
  			{
  		   	Ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  				Bid = SymbolInfoDouble(symbol, SYMBOL_BID);
  				// Bid and Ask are swapped to preserve the probabilities and decrease/increase profit/loss size
  		      double SL = NormalizeDouble(Ask + ATR[0], digits);

            if ((VirtualTrading.TradeBlock) && (ZScore)) // Virtual Entry
            {
               VirtualTrading.VirtualDirection = POSITION_TYPE_SELL;
               VirtualTrading.VirtualOpen = true;
               VirtualTrading.VirtualOP = Bid;
               VirtualTrading.VirtualSL = SL;
               SaveFile();
               if (!Mute) Print(symbol, " - Entered Virtual Short at ", VirtualTrading.VirtualOP, " with SL at", VirtualTrading.VirtualSL);
               return;
            }
   
  				Trade.PositionOpen(symbol, ORDER_TYPE_SELL, Lots, Bid, SL, 0);
  				Sleep(7000);
  				if ((Trade.ResultRetcode() != 10008) && (Trade.ResultRetcode() != 10009) && (Trade.ResultRetcode() != 10010))
  					Print("Short Position Open Return Code: ", Trade.ResultRetcodeDescription());
  				else return;
  			}
   	}
	}
}

//+------------------------------------------------------------------+
//| Check What Position is Currently Open										|
//+------------------------------------------------------------------+
void CMCPriceAction::GetPositionStates()
{
   if ((VirtualTrading.TradeBlock) && (ZScore)) // Virtual Check
   {
      if (VirtualTrading.VirtualOpen)
      {
         if (VirtualTrading.VirtualDirection == POSITION_TYPE_BUY)
         {
   			HaveLongPosition = true;
			   HaveShortPosition = false;
         }
         else if (VirtualTrading.VirtualDirection == POSITION_TYPE_SELL)
         {
			   HaveLongPosition = false;
   			HaveShortPosition = true;
         }
      }
      else
      {
		   HaveLongPosition = false;
		   HaveShortPosition = false;
		}

      return;
   }

	// Is there a position on this currency pair?
	if (PositionInfo.Select(symbol))
	{
		if (PositionInfo.PositionType() == POSITION_TYPE_BUY)
		{
  			HaveLongPosition = true;
  			HaveShortPosition = false;
		}
		else if (PositionInfo.PositionType() == POSITION_TYPE_SELL)
		{ 
  			HaveLongPosition = false;
  			HaveShortPosition = true;
		}
   	if (HaveLongPosition) LastPosition = POSITION_TYPE_BUY;
   	else if (HaveShortPosition) LastPosition = POSITION_TYPE_SELL;
	}
	else
	{
		HaveLongPosition = false;
		HaveShortPosition = false;
	}
}

//+------------------------------------------------------------------+
//| Close Open Position (Used only in virtual mode)						|
//+------------------------------------------------------------------+
void CMCPriceAction::ClosePrevious()
{
   if ((VirtualTrading.TradeBlock) && (ZScore)) // Virtual Exit
   {
      if (VirtualTrading.VirtualOpen)
      {
         if (VirtualTrading.VirtualDirection == POSITION_TYPE_BUY)
         {
            double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
          	if (Bid < VirtualTrading.VirtualOP) VirtualTrading.TradeBlock = false;
            LastPosition = POSITION_TYPE_BUY;
            if (!Mute) Print(symbol, " - Closed Virtual Long at ", Bid, " with Open at", VirtualTrading.VirtualOP);
         }
         else if (VirtualTrading.VirtualDirection == POSITION_TYPE_SELL)
         {
          	double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
            if (Ask > VirtualTrading.VirtualOP) VirtualTrading.TradeBlock = false;
            LastPosition = POSITION_TYPE_SELL;
            if (!Mute) Print(symbol, " - Closed Virtual Short at ", Ask, " with Open at", VirtualTrading.VirtualOP);
         }
         VirtualTrading.VirtualDirection = -1;
         VirtualTrading.VirtualOpen = false;
         VirtualTrading.VirtualOP = 0;
         VirtualTrading.VirtualSL = 0;
         SaveFile();
   		HaveLongPosition = false;
   		HaveShortPosition = false;
      }
      return;
   }
}

//+------------------------------------------------------------------+
//| Adjust Stop-Loss and TakeProfit of the Open Position					|
//+------------------------------------------------------------------+
void CMCPriceAction::AdjustSLTP(double SLparam)
{
   if ((VirtualTrading.TradeBlock) && (ZScore)) // Virtual Trailing Stop
   {
      if (VirtualTrading.VirtualOpen)
      {
         if (VirtualTrading.VirtualDirection == POSITION_TYPE_BUY)
         {
   		   double Bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   			double SL = NormalizeDouble(Bid - SLparam, digits);
   			if (SL > VirtualTrading.VirtualSL) VirtualTrading.VirtualSL = SL;
   			SaveFile();
         }
         else if (VirtualTrading.VirtualDirection == POSITION_TYPE_SELL)
         {
   			double Ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   			double SL = NormalizeDouble(Ask + SLparam, digits);
   			if ((SL < VirtualTrading.VirtualSL) || (VirtualTrading.VirtualSL == 0)) VirtualTrading.VirtualSL = SL;
   			SaveFile();
         }
      }   
      return;
   }

	// Is there a position on this currency pair?
	if (PositionInfo.Select(symbol))
	{
		if (PositionInfo.PositionType() == POSITION_TYPE_BUY)
		{
		   double Bid = SymbolInfoDouble(symbol, SYMBOL_BID);
			double SL = NormalizeDouble(Bid - SLparam, digits);
			double TP = NormalizeDouble(PositionInfo.TakeProfit(), digits);
			if (SL > NormalizeDouble(PositionInfo.StopLoss(), digits))
			{
				for (int i = 0; i < 10; i++)
				{
					Trade.PositionModify(symbol, SL, TP);
					if ((Trade.ResultRetcode() != 10008) && (Trade.ResultRetcode() != 10009) && (Trade.ResultRetcode() != 10010))
						Print("Long Position Modify Return Code: ", Trade.ResultRetcodeDescription());
					else return;
				}
			}
		}
		else if (PositionInfo.PositionType() == POSITION_TYPE_SELL)
		{ 
			double Ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
			double SL = NormalizeDouble(Ask + SLparam, digits);
			double TP = NormalizeDouble(PositionInfo.TakeProfit(), digits);
			if (SL < NormalizeDouble(PositionInfo.StopLoss(), digits))
			{
				for (int i = 0; i < 10; i++)
				{
					Trade.PositionModify(symbol, SL, TP);
					if ((Trade.ResultRetcode() != 10008) && (Trade.ResultRetcode() != 10009) && (Trade.ResultRetcode() != 10010))
						Print("Short Position Modify Return Code: ", Trade.ResultRetcodeDescription());
					else return;
				}
			}
		}
	}
}

// Global variables
CMCPriceAction TradeObject1, TradeObject2;

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("Initialization...");
	// Initialize all objects
   if (CurrencyPair1 != "")
      if (!TradeObject1.Init(CurrencyPair1, TimeFrame1, ATRper1, iLots1, Mute1, Slippage1, ZScoreOptimization1, 1))
      {
         TradeObject1.Deinit();
         return(-1);
      }
   if (CurrencyPair2 != "")
      if (!TradeObject2.Init(CurrencyPair2, TimeFrame2, ATRper2, iLots2, Mute2, Slippage2, ZScoreOptimization2, 2))
      {
         TradeObject2.Deinit();
         return(-1);
      }

   fh = FileOpen("atc.txt", FILE_WRITE|FILE_BIN); // For saving
   //Print("File Handle: ", fh);
   return(0);
}

void OnDeinit(const int reason)
{
   FileClose(fh);
}

//+------------------------------------------------------------------+
//| Triggers on events generated by MCSpy indicators                 |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // event id:
                  const long&   lparam, // chart period
                  const double& dparam, // price
                  const string& sparam  // symbol
                 )
{
   if (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == false) return;
   if (AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) == false) return;
   if (AccountInfoInteger(ACCOUNT_TRADE_EXPERT) == false) return;
   if (SymbolInfoInteger(sparam, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED) return;

   // Got signal from this currency pair chart? Did we even set this currency pair to trade with it?
   if ((sparam == CurrencyPair1) && (CurrencyPair1 != ""))
   {
      // Have the trade objects initialized?
      if (!TradeObject1.Validated()) return;
      // Main trading function
      TradeObject1.CheckEntry();
   }
   else if ((sparam == CurrencyPair2) && (CurrencyPair2 != ""))
   {
      if (!TradeObject2.Validated()) return;
      TradeObject2.CheckEntry();
   }
}

//+------------------------------------------------------------------+

