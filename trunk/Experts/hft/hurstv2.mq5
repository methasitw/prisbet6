
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh> 
input int    HourStart =   7; // Hour of trade start
input int    HourEnd   =  20; // Hour of trade end

input int    HourLimit   =  12;

input int    periodMaMi =  4;
input int 	loose = 2;
input string Symbol="EURUSD" ;
input ENUM_TIMEFRAMES period = PERIOD_H1;
input int n = 5;
input int nBars = 1000;
input int drawDown = 16000;

double down,up;
int tp = 5;



 
  int             handle_hurst;           

   
  CSymbolInfo       smbinf;      // symbol parameters
  CTrade trade;                            
   
  bool      checkForOpen(long dir);             
  bool      checkForClose(long dir) ;
  long    	chekPrice(long dir);
  bool      checkTime(datetime start,datetime end);
  bool      getLimits();

  bool      checkLoose();
  double    getStops();  
  double    BasePrice(long dir);            // returns Bid/Ask price for specified direction

//risk management
  bool      deal(long dir);
  double    fixedRatio();

  //indicators functions
  double      hurst();            // check signal
   

  
   
 int OnInit()
  {  
      
      //stack overflow
     down = -1; up = -1;
     printf(Symbol);
      smbinf.Name(Symbol);
/**
       handle_hurst=iCustom(Symbol,period,"HURSTINDICATOR",n,nBars);
     printf("hurst indicator! " + handle_hurst);
       if(handle_hurst==INVALID_HANDLE)
        {
         printf("Error in hurst indicator!");
         return(true);
        }
 */
     return(0);
}


void OnTick()
  {
   smbinf.Refresh();smbinf.RefreshRates();

   //fase de inactividad
   if(!checkTime(StringToTime(IntegerToString(HourStart)+":00"),
      StringToTime(IntegerToString(HourEnd)+":00"))) return;
      
  
    //fase de mamximos y minimos
   if (getLimits()) return;						   //Calcula el maximo // minnimo en el intervalo entre start y HourLimit 
     
  
     
   if(checkTime(StringToTime(IntegerToString(HourStart)+":00"),
      StringToTime(IntegerToString(HourLimit)+":00"))) return;
 
   
     
		if(!PositionSelect(Symbol) )
		{
		 (checkForOpen(ORDER_TYPE_SELL)) ;
		 (checkForOpen(ORDER_TYPE_BUY)) ;
		}
		else{
		checkForClose(ORDER_TYPE_SELL);
		}

}  

bool checkForOpen(long dir)
{
  // indicator signal
  //  if (hurst() < 0.5) return(false);
      // min max signal
      if (dir == chekPrice(dir)) return (false);
        printf( " down " + down  + " up " + up + " " +  TimeCurrent() );
    // deal
	deal(dir);
   return (false)  ;
}


long chekPrice(long dir)
{
   if ( dir == ORDER_TYPE_SELL && BasePrice(dir) > down)   return dir;
      else if ( dir == ORDER_TYPE_BUY && BasePrice(dir) > up)   return dir;
      else return( WRONG_VALUE);
}

bool checkForClose(long dir)
{
  if (checkLoose()) return(false);
      return (false)  ;
}

// atencion este indicador no establece cual es la tendencia, solo indica que 
// existe persistencia en el precio bien para un sentido o para el otro
double hurst()
{
return -1;
}

//si la perdida es mayor que un tanto x ciento de la cuenta se va fuera.
bool checkLoose()
{
	double Equity =AccountInfoDouble(ACCOUNT_FREEMARGIN);
	double positionLoose = PositionGetDouble(POSITION_PROFIT);
	
	if (MathAbs(positionLoose) > (Equity* loose/100))
		return (true);
		else return (false);
}




//########### MONEY MANAGEMENT FUNCTION  ####################

bool deal(long dir)
{
     
      if(dir == ORDER_TYPE_BUY)      
                    {
                    trade.PositionOpen(Symbol,                                          
                                        ORDER_TYPE_BUY,                                   
                                        fixedRatio(),                                        
                                          BasePrice(dir),                                              
                                          (BasePrice(dir) - (up-down)),   //       SL                
                                           0,                           //TP
                                        " BUY ");  
                                          printf( " BasePrice " + BasePrice(dir)     ); 
                                     
                       return true;                                          
                    }
                    else if (ORDER_TYPE_SELL)
                    {
                     trade.PositionOpen(Symbol,                                          
                                        ORDER_TYPE_SELL,                                   
                                        fixedRatio(),                                        
                                          BasePrice(dir),                                              
                                          (BasePrice(dir) + (up-down)),       //SL               
                                          0,                               //TP
                                        " SELL ");      
                        return true;
                    }
                    return false;
}

  
//
double fixedRatio()
{
double DD = drawDown;
  double Equity =AccountInfoDouble(ACCOUNT_FREEMARGIN);
  double DeltaNeutro = DD/2;
  double value = 1 + 8*(Equity/DeltaNeutro );
  double valuesqrt = sqrt(value);
  double N = 1 + ( valuesqrt / 2);
  N = N*0.1;
  printf( " N " + N + " valuesqrt " +  valuesqrt  );
  
  //printf("el riesgo que queremos es: " + (pips*  N*100000)+" pips " + pips + " lot: " + N);

 return ((NormalizeDouble( N,2)));
}



//####################### AUX FUCTIONS #####################

/*
  En el vector de tiempo inicial donde se determinan el maximo y minimo buy/sell
*/
bool getLimits()
{
  double High[],Low[];
      
   int high =  CopyHigh(NULL,PERIOD_H1,0,periodMaMi,High);
   int low =  CopyLow(NULL,PERIOD_H1,0,periodMaMi,Low);

  down = Low[ArrayMinimum(Low, 0, WHOLE_ARRAY)]   ;
  up =   High[ArrayMaximum(High, 0, WHOLE_ARRAY)] ;
    
  return(false);

}

/*
  True si el time current esta comprendido entre el date start y end
*/
bool checkTime(datetime start,datetime end)
  {
   datetime dt=TimeCurrent();                          // current time
   if(start<end) if(dt>=start && dt<end) return(true); // check if we are in the range
   if(start>=end) if(dt>=start|| dt<end) return(true);
   return(false);
  } 

  
 double BasePrice(long dir)
  {
  smbinf.Refresh();
   if(dir==(long)ORDER_TYPE_BUY) return(smbinf.Ask());
   if(dir==(long)ORDER_TYPE_SELL) return(smbinf.Bid());
   return(WRONG_VALUE);
  }
  
  
  
  