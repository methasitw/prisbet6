//+------------------------------------------------------------------+
//|                                                          PyR.mqh |
//|                                                           hippie |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "hippie"
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//------------------------------------------------------------------	
// Pyr Position
//------------------------------------------------------------------ 

#include <utilsv11\RiskManagement.mqh>



class PyR   
  {
  
protected:
//Abandon faith in yourself. Have faith only in the system. 
	
   int               Bands_handle_PYR, EMAFastMaHandle_PYR, EMASlowMaHandle_PYR;
   double      		Base[], Upper[],  Lower[];     //  BASE_LINE, UPPER_BAND and LOWER_BAND  of iBands
   double      		FastEma[],SlowEma[] ;			// EMA lines
   string m_smb ;
    bool m_bInit;
     CSymbolInfo       m_symbol;              // symbol parameters
     
    RiskManagement rm;
    
   public: 
   void              PyR();
	void             ~PyR();
	virtual bool      Init(long magic,string smb,ENUM_TIMEFRAMES tf); // initialization
	 virtual bool     Main() ;
	 
 	virtual long      	CheckSignalPyr(long type, bool bEntry);            // check signal
   virtual long         CheckDistance(long type, bool bEntry);
   virtual double LastDealOpenPrice();

  };
    
    
    void PyR::PyR() { }
//------------------------------------------------------------------	~HAL
void PyR::~PyR()
  {
   IndicatorRelease(Bands_handle_PYR); // delete indicators
   IndicatorRelease(EMAFastMaHandle_PYR); 
   IndicatorRelease(EMASlowMaHandle_PYR); 
  }
  
  bool  PyR::Init(long magic,string smb,ENUM_TIMEFRAMES tf)
  {
   	//--- creation of the indicator iBands
   	m_smb = smb;
   	 m_symbol.Name(m_smb);                  // initialize symbol
   	if (!rm.Init(0,m_smb,tf)) return(false);  // initialize object RiskManagement
   	
   	  Bands_handle_PYR=iBands(NULL,periodBBPyr,bands_periodPyr,bands_shiftPyr,deviationPyr,PRICE_CLOSE);
   	  EMAFastMaHandle_PYR=iMA(NULL,periodEMAPyr,InpFastEMAPyr,0,MODE_EMA,PRICE_CLOSE);
   	  EMASlowMaHandle_PYR=iMA(NULL,periodEMAPyr,InpSlowEMAPyr,0,MODE_EMA,PRICE_CLOSE);

	//--- report if there was an error in object creation
	   if(Bands_handle_PYR<0 || EMAFastMaHandle_PYR < 0 || EMASlowMaHandle_PYR < 0  )
		 {
		  printf(__FUNCTION__+"The creation of indicator has failed: Runtime error = " + GetLastError());
		  return(-1);
		 }

	m_bInit=true; return(true);                    // "trade allowed"
  }
  
    bool PyR::Main() // Main module
  {

   if(!m_bInit) return(false);
   if(!rm.Main()) return(false); // call function of parent class
   if(!MQL5InfoInteger(MQL5_TRADE_ALLOWED) || !TerminalInfoInteger(TERMINAL_CONNECTED))
      return(false);                            // if trade is not possible, then exit
   m_symbol.Refresh(); m_symbol.RefreshRates(); // update symbol parameters
   return(true);
  }
  
  //------------------------------------------------------------------	
// calculate the distance necessary to process a new deal
//------------------------------------------------------------------ 
  long PyR::CheckDistance(long type, bool bEntry)
{   
      double atr,cop,apr;
       

         atr = rm.getN();                                                            // numero de points que tiene que distanciarse
        // cop = rm.ea.NormalDbl(PositionGetDouble(POSITION_PRICE_OPEN));             // precio de apertura de posicion
         cop = LastDealOpenPrice();
         apr = rm.ea.BasePrice( type);                                             // precio objetivo actual

        if( cop + atr <  rm.ea.BasePrice( type))      
            {  
                 return(bEntry ? ORDER_TYPE_BUY:ORDER_TYPE_SELL); 
           }
       else if( cop - atr >  rm.ea.BasePrice( type))
          {       
               return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for sell
          }
         return(WRONG_VALUE);
}
//------------------------------------------------------------------	
// Las deal open price to calculate the distance necessary to process a new deal
//------------------------------------------------------------------ 
double PyR::LastDealOpenPrice()
  {
   uint pos_total=0;
   uint total=0;
   long pos_id=0;
   ulong HTicket=0;
   double price=0;
   pos_total=PositionsTotal();
  
   if(pos_total>0)
     {

      if(PositionSelect(Symbol())) // continue if open position is for chart symbol and order type
        {
         pos_id=(ENUM_POSITION_PROPERTY_INTEGER)PositionGetInteger(POSITION_IDENTIFIER);
         HistorySelectByPosition(pos_id);
         total=HistoryDealsTotal();
         HTicket=HistoryDealGetTicket(total-1); // get ticket number for last deal in position
        
         if(HTicket>0)
            price=HistoryDealGetDouble(HTicket,DEAL_PRICE);

         return(price);
        }

     }
   return(0);
  }

//------------------------------------------------------------------	
// Check Signal
//------------------------------------------------------------------ 
long PyR::CheckSignalPyr(long type, bool bEntry)
  {  
      if(!GetBandsBuffers(Bands_handle_PYR,0,90,Base,Upper,Lower,true)) return (-1);
           if( rm.ea.BasePrice( ORDER_TYPE_BUY) < Lower[0]   )
               {  
                     return(bEntry ? ORDER_TYPE_BUY:ORDER_TYPE_SELL);
               }

          else  if(  rm.ea.BasePrice( ORDER_TYPE_SELL)  > Upper[0])
                   {  
                        return(bEntry ? ORDER_TYPE_SELL:ORDER_TYPE_BUY);// condition for buy
                   }

   return(WRONG_VALUE);
  }



  