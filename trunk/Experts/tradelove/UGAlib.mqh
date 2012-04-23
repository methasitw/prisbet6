//+——————————————————————————————————————————————————————————————————————+
//|                                                       JQS UGA v1.3.1 |
//|                                       Copyright © 2010, JQS aka Joo. |
//|                                     http://www.mql4.com/ru/users/joo |
//|                                  https://login.mql5.com/ru/users/joo |
//+——————————————————————————————————————————————————————————————————————+
//The "Universla Genetic Algorithm UGAlib Library"                       |
//that uses the representation of chromosome via real numbers.           |
//+——————————————————————————————————————————————————————————————————————+

//----------------------Global Variables-----------------------------
double Chromosome[];            //Number of optimized arguments of the function - genes
                                //(for example: weights of the neutron net, etc.)-chromosome
int    ChromosomeCount     =0;  //Maximum possible number of chromosomes in colony
int    TotalOfChromosomesInHistory=0;//Total number of chromosomes in history
int    ChrCountInHistory   =0;  //Number of unique chromosomes in the chromosome base
int    GeneCount           =0;  //Number of genes in a chromosome

double RangeMinimum        =0.0;//Minimum of the search range
double RangeMaximum        =0.0;//Maximum of the search range
double Precision           =0.0;//Search step
int    OptimizeMethod      =0;  //1-minimum, any other - maximum

