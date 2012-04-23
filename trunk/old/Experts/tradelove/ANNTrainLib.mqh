// Optimized by the capital percent value
#include        "UGAlib.mqh"
#include        "MustHaveLib.mqh"
//---
double          cap=10000;      // Initial deposit
double          optF=0.3;       // Optimal F
long            leverage;       // Account leverage
double          contractSize;   // Contract size
double          dig;            // The number of digits in a quote after a comma (to allow correct forecast of the balance curve for currency pairs with different amount of digits)
//--- for a neural network using historical data:
int             depth=250;      // Historical depth (by default - 250, in case some other value is needed, it should be changed  in the Expert Advisor/script Initializer)
int             from=0;         // Where we should copy from (must be initialized before each InitFirstLayer() function call)
int             count=2;        // Copies at a time (by default - 2, in case some other value is needed, it should be changed  in the Expert Advisor/script Initializer)
//--- 
double          a=2.5;          // Values of activation function ratio (sigmoid) (in case some other value is set, then the result of the GetANNResult() function should be compared with a value different from 0.75)
int             layers=2;       // Layers (by default - 2, in case some other value is needed, it should be changed  in the Expert Advisor/script Initializer)
int             neurons=2;      // Neurons (by default - 2, in case some other value is needed, it should be changed  in the Expert Advisors/script Initializer)
double          ne[];           // Neurons values array [layers][neurons number in a layer]
double          we[];           // Synapse weights array [layers][neurons in a layer][number of synapse at each neuron]
double          ANNRes=0;       // Neural network output result

double          ERROR=0.0;      // Average error per gene (that is for the genetic optimiser, I don't know the value)
//+------------------------------------------------------------------+
//| InitArrays                                                       |
//| Must be called in the Expert Advisor/script Initializer          |
//+------------------------------------------------------------------+
void InitArrays() 
  {
//--- neurons array
   ArrayResize(ne,layers*neurons);
//--- synapse array
   ArrayResize(we,(layers-1)*neurons*neurons+neurons);
//--- initializing the neurons array
   ArrayInitialize(ne,0.5);
//--- initializing the synapse array
   ArrayInitialize(we,0.5);
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(d,count);
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(o,count);
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(h,count);
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(l,count);
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(c,count);
//--- auxiliary array for a neural network optimization based on historical data
   ArrayResize(v,count);
  }
//+--------------------------------------------------------------------+
//| Neural network output result, the                                  |
//| InitFirstLayer() function must be called before this function call |
//+--------------------------------------------------------------------+
double GetANNResult() //
  {
   double r;
   int    c1,c2,c3;
   for(c1=2;c1<=layers;c1++)
     {
      for(c2=1;c2<=neurons;c2++)
        {
         ne[(c1-1)*neurons+c2-1]=0;
         for(c3=1;c3<=neurons;c3++)
           {
            ne[(c1-1)*neurons+c2-1]=ne[(c1-1)*neurons+c2-1]+ne[(c1-2)*neurons+c3-1]*we[((c1-2)*neurons+c3-1)*neurons+c2-1];
           }
         ne[(c1-1)*neurons+c2-1]=1/(1+MathExp(-a*ne[(c1-1)*neurons+c2-1]));
        }
     }
   r=0;
   for(c2=1;c2<=neurons;c2++)
     {
      r=r+ne[(layers-1)*neurons+c2-1]*we[(layers-1)*neurons*neurons+c2-1];
     }
   r=1/(1+MathExp(-a*r));
   return(r);
  }
