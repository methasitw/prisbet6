

#include <Trade\SymbolInfo.mqh>

input int    HourStart  =   8; // Hour of trade start
input int    HourMaMi   =  12;
input int    HourEnd    =  22; // Hour of trade end
input int    periodMaMi =  4;

input string Symbol="EURUSD" ;
input ENUM_TIMEFRAMES period = PERIOD_H1;

input int n = 5;
input int nBars = 1000;
double down,up;
class Hurst   
  {
protected:
 
   int             Bands_handle_PYR, Bands_handle, EMAFastMaHandle, EMASlowMaHandle , EMASlowestMaHandle;           
   string          m_smb; ENUM_TIMEFRAMES m_tf ; 
   

  CSymbolInfo       smbinf;      // symbol parameters
public:
	void        Hurst();
   void       ~Hurst();
	
	 bool     init(string smb,ENUM_TIMEFRAMES tf); 
	 void     main();                             
	 
	bool      checkForOpen(long dir);             
	bool      checkForClose(long dir) ;
	long     chekPrice(long dir);
	bool      checkTime(datetime start,datetime end);
	bool      getLimits(datetime start,datetime end);
	bool      checkLoose();
	double    getStops();	
	double    BasePrice(long dir);            // returns Bid/Ask price for specified direction
	//indicators functions
	double      hurst();            // check signal
   
   
  };
  
       
bool  Hurst::init(string smb,ENUM_TIMEFRAMES tf)
{
      m_smb=smb;
      m_tf = tf;
      down = -1; up = -1;
       int handle1=iCustom(m_smb,m_tf,"hurst",n,nBars);
       if(handle1==INVALID_HANDLE)
        {
         Print("Error in RKD indicator!");
         return(1);
        }
      
      return(true);
}

void Hurst::main()
{
   //fase de inactividad
   if (!checkTime(HourStart,HourEnd)) return;
   //fase de mamximos y minimos
   if (!getLimits(HourStart,HourMaMi)) return;
	   
	    if  (!PositionSelect(m_smb)) 
		       checkForOpen(ORDER_TYPE_SELL);
			         checkForClose(ORDER_TYPE_SELL);
			         
		if  (!PositionSelect(m_smb)) 
		       checkForOpen(ORDER_TYPE_BUY);
			         checkForClose(ORDER_TYPE_BUY);
}  

bool Hurst::checkForOpen(long dir)
{
	// indicator signal
		if (hurst() < 0.5) return(false);
			// min signal
			if (dir == chekPrice(dir)) return (false);
		
   return (false)	;
}


long Hurst::chekPrice(long dir)
{
   if ( dir == ORDER_TYPE_SELL && BasePrice(dir) > down)   return dir;
      else if ( dir == ORDER_TYPE_BUY && BasePrice(dir) > up)   return dir;
      else return( WRONG_VALUE);

}
bool Hurst::checkForClose(long dir)
{
	if (checkLoose()) return(false);
      return (false)	;
}

// atencion este indicador no establece cual es la tendencia, solo indica que 
// existe persistencia en el precio bien para un sentido o para el otro
double Hurst::hurst()
{
return -1;
}

//
bool Hurst::checkLoose()
{
return false;
}

/*
	En el vector de tiempo comprendido entre las 9 y las 12
	se consigue el maximo y el minimo que consituyen niveles de salida, 
	dependiendo si la entrada sell o buy
*/

bool Hurst::getLimits(datetime start,datetime end)
{

 

 datetime dt=TimeCurrent();                          // current time
   if(start<end) if(dt>=start && dt<end) return(true); // check if we are in the range
   if(start>=end) if(dt>=start|| dt<end) return(true);
  
   
   
     double High[],Low[];
      
   int high =  CopyHigh(NULL,PERIOD_H1,0,periodMaMi,High);
   int low =  CopyLow(NULL,PERIOD_H1,0,periodMaMi,Low);

    down = Low[ArrayMinimum(Low, 0, WHOLE_ARRAY)]   ;
     up =   High[ArrayMaximum(High, 0, WHOLE_ARRAY)] ;
		
	return(false);

}

bool Hurst::checkTime(datetime start,datetime end)
  {
   datetime dt=TimeCurrent();                          // current time
   if(start<end) if(dt>=start && dt<end) return(true); // check if we are in the range
   if(start>=end) if(dt>=start|| dt<end) return(true);
   return(false);
  } 

  
 double Hurst::BasePrice(long dir)
  {
   if(dir==(long)ORDER_TYPE_BUY) return(smbinf.Ask());
   if(dir==(long)ORDER_TYPE_SELL) return(smbinf.Bid());
   return(WRONG_VALUE);
  }
  
  
  
    
Hurst  h; // class instance
//------------------------------------------------------------------	OnInit
int OnInit()
  {
  
   h.init(Symbol,period); // initialize expert
   return(0);
  }

  
void OnDeinit(const int reason)
  {
  // ~Hurst();
  }


//------------------------------------------------------------------	OnTick
void OnTick()
  {
   h.main();
  }
//+------------------------------------------------------------------+
