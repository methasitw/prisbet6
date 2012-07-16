//+------------------------------------------------------------------------------+
//|                                                      GetIndicatorBuffers.mqh |
//|                                                             Copyright DC2008 |
//|                                                          http://www.mql5.com |
//+------------------------------------------------------------------------------+
#property copyright "DC2008"
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------------------+
//| Copies values of the indicator to the buffer                                 |
//+------------------------------------------------------------------------------+



bool CopyBufferAsSeries(
                        int handle,      // handle
                        int bufer,       // buffer number
                        int start,       // start from
                        int number,      // number of elements to copy
                        bool asSeries,   // is as series
                        double &M[]      // target array for data
                        )
  {
//--- filling M with current values of the indicator
   if(CopyBuffer(handle,bufer,start,number,M)<=0) return(false);
//--- setting ordering for M
//--- если asSeries=true, the indexation of M as timeseries
//--- если asSeries=false, the indexation of M as default
   ArraySetAsSeries(M,asSeries);
//---
   return(true);
  }
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator ADX to the arrays                         |
//+------------------------------------------------------------------------------+
bool GetADXBuffers(int ADX_handle,
                   int start,
                   int number,
                   double &Main[],
                   double &PlusDI[],
                   double &MinusDI[],
                   bool asSeries=true  // as series
                   )
  {
//--- Filling the array Main with the current values of MAIN_LINE
   if(!CopyBufferAsSeries(ADX_handle,0,start,number,asSeries,Main)) return(false);
//--- Filling the array PlusDI with the current values of PLUSDI_LINE
   if(!CopyBufferAsSeries(ADX_handle,1,start,number,asSeries,PlusDI)) return(false);
//--- Filling the array MinusDI with the current values of MINUSDI_LINE
   if(!CopyBufferAsSeries(ADX_handle,2,start,number,asSeries,MinusDI)) return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator ADXWilder to the arrays                   |
//+------------------------------------------------------------------------------+
bool GetADXWilderBuffers(int ADXWilder_handle,
                         int start,
                         int number,
                         double &Main[],
                         double &PlusDI[],
                         double &MinusDI[],
                         bool asSeries=true  // as series
                         )
  {
   //--- Filling the array Main with the current values of MAIN_LINE
   if(!CopyBufferAsSeries(ADXWilder_handle,0,start,number,asSeries,Main)) return(false);
   //--- Filling the array PlusDI with the current values of PLUSDI_LINE
   if(!CopyBufferAsSeries(ADXWilder_handle,1,start,number,asSeries,PlusDI)) return(false);
   //--- Filling the array MinusDI with the current values of MINUSDI_LINE
   if(!CopyBufferAsSeries(ADXWilder_handle,2,start,number,asSeries,MinusDI)) return(false);

   return(true);
  }
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Alligator to the arrays                   |
//+------------------------------------------------------------------------------+

bool GetGravBuffers(int grav_handle,
                         int start,
                         int number,
                         double &Cycle[],
                         double &Trigger[],
                         bool asSeries=true  // as series
                         )
  {
//--- Filling the array smooth
   if(!CopyBufferAsSeries(grav_handle,0,start,number,asSeries,Cycle)) return(false);
//--- Filling the array cycle
   if(!CopyBufferAsSeries(grav_handle,1,start,number,asSeries,Trigger)) return(false);

//---
   return(true);
  }
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Bands to the arrays                       |
//+------------------------------------------------------------------------------+
bool GetBandsBuffers(int Bands_handle,
                     int start,
                     int number,
                     double &Base[],
                     double &Upper[],
                     double &Lower[],
                     bool asSeries=true  // as series
                     )
  {
//--- Filling the array Base with the current values of BASE_LINE
   if(!CopyBufferAsSeries(Bands_handle,0,start,number,asSeries,Base)) return(false);
//--- Filling the array Upper with the current values of UPPER_BAND
   if(!CopyBufferAsSeries(Bands_handle,1,start,number,asSeries,Upper)) return(false);
//--- Filling the array Lower with the current values of LOWER_BAND
   if(!CopyBufferAsSeries(Bands_handle,2,start,number,asSeries,Lower)) return(false);
//---
   return(true);
  }

//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Fractals to the arrays                   |
//+------------------------------------------------------------------------------+
bool GetFractalsBuffers(int Fractals_handle,
                        int start,
                        int number,
                        double &Upper[],
                        double &Lower[],
                        bool asSeries=true       // as series
                        )
  {
//--- Filling the array Upper with the current values of UPPER_LINE
   if(!CopyBufferAsSeries(Fractals_handle,0,start,number,asSeries,Upper)) return(false);
//--- Filling the array Lower with the current values of LOWER_LINE
   if(!CopyBufferAsSeries(Fractals_handle,1,start,number,asSeries,Lower)) return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Gator to the arrays                   |
//+------------------------------------------------------------------------------+
bool GetGatorBuffers(int Gator_handle,
                     int start,
                     int number,
                     double &Upper[],
                     double &Lower[],
                     bool asSeries=true       // as series
                     )
  {
//--- Filling the array Upper with the current values of UPPER_LINE
   if(!CopyBufferAsSeries(Gator_handle,0,start,number,asSeries,Upper)) return(false);
//--- Filling the array Lower with the current values of LOWER_LINE
   if(!CopyBufferAsSeries(Gator_handle,1,start,number,asSeries,Lower)) return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Ichimoku to the arrays                    |
//+------------------------------------------------------------------------------+
bool GetIchimokuBuffers(int Ichimoku_handle,
                        int start,
                        int number,
                        double &Tenkansen[],
                        double &Kijunsen[],
                        double &SenkouspanA[],
                        double &SenkouspanB[],
                        double &Chinkouspan[],
                        bool asSeries=true       // as series
                        )
  {
//--- Filling the array Tenkansen with the current values of TENKANSEN_LINE
   if(!CopyBufferAsSeries(Ichimoku_handle,0,start,number,asSeries,Tenkansen)) return(false);
//--- Filling the array Kijunsen with the current values of KIJUNSEN_LINE
   if(!CopyBufferAsSeries(Ichimoku_handle,1,start,number,asSeries,Kijunsen)) return(false);
//--- Filling the array SenkouspanA with the current values of SENKOUSPANA_LINE
   if(!CopyBufferAsSeries(Ichimoku_handle,2,start,number,asSeries,SenkouspanA)) return(false);
//--- Filling the array SenkouspanB with the current values of SENKOUSPANB_LINE
   if(!CopyBufferAsSeries(Ichimoku_handle,3,start,number,asSeries,SenkouspanB)) return(false);
//--- Filling the array Chinkouspan with the current values of CHINKOUSPAN_LINE
   if(!CopyBufferAsSeries(Ichimoku_handle,4,start,number,asSeries,Chinkouspan)) return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator MACD to the arrays                        |
//+------------------------------------------------------------------------------+
bool GetMACDBuffers(int MACD_handle,
                    int start,
                    int number,
                    double &Main[],
                    double &Signal[],
                    bool asSeries=true       // as series
                    )
  {
//--- Filling the array Main with the current values of MAIN_LINE
   if(!CopyBufferAsSeries(MACD_handle,0,start,number,asSeries,Main)) return(false);
//--- Filling the array Signal with the current values of SIGNAL_LINE
   if(!CopyBufferAsSeries(MACD_handle,1,start,number,asSeries,Signal)) return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator RVI to the arrays                         |
//+------------------------------------------------------------------------------+
bool GetRVIBuffers(int RVI_handle,
                   int start,
                   int number,
                   double &Main[],
                   double &Signal[],
                   bool asSeries=true       // as series
                   )
  {
//--- Filling the array Main with the current values of MAIN_LINE
   if(!CopyBufferAsSeries(RVI_handle,0,start,number,asSeries,Main)) return(false);
//--- Filling the array Signal with the current values of SIGNAL_LINE
   if(!CopyBufferAsSeries(RVI_handle,1,start,number,asSeries,Signal)) return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------------------+
//| Copies the values of the indicator Stochastic to the arrays                  |
//+------------------------------------------------------------------------------+
bool GetStochasticBuffers(int Stochastic_handle,
                          int start,
                          int number,
                          double &Main[],
                          double &Signal[],
                          bool asSeries=true       // as series
                          )
  {
//--- Filling the array Main with the current values of MAIN_LINE
   if(!CopyBufferAsSeries(Stochastic_handle,0,start,number,asSeries,Main)) return(false);
//--- Filling the array Signal with the current values of SIGNAL_LINE
   if(!CopyBufferAsSeries(Stochastic_handle,1,start,number,asSeries,Signal)) return(false);
//---
   return(true);
  }