//+------------------------------------------------------------------+
//| Fitness function for neural network genetic optimiser:           |
//| selecting a pair, optF, synapse weights;                         |
//| anything can be optimised but it is necessary                    |
//| to carefully monitor the number of genes                         |
//+------------------------------------------------------------------+
void FitnessFunction(int chromos) 
  {
   int    c1;
   int    b;
//--- intermediary between a gene colony and optimised parameters
   int    z;
// Current balance
   double t=cap;                                                      
// Maximum balance
   double maxt=t;
// Absolute drawdown
   double aDD=0;
// Relative drawdown
   double rDD=0.000001;
// Fitness function proper
   double ff=0;
// GA is selecting synapse weights
   for(c1=1;c1<=GeneCount-2;c1++) we[c1-1]=Colony[c1][chromos];
// GA is selecting a pair
   z=(int)MathRound(Colony[GeneCount-1][chromos]*12);                 
   switch(z)
     {
      case  0: {s="AUDUSD"; break;};
      case  1: {s="AUDUSD"; break;};
      case  2: {s="EURAUD"; break;};
      case  3: {s="EURCHF"; break;};
      case  4: {s="EURGBP"; break;};
      case  5: {s="EURJPY"; break;};
      case  6: {s="EURUSD"; break;};
      case  7: {s="GBPCHF"; break;};
      case  8: {s="GBPJPY"; break;};
      case  9: {s="GBPUSD"; break;};
      case 10: {s="USDCAD"; break;};
      case 11: {s="USDCHF"; break;};
      case 12: {s="USDJPY"; break;};
      default: {s="EURUSD"; break;};
     }
   dig=MathPow(10.0,(double)SymbolInfoInteger(s,SYMBOL_DIGITS));
   //--- GA is selecting the optimal F
   optF=Colony[GeneCount][chromos];                                   
   leverage=AccountInfoInteger(ACCOUNT_LEVERAGE);
   contractSize=SymbolInfoDouble(s,SYMBOL_TRADE_CONTRACT_SIZE);
   b=MathMin(Bars(s,tf)-1-count,depth);
   //--- for a neural network using historical data - where the data is copied from
   for(from=b;from>=1;from--) 
     {
      //--- initializing the input layer
      InitFirstLayer();                                                
      //--- getting the result at the neural network output
      ANNRes=GetANNResult();
      if(t>0)
        {
         if(ANNRes<0.75) t=t+t*optF*leverage*(o[1]-c[1])*dig/contractSize;
         else            t=t+t*optF*leverage*(c[1]-o[1])*dig/contractSize;
        }
      else t=0;
      if(t>maxt) {maxt=t; aDD=0;} else if((maxt-t)>aDD) aDD=maxt-t;
      if((maxt>0) && (aDD/maxt>rDD)) rDD=aDD/maxt;
     }
   if(rDD<=trainDD) ff=t; else ff=0.0;
   AmountStartsFF++;
   Colony[0][chromos]=ff;
  }
//+------------------------------------------------------------------+
//| ServiceFunction()                                                |
//+------------------------------------------------------------------+
void ServiceFunction()
  {
  }
//+------------------------------------------------------------------+
//| Preparing and calling the genetic optimiser                      |
//+------------------------------------------------------------------+
void GA()
  {
//--- number of genes (equal to the number of optimised variables), 
//--- all of them should be specified in FitnessFunction())
   GeneCount      =(layers-1)*neurons*neurons+neurons+2;              
//--- number of chromosomes in a colony
   ChromosomeCount=GeneCount*11;                                      
//--- minimum search range
   RangeMinimum   =0.0;                                               
//--- maximum search range
   RangeMaximum   =1.0;                                               
//--- search pitch
   Precision      =0.0001;                                            
//--- 1 is a minimum, anything else is a maximum
   OptimizeMethod =2;                                                 
   ArrayResize(Chromosome,GeneCount+1);
   ArrayInitialize(Chromosome,0);
//--- number of epochs without any improvement
   Epoch          =100;                                               
//--- ratio of replication, natural mutation, artificial mutation, gene borrowing, 
//--- crossingover, interval boundary displacement ratio, every gene mutation probabilty, %
   UGA(100.0,1.0,1.0,1.0,1.0,0.5,1.0);                                
  }
//+---------------------------------------------------------------------+
//| GetTrainANNResults()                                                |
//| getting the optimised neural network parameters and other variables |
//| should always be equal to the number of genes                       |
//+---------------------------------------------------------------------+
void GetTrainANNResults()
  {
   int c1;
//--- intermediary between a gene colony and optimised parameters
   int z;                                                            
//--- store best synapse weights in memory
   for(c1=1;c1<=GeneCount-2;c1++) we[c1-1]=Chromosome[c1];
//--- save the best pair
   z=(int)MathRound(Chromosome[GeneCount-1]*12);
   switch(z)
     {
      case  0: {s="AUDUSD"; break;};
      case  1: {s="AUDUSD"; break;};
      case  2: {s="EURAUD"; break;};
      case  3: {s="EURCHF"; break;};
      case  4: {s="EURGBP"; break;};
      case  5: {s="EURJPY"; break;};
      case  6: {s="EURUSD"; break;};
      case  7: {s="GBPCHF"; break;};
      case  8: {s="GBPJPY"; break;};
      case  9: {s="GBPUSD"; break;};
      case 10: {s="USDCAD"; break;};
      case 11: {s="USDCHF"; break;};
      case 12: {s="USDJPY"; break;};
      default: {s="EURUSD"; break;};
     }
//--- saving the best optimal F
   optF=Chromosome[GeneCount];                                        
  }
//+------------------------------------------------------------------+
