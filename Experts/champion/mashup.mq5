//+------------------------------------------------------------------+
//      
//Consideraciones generales
//Sistema tipo swing ==> escasas oportunidades de podium pero altas top ten

// probar errores 
// Algo guay para este sistema es que si el precio ha recorrido mucha distancia
// y no ha metido su segunda orden se mete y punto !!!

//+------------------------------------------------------------------+
#property copyright "hippie Corp."

#include <Trade\Trade.mqh>    
#include <Trade\AccountInfo.mqh>
//+-----------------------------------+
//|  Indicator input parameters       |
//+-----------------------------------+
input int Fast=30;
input int Slow=500;
input int Sign=32;


//--- input parameters

input double sl = 0.008;
input double tp = 0.022;

input double Risk  = 0.1;
 

int    MACD,ATR_handle;

CTrade trade;  
CAccountInfo account ;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
       MACD=iMACD(NULL,0,Fast,Slow,Sign,PRICE_CLOSE);
    
   return(0);
  }
  
  /**
void OnDeinit(const int reason)
{
   IndicatorRelease(MA_handle_fast); // delete indicators
   IndicatorRelease(MA_handle_slow); 
   IndicatorRelease(MA_handle_slowest); 
   IndicatorRelease(ATR_handle);  
   IndicatorRelease(BB_handle);  

}
*/
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
     {
   
    int Mybars=Bars(_Symbol,_Period);
      if(Mybars<100) 
        {
         Alert("We have less than 100 bars on the chart, the Expert Advisor will exit!!!");
         return;
        }
    static bool sell,buy;
      double Ind[2],Sig[3];
      sell=false;
      buy=false;

      if(CopyBuffer(MACD,0,1,2,Ind)<=0)return;
      
      if(CopyBuffer(MACD,1,1,3,Sig)<=0)return;

      ArraySetAsSeries(Ind,true);
      ArraySetAsSeries(Sig,true);

       
 if  (!PositionSelect(_Symbol)) 
 {
 
      if(Ind[0]>0 && Ind[1]<0) buy=true;
      if(Ind[0]<0 && Ind[1]>0) sell=true;
      if(Ind[1]<0 && Sig[0]<Sig[1] && Sig[1]>Sig[2]) buy=true;
      if(Ind[1]>0 && Sig[0]>Sig[1] && Sig[1]<Sig[2]) sell=true;
 if (buy || sell)
 {
   double no = 0 ;
   double lot = Money_M(sl,false);
 double tmp = 0 ;
   if (lot>5)
          {
              no=lot/4.99;
               for (int i =0; i<=no ; i++)
                 { 
                    printf("el lot a partir es : " + lot + " no " + no);
                  if (lot > 5)
                           tmp = 5;
                           else tmp = lot;
                            
   				if (buy)  deal(ORDER_TYPE_BUY,tmp);
   				else if (sell)deal(ORDER_TYPE_SELL,tmp);
   				Sleep(500);
   				if (i == 2) break;
   				lot = lot -5;
   				}
   			}
			else
			{
				if (buy)  deal(ORDER_TYPE_BUY,lot);
				else if (sell)deal(ORDER_TYPE_SELL,lot);
			}
	}
      
  }
   }   



/*
Necesito una función que me diga en base a la direccion el precio base ! do I 
*/

bool deal(long dir,double lot)
{

      printf(__FUNCTION__+ " Abrimos posicion con un stop de  " +sl  + " pips. un take profit de : " + tp);
      if(dir == ORDER_TYPE_BUY)        // cuanto es lo minimo para apostar ??
                    {
                    printf("BUY ### pips : " + sl );
                    trade.PositionOpen(_Symbol,                                          
                                        ORDER_TYPE_BUY,                                   
                                        lot,                                        
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5),                                              
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5) - sl,                          
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5) + tp,                        
                                        " BUY ");   
                       return true;                                          
                    }
                    else if (ORDER_TYPE_SELL)
                    {
                     printf("SELL ### pips : " + sl );
                     trade.PositionOpen(_Symbol,                                          
                                        ORDER_TYPE_SELL,                                   
                                        lot,                                        
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5),                                              
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5) + sl,                          
                                          NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),5) - tp,                        
                                        " SELL ");      
                        return true;
                    }
                    return false;
}


double Money_M(double pips, bool pyr)
{
    
   printf(__FUNCTION__+ " account.FreeMargin():  " + account.FreeMargin());
   
   double risk = account.FreeMargin()*Risk;
    
   pips = pips *100000 ;
   double lot = -1 ;

           lot = risk /pips ;
           printf(__FUNCTION__+ " Abrimos posicion con Volumen de " + lot );

       
    if (PositionSelect(_Symbol))
    if ( (lot +PositionGetDouble(POSITION_VOLUME))  > 15.0 )
            lot = 14.99 -  PositionGetDouble(POSITION_VOLUME);
                
            
            return ((NormalizeDouble(lot,2)));
    
}
  
  

    
    
    

