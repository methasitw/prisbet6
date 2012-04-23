//+------------------------------------------------------------------+
//|                                              Data structures.mqh |
//|                                                  Roman Martynyuk |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Roman Martynyuk"
#property link      "http://www.mql5.com"

// The structure for storing the points, found by the zigzag
struct TPoints
  {
   double            ValuePoints[];   // the values of the found points
   int               IndexPoints[];   // the indexes of the found points
   int               NumPoints;       // the number of found points
  };

// A class for storing the parameters of a wave
class TWave
  {
public:
   string            Name;            // name of the wave
   string            Formula;         // the formula of the wave (1-2-3-4-5, <1-2-3 etc.)
   int               Level;           // the level of the wave
   double            ValueVertex[6];  // the value of the top of the wave
   int               IndexVertex[6];  // the indexes of the top of the waves
  };
// A class for the presentation of the tree of the waves
class TNode:public CObject
  {
public:
   CArrayObj        *Child;    // node childs
   TWave            *Wave;     // wave
   string            Text;     // node text
   TNode            *Add(string Text,TWave *Wave=NULL) // function of adding a node into the tree
     {
      TNode *Node=new TNode;
      Node.Child=new CArrayObj;
      Node.Text =Text;
      Node.Wave=Wave;
      Child.Add(Node);
      return(Node);
     }
  };
// The structure of the description of the analyzed waves in the program
struct TWaveDescription
  {
   string            NameWave;    // name of the wave
   int               NumWave;     // number of sub-waves in a wave
   string            Subwaves[6]; // the names of the possible sub-waves in the wave
  };
// A class for storing the marking of waves before placing them on the chart
class TLabel:public CObject
  {
public:
   double            Value;  // the value of the vertex
   int               Level;  // the level of the wave
   string            Text;   // the marking of the wave
  };
// A class for storing the values of vertexes and indexes of the zigzag
class TZigzag:public CObject
  {
public:
   CArrayInt        *IndexVertex;    // indexes of the vertexes of the zigzag
   CArrayDouble     *ValueVertex;    // value of the vertexes of the zigzags
  };
// A class for storing the parameters of the already analyzed section, corresponding to the wave tree node
class TNodeInfo:CObject
  {
public:
   int               IndexStart,IndexFinish;  // the range of the already analyzed section
   double            ValueStart,ValueFinish;  // the edge value of the already analyzed section
   string            Subwaves;                // the name of the wave and the group of the waves
   TNode            *Node;                    // the node, pointing to the already analyzed range of the chart
  };
//+------------------------------------------------------------------+