double Population   [][1000];   //Population
double Colony       [][500];    //Colony of offsprings
int    PopulChromosCount   =0;  //Current number of chromosomes in the population
int    Epoch               =0;  //Number of epochs without improvement
int    AmountStartsFF=0;        //Number of launches of the fitness function
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Main function of UGA
void UGA
(
double ReplicationPortion, //Portion of replication.
double NMutationPortion,   //Portion of natural mutation.
double ArtificialMutation, //Portion of artificial number .
double GenoMergingPortion, //Portion of adoption of genes.
double CrossingOverPortion,//Portion of crossing over.
//---
double ReplicationOffset,  //Rate of shifting the interval borders
double NMutationProbability//Probability of mutation of each gene in %
)
{ 
  //Reset the generator; performed only once
  MathSrand((int)TimeLocal());
  //-----------------------Variables-------------------------------------
  int    chromos=0, gene  =0;//Indexes of chromosomes and genes
  int    resetCounterFF   =0;//Counter of resets of "Epochs without improvement"
  int    currentEpoch     =1;//Number of the current epoch
  int    SumOfCurrentEpoch=0;//Sum of "Epoch without improvement"
  int    MinOfCurrentEpoch=Epoch;//Minimum of "Epochs without improvement"
  int    MaxOfCurrentEpoch=0;//Maximum of "Epochs without improvement"
  int    epochGlob        =0;//Total number of epochs
  // Colony [number of attributes (genes)][number of individuals in colony]
  ArrayResize    (Population,GeneCount+1);
  ArrayInitialize(Population,0.0);
  // Number of offsprings [number of attributes (genes)][number of individuals in colony]
  ArrayResize    (Colony,GeneCount+1);
  ArrayInitialize(Colony,0.0);
  // Bank of Chromosomes
  // [number of attributes(genes)][number of chromosomes in bank]
  double          historyHromosomes[][100000];
  ArrayResize    (historyHromosomes,GeneCount+1);
  ArrayInitialize(historyHromosomes,0.0);
  //----------------------------------------------------------------------
  //--------------Checking the correctness of input parameters----------------
  //...number of chromosomes must be no less than 2
  if (ChromosomeCount<=1)  ChromosomeCount=2;
  if (ChromosomeCount>500) ChromosomeCount=500;
  //----------------------------------------------------------------------
  //======================================================================
  // 1) Create protopopulation                                     —————1)
  ProtopopulationBuilding ();
  //======================================================================
  // 2) Determine the fitness of each individual                   —————2)
  //For 1-st colony
  for (chromos=0;chromos<ChromosomeCount;chromos++)
    for (gene=1;gene<=GeneCount;gene++)
      Colony[gene][chromos]=Population[gene][chromos];

  GetFitness(historyHromosomes);

  for (chromos=0;chromos<ChromosomeCount;chromos++)
    Population[0][chromos]=Colony[0][chromos];

  //For 2-nd colony
  for (chromos=ChromosomeCount;chromos<ChromosomeCount*2;chromos++)
    for (gene=1;gene<=GeneCount;gene++)
      Colony[gene][chromos-ChromosomeCount]=Population[gene][chromos];

  GetFitness(historyHromosomes);

  for (chromos=ChromosomeCount;chromos<ChromosomeCount*2;chromos++)
    Population[0][chromos]=Colony[0][chromos-ChromosomeCount];
  //======================================================================
  // 3) Prepare the population for propagation                      ————3)
  RemovalDuplicates();
  //======================================================================
  // 4) Select the standard chromosome                             —————4)
  for (gene=0;gene<=GeneCount;gene++)
    Chromosome[gene]=Population[gene][0];
  //======================================================================
  ServiceFunction();

  //Main cycle of the genetic algorithm from 5 to 6
  while (currentEpoch<=Epoch)
  {
    //====================================================================
    // 5) Operators of UGA                                         —————5)
    CycleOfOperators
    (
    historyHromosomes,
    //---
    ReplicationPortion, //Portion of replication.
    NMutationPortion,   //Portion of natural mutation.
    ArtificialMutation, //Portion of artificial mutation.
    GenoMergingPortion, //Portion of adoption of genes.
    CrossingOverPortion,//Portion of crossing over.
    //---
    ReplicationOffset,  //Rate of shifting the interval borders
    NMutationProbability//Probability of mutation of each gene in %
    );
    //====================================================================
    // 6) Compare genes of the best offspring with genes of the standard chromosome. 
    // If the chromosome of offspring is betters than the standard one,
    // replace the standard one.                                   —————6)
    // if the optimization mode is minimization
    if (OptimizeMethod==1)
    {
      //If the best chromosome of the population is better than the standard one
      if (Population[0][0]<Chromosome[0])
      {
        //Replace the standard chromosome
        for (gene=0;gene<=GeneCount;gene++)
          Chromosome[gene]=Population[gene][0];
        ServiceFunction();
        //Reset the counter of "epochs without improvement"
        if (currentEpoch<MinOfCurrentEpoch)
          MinOfCurrentEpoch=currentEpoch;
        if (currentEpoch>MaxOfCurrentEpoch)
          MaxOfCurrentEpoch=currentEpoch;
        SumOfCurrentEpoch+=currentEpoch; currentEpoch=1; resetCounterFF++;
      }
      else
        currentEpoch++;
    }
    //If the optimization mode is maximization
    else
    {
      //If the best chromosome of the population is better than the standard one
      if (Population[0][0]>Chromosome[0])
      {
        //Replace the standard chromosome
        for (gene=0;gene<=GeneCount;gene++)
          Chromosome[gene]=Population[gene][0];
        ServiceFunction();
        //Reset the counter of "epochs without improvement"
        if (currentEpoch<MinOfCurrentEpoch)
          MinOfCurrentEpoch=currentEpoch;
        if (currentEpoch>MaxOfCurrentEpoch)
          MaxOfCurrentEpoch=currentEpoch;
        SumOfCurrentEpoch+=currentEpoch; currentEpoch=1; resetCounterFF++;
      }
      else
        currentEpoch++;
    }
    //====================================================================
    //Another epoch has passed....
    epochGlob++;
  }
  Print("Total number of passed epochs=",epochGlob," Number of resets=",resetCounterFF);
  Print("MinOfCurrentEpoch",MinOfCurrentEpoch,
        " AverageOfCurrentEpoch",NormalizeDouble((double)SumOfCurrentEpoch/(double)resetCounterFF,2),
        " MaxOfCurrentEpoch",MaxOfCurrentEpoch);
  Print(ChrCountInHistory," - Unique chromosomes");
  Print(AmountStartsFF," - Total number of launches of FF");
  Print(TotalOfChromosomesInHistory," - Total number of chromosomes in history");
  Print(NormalizeDouble(100.0-((double)ChrCountInHistory*100.0/(double)TotalOfChromosomesInHistory),2),"% of duplicates");
  Print(Chromosome[0]," - Best result");
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Creation of protopopulation
void ProtopopulationBuilding()
{ 
  PopulChromosCount=ChromosomeCount*2;
  //Fill the population with chromosomes that have random
  //...genes within the RangeMinimum...RangeMaximum range
  for (int chromos=0;chromos<PopulChromosCount;chromos++)
  {
    //starting from the 1-st index (0- is reserved for VFF) 
    for (int gene=1;gene<=GeneCount;gene++)
      Population[gene][chromos]=
      SelectInDiscreteSpace(RNDfromCI(RangeMinimum,RangeMaximum),RangeMinimum,RangeMaximum,Precision,3);
    TotalOfChromosomesInHistory++;
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Obtain the fitness for each individual.
void GetFitness
(
double &historyHromosomes[][100000]
)
{ 
  for (int chromos=0;chromos<ChromosomeCount;chromos++)
    CheckHistoryChromosomes(chromos,historyHromosomes);
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Check chromosome by the base of chromosomes.
void CheckHistoryChromosomes
(
int     chromos,
double &historyHromosomes[][100000]
)
{ 
  //-----------------------Variables-------------------------------------
  int   Ch1=0;  //Index of a chromosome from base
  int   Ge =0;  //Index of a gene
  int   cnt=0;  //Counter of unique genes. If at least one gene is different 
                //- the chromosome is considered to be unique
  //----------------------------------------------------------------------
  //If at least one chromosome is stored in the base
  if (ChrCountInHistory>0)
  {
    //Search through the chromosomes in base to find the same one
    for (Ch1=0;Ch1<ChrCountInHistory && cnt<GeneCount;Ch1++)
    {
      cnt=0;
      //Compare genes while the index of a gene is less than the number of genes and while the same genes are being found
      for (Ge=1;Ge<=GeneCount;Ge++)
      {
        if (Colony[Ge][chromos]!=historyHromosomes[Ge][Ch1])
          break;
        cnt++;
      }
    }
    //If there's the same number of identical genes, we can take a ready solution from the base
    if (cnt==GeneCount)
      Colony[0][chromos]=historyHromosomes[0][Ch1-1];
    //If there is no identical chromosome in the base, calculate FF for it...
    else
    {
      FitnessFunction(chromos);
      //.. If there is free space in the base, save it
      if (ChrCountInHistory<100000)
      {
        for (Ge=0;Ge<=GeneCount;Ge++)
          historyHromosomes[Ge][ChrCountInHistory]=Colony[Ge][chromos];
        ChrCountInHistory++;
      }
    }
  }
  //If the base is free, calculate FF for it and save it in the base
  else
  {
    FitnessFunction(chromos);
    for (Ge=0;Ge<=GeneCount;Ge++)
      historyHromosomes[Ge][ChrCountInHistory]=Colony[Ge][chromos];
    ChrCountInHistory++;
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Cycle of UGA operators
void CycleOfOperators
(
double &historyHromosomes[][100000],
//---
double    ReplicationPortion, //Portion of replication.
double    NMutationPortion,   //Portion of mutation.
double    ArtificialMutation, //Portion of artificial mutation.
double    GenoMergingPortion, //Portion of adoption of genes.
double    CrossingOverPortion,//Portion of crossing over.
//---
double    ReplicationOffset,  //Rate of shifting the interval borders
double    NMutationProbability//Probability of mutation of each gene in %
)
{
  //-----------------------Variables-------------------------------------
  double          child[];
  ArrayResize    (child,GeneCount+1);
  ArrayInitialize(child,0.0);

  int gene=0,chromos=0, border=0;
  int    i=0,u=0;
  double p=0.0,start=0.0;
  double          fit[][2];
  ArrayResize    (fit,6);
  ArrayInitialize(fit,0.0);

  //Counter of seats in a new population.
  int T=0;
  //----------------------------------------------------------------------

  //Set portion of operators of UGA
  double portion[6];
  portion[0]=ReplicationPortion; //Portion of replication.
  portion[1]=NMutationPortion;   //Portion of natural mutation.
  portion[2]=ArtificialMutation; //Portion of artificial mutation.
  portion[3]=GenoMergingPortion; //Portion of adoption of genes.
  portion[4]=CrossingOverPortion;//Portion of crossing over.
  portion[5]=0.0;
  //----------------------------
  if (NMutationProbability<0.0)
    NMutationProbability=0.0;
  if (NMutationProbability>100.0)
    NMutationProbability=100.0;
  //----------------------------
  //------------------------Cycle of operators of UGA---------
  //Fill the new colony with offsprings 
  while (T<ChromosomeCount)
  {
    //============================
    for (i=0;i<6;i++)
    {
      fit[i][0]=start;
      fit[i][1]=start+MathAbs(portion[i]-portion[5]);
      start=fit[i][1];
    }
    p=RNDfromCI(fit[0][0],fit[4][1]);
    for (u=0;u<5;u++)
    {
      if ((fit[u][0]<=p && p<fit[u][1]) || p==fit[u][1])
        break;
    }
    //============================
    switch (u)
    {
    //---------------------
    case 0:
      //------------------------Replication--------------------------------
      //If there is a place in new colony, create a new individual
      if (T<ChromosomeCount)
      {
        Replication(child,ReplicationOffset);
        //Place the new individual in new colony
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //Occupied one place and scroll the counter forward
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    case 1:
      //---------------------Natural Mutation-------------------------
      //If there is a place in new colony, create a new individual
      if (T<ChromosomeCount)
      {
        NaturalMutation(child,NMutationProbability);
        //Place the new individual in new colony
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //Occupied one place and scroll the counter forward
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    case 2:
      //----------------------Artificial Mutation-----------------------
      //If there is a place in new colony, create a new individual
      if (T<ChromosomeCount)
      {
        ArtificialMutation(child,ReplicationOffset);
        //Place the new individual in new colony
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //Occupied one place and scroll the counter forward
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    case 3:
      //-------------Formation of a new individual with adopted genes-----------
      //If there is a place in new colony, create a new individual
      if (T<ChromosomeCount)
      {
        GenoMerging(child);
        //Place the new individual in new colony 
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //Occupied one place and scroll the counter forward
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    default:
      //---------------------------Êðîññèíãîâåð---------------------------
      //If there is a place in new colony, create a new individual
      if (T<ChromosomeCount)
      {
        CrossingOver(child);
        //Place the new individual in new colony
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //Occupied one place and scroll the counter forward
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------

      break;
      //---------------------
    }
  }//End of the cycle of UGA operators--

  //Determine the fitness of each individual in the colony of offsprings
  GetFitness(historyHromosomes);

  //Plcae the ffsprings in the main population
  if (PopulChromosCount>=ChromosomeCount)
  {
    border=ChromosomeCount;
    PopulChromosCount=ChromosomeCount*2;
  }
  else
  {
    border=PopulChromosCount;
    PopulChromosCount+=ChromosomeCount;
  }
  for (chromos=0;chromos<ChromosomeCount;chromos++)
    for (gene=0;gene<=GeneCount;gene++)
      Population[gene][chromos+border]=Colony[gene][chromos];

  //Prepare the population to the next propagation
  RemovalDuplicates();
}//end of function
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Replication
void Replication
(
double &child[],
double  ReplicationOffset
)
{
  //-----------------------Variables-------------------------------------
  double C1=0.0,C2=0.0,temp=0.0,Maximum=0.0,Minimum=0.0;
  int address_mama=0,address_papa=0;
  //----------------------------------------------------------------------
  SelectTwoParents(address_mama,address_papa);
  //-------------------Cycle of searching genes--------------------------------
  for (int i=1;i<=GeneCount;i++)
  {
    //----Determine where do mother and father come from--------
    C1 = Population[i][address_mama];
    C2 = Population[i][address_papa];
    //------------------------------------------

    //------------------------------------------------------------------
    //....determine the largest and the smallest of them,
    //if Ñ1>C2, switch their places
    if (C1>C2)
    {
      temp = C1; C1=C2; C2 = temp;
    }
    //--------------------------------------------
    if (C2-C1<Precision)
    {
      child[i]=C1; continue;
    }
    //--------------------------------------------
    //Set the borders of creation of new gene
    Minimum = C1-((C2-C1)*ReplicationOffset);
    Maximum = C2+((C2-C1)*ReplicationOffset);
    //--------------------------------------------
    //Obligatory checking if the search is within the specified range
    if (Minimum < RangeMinimum) Minimum = RangeMinimum;
    if (Maximum > RangeMaximum) Maximum = RangeMaximum;
    //---------------------------------------------------------------
    temp=RNDfromCI(Minimum,Maximum);
    child[i]=
    SelectInDiscreteSpace(temp,RangeMinimum,RangeMaximum,Precision,3);
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Natural Mutation.
void NaturalMutation
(
double &child[],
double  NMutationProbability
)
{
  //-----------------------Variables-------------------------------------
  int    address=0;
  //----------------------------------------------------------------------

  //-----------------Selection of parent------------------------
  SelectOneParent(address);
  //---------------------------------------
  for (int i=1;i<=GeneCount;i++)
    if (RNDfromCI(0.0,100.0)<=NMutationProbability)
      child[i]=
      SelectInDiscreteSpace(RNDfromCI(RangeMinimum,RangeMaximum),RangeMinimum,RangeMaximum,Precision,3);
    else
      child[i]=Population[i][address];
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Artificial Mutation.
void ArtificialMutation
(
double &child[],
double  ReplicationOffset
)
{
  //-----------------------Variables-------------------------------------
  double C1=0.0,C2=0.0,temp=0.0,Maximum=0.0,Minimum=0.0,p=0.0;
  int address_mama=0,address_papa=0;
  //----------------------------------------------------------------------
  //-----------------Selection of parents------------------------
  SelectTwoParents(address_mama,address_papa);
  //--------------------------------------------------------
  //-------------------Cycle of searching genes------------------------------
  for (int i=1;i<=GeneCount;i++)
  {
    //----Determine where do mother and father come from--------
    C1 = Population[i][address_mama];
    C2 = Population[i][address_papa];
    //------------------------------------------

    //------------------------------------------------------------------
    //....determine the largest and the smallest of them,
    //if Ñ1>C2, switch their places
    if (C1>C2)
    {
      temp=C1; C1=C2; C2=temp;
    }
    //--------------------------------------------
    //Set the borders of creation of new gene
    Minimum=C1-((C2-C1)*ReplicationOffset);
    Maximum=C2+((C2-C1)*ReplicationOffset);
    //--------------------------------------------
    //Obligatory checking if the search is within the specified range
    if (Minimum < RangeMinimum) Minimum = RangeMinimum;
    if (Maximum > RangeMaximum) Maximum = RangeMaximum;
    //---------------------------------------------------------------
    p=MathRand();
    if (p<16383.5)
    {
      temp=RNDfromCI(RangeMinimum,Minimum);
      child[i]=
      SelectInDiscreteSpace(temp,RangeMinimum,RangeMaximum,Precision,3);
    }
    else
    {
      temp=RNDfromCI(Maximum,RangeMaximum);
      child[i]=
      SelectInDiscreteSpace(temp,RangeMinimum,RangeMaximum,Precision,3);
    }
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Adoption of genes.
void GenoMerging
(
double &child[]
)
{
  //-----------------------Variables-------------------------------------
  int  address=0;
  //----------------------------------------------------------------------
  for (int i=1;i<=GeneCount;i++)
  {
    //-----------------Selection of parent------------------------
    SelectOneParent(address);
    //--------------------------------------------------------
    child[i]=Population[i][address];
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Crossing Over.
void CrossingOver
(
double &child[]
)
{
  //-----------------------Variables-------------------------------------
  int address_mama=0,address_papa=0;
  //----------------------------------------------------------------------
  //-----------------Selection of parents------------------------
  SelectTwoParents(address_mama,address_papa);
  //--------------------------------------------------------
  //Determine the point of break
  int address_of_gene=(int)MathFloor((GeneCount-1)*(MathRand()/32767.5));

  for (int i=1;i<=GeneCount;i++)
  {
    //----copy mother's genes--------
    if (i<=address_of_gene+1)
      child[i]=Population[i][address_mama];
    //----copy father's genes--------
    else
      child[i]=Population[i][address_papa];
  }
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Selection of two parents.
void SelectTwoParents
(
int &address_mama,
int &address_papa
)
{
  //-----------------------Variables-------------------------------------
  int cnt=1;
  address_mama=0;//address of the mother individual in population
  address_papa=0;//address of the father individual in the population
  //----------------------------------------------------------------------
  //----------------------------Selection of parents--------------------------
  //Ten attempts to choose different parents.
  while (cnt<=10)
  {
    //For the mother individual
    address_mama=NaturalSelection();
    //For the father individual
    address_papa=NaturalSelection();
    if (address_mama!=address_papa)
      break;
    cnt++;
  }
  //---------------------------------------------------------------------
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Selection of one parent.
void SelectOneParent
(
int &address//address of the parent individual in population
)
{
  //-----------------------Variables-------------------------------------
  address=0;
  //----------------------------------------------------------------------
  //----------------------------Selection of parent--------------------------
  address=NaturalSelection();
  //---------------------------------------------------------------------
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Natural selection.
int NaturalSelection()
{
  //-----------------------Variables-------------------------------------
  int    i=0,u=0;
  double p=0.0,start=0.0;
  double          fit[][2];
  ArrayResize    (fit,PopulChromosCount);
  ArrayInitialize(fit,0.0);
  double delta=(Population[0][0]-Population[0][PopulChromosCount-1])*0.01-Population[0][PopulChromosCount-1];
  //----------------------------------------------------------------------

  for (i=0;i<PopulChromosCount;i++)
  {
    fit[i][0]=start;
    fit[i][1]=start+MathAbs(Population[0][i]+delta);
    start=fit[i][1];
  }
  p=RNDfromCI(fit[0][0],fit[PopulChromosCount-1][1]);

  for (u=0;u<PopulChromosCount;u++)
    if ((fit[u][0]<=p && p<fit[u][1]) || p==fit[u][1])
      break;

  return(u);
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Deletion of duplicates with the sorting by VFF
void RemovalDuplicates()
{
  //-----------------------Variables-------------------------------------
  int             chromosomeUnique[1000];//The array stores the sign of uniqueness 
                                         //of each chromosome: 0-duplicate, 1-unique
  ArrayInitialize(chromosomeUnique,1);   //Suppose that there's no duplicates
  double          PopulationTemp[][1000];
  ArrayResize    (PopulationTemp,GeneCount+1);
  ArrayInitialize(PopulationTemp,0.0);

  int Ge =0;                             //Index of a gene
  int Ch =0;                             //Index of a chromosome
  int Ch2=0;                             //Index of a second chromosome
  int cnt=0;                             //Counter
  //----------------------------------------------------------------------

  //----------------------Delete duplicates---------------------------1
  //Select the first one from a pair to compare...
  for (Ch=0;Ch<PopulChromosCount-1;Ch++)
  {
    //If it is not a duplicate...
    if (chromosomeUnique[Ch]!=0)
    {
      //Choose the second one from the pair...
      for (Ch2=Ch+1;Ch2<PopulChromosCount;Ch2++)
      {
        if (chromosomeUnique[Ch2]!=0)
        {
          //Zeroize  the counter of identical genes
          cnt=0;
          //Compare genes until there no identical genes
          for (Ge=1;Ge<=GeneCount;Ge++)
          {
            if (Population[Ge][Ch]!=Population[Ge][Ch2])
              break;
            else
              cnt++;
          }
          //if the number of identical genes is the sane as the genes in total
          //..the chromosome is considered to be a duplicate
          if (cnt==GeneCount)
            chromosomeUnique[Ch2]=0;
        }
      }
    }
  }
  //The counter will calculate the number of unique chromosomes
  cnt=0;
  //Copy the unique chromosomes to a temporary array
  for (Ch=0;Ch<PopulChromosCount;Ch++)
  {
    //If a chromosome is uniqe, copy it; if it is not, go to the next one
    if (chromosomeUnique[Ch]==1)
    {
      for (Ge=0;Ge<=GeneCount;Ge++)
        PopulationTemp[Ge][cnt]=Population[Ge][Ch];
      cnt++;
    }
  }
  //Assign the value of the counter of unique chromosomes to the "Total number of chromosomes" variable
  PopulChromosCount=cnt;
  //Return the unique chromosomes back to the array for temporary storing 
  //..unite populations 
  for (Ch=0;Ch<PopulChromosCount;Ch++)
    for (Ge=0;Ge<=GeneCount;Ge++)
      Population[Ge][Ch]=PopulationTemp[Ge][Ch];
  //=================================================================1

  //----------------Ranking of population---------------------------2
  PopulationRanking();
  //=================================================================2
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Ranking of population.
void PopulationRanking()
{
  //-----------------------Variables-------------------------------------
  int cnt=1, i = 0, u = 0;
  double          PopulationTemp[][1000];           //Temporary population 
  ArrayResize    (PopulationTemp,GeneCount+1);
  ArrayInitialize(PopulationTemp,0.0);

  int             Indexes[];                        //Indexes of chromosomes
  ArrayResize    (Indexes,PopulChromosCount);
  ArrayInitialize(Indexes,0);
  int    t0=0;
  double          ValueOnIndexes[];                 //VFF of the corresponding
                                                    //..indexes of chromosomes
  ArrayResize    (ValueOnIndexes,PopulChromosCount);
  ArrayInitialize(ValueOnIndexes,0.0); double t1=0.0;
  //----------------------------------------------------------------------

  //Place the indexes to the temp2 temporary array and 
  //...copy the first line from the sorted array
  for (i=0;i<PopulChromosCount;i++)
  {
    Indexes[i] = i;
    ValueOnIndexes[i] = Population[0][i];
  }
  if (OptimizeMethod==1)
  {
    while (cnt>0)
    {
      cnt=0;
      for (i=0;i<PopulChromosCount-1;i++)
      {
        if (ValueOnIndexes[i]>ValueOnIndexes[i+1])
        {
          //-----------------------
          t0 = Indexes[i+1];
          t1 = ValueOnIndexes[i+1];
          Indexes   [i+1] = Indexes[i];
          ValueOnIndexes   [i+1] = ValueOnIndexes[i];
          Indexes   [i] = t0;
          ValueOnIndexes   [i] = t1;
          //-----------------------
          cnt++;
        }
      }
    }
  }
  else
  {
    while (cnt>0)
    {
      cnt=0;
      for (i=0;i<PopulChromosCount-1;i++)
      {
        if (ValueOnIndexes[i]<ValueOnIndexes[i+1])
        {
          //-----------------------
          t0 = Indexes[i+1];
          t1 = ValueOnIndexes[i+1];
          Indexes   [i+1] = Indexes[i];
          ValueOnIndexes   [i+1] = ValueOnIndexes[i];
          Indexes   [i] = t0;
          ValueOnIndexes   [i] = t1;
          //-----------------------
          cnt++;
        }
      }
    }
  }
  //Created a sorted array by the obtained indexes
  for (i=0;i<GeneCount+1;i++)
    for (u=0;u<PopulChromosCount;u++)
      PopulationTemp[i][u]=Population[i][Indexes[u]];
  //Copy the sorted array back
  for (i=0;i<GeneCount+1;i++)
    for (u=0;u<PopulChromosCount;u++)
      Population[i][u]=PopulationTemp[i][u];
}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Generator of random number from a specified range
double RNDfromCI(double Minimum,double Maximum) 
{ return(Minimum+((Maximum-Minimum)*MathRand()/32767.5));}
//————————————————————————————————————————————————————————————————————————

//————————————————————————————————————————————————————————————————————————
//Selection in a discrete space.
//Modes:
//1-closest from bottom
//2-closest from top
//any one to the closest
double SelectInDiscreteSpace
(
double In, 
double InMin, 
double InMax, 
double step, 
int    RoundMode
)
{
  if (step==0.0)
    return(In);
  // provide the correctness of borders
  if ( InMax < InMin )
  {
    double temp = InMax; InMax = InMin; InMin = temp;
  }
  // return the broken border if it is broken
  if ( In < InMin ) return( InMin );
  if ( In > InMax ) return( InMax );
  if ( InMax == InMin || step <= 0.0 ) return( InMin );
  // cast to the specified scale
  step = (InMax - InMin) / MathCeil ( (InMax - InMin) / step );
  switch ( RoundMode )
  {
  case 1:  return( InMin + step * MathFloor ( ( In - InMin ) / step ) );
  case 2:  return( InMin + step * MathCeil  ( ( In - InMin ) / step ) );
  default: return( InMin + step * MathRound ( ( In - InMin ) / step ) );
  }
}
//————————————————————————————————————————————————————————————————————————
