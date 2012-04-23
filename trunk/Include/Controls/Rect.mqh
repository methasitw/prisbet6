//+------------------------------------------------------------------+
//|                                                         Rect.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Class Point                                                      |
//| Usage: point of chart in Cartesian coordinates                   |
//+------------------------------------------------------------------+
class CPoint
  {
public:
   int               m_x;                   // horizontal coordinate
   int               m_y;                   // vertical coordinate

public:
                     CPoint(void);
                     CPoint(const int x,const int y);
                    ~CPoint(void);
   //--- methods
   void              Move(const int x,const int y)    { m_x=x; m_y=y;     }
   void              Shift(const int dx,const int dy) { m_x+=dx; m_y+=dy; }
   //--- format
   string            Format(string& fmt)      const;
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPoint::CPoint(void) : m_x(0), m_y(0)
  {
  }
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPoint::CPoint(const int x,const int y) : m_x(x), m_y(y)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPoint::~CPoint(void)
  {
  }
//+------------------------------------------------------------------+
//| Formatted output to row                                          |
//+------------------------------------------------------------------+
string CPoint::Format(string& fmt) const
  {
//--- clear
   fmt="";
//--- formatting
   fmt=StringFormat("(%d,%d)",m_x,m_y);
//--- return
   return(fmt);
  }
//+------------------------------------------------------------------+
//| Class CRect                                                      |
//| Usage: area of chart in Cartesian coordinates                    |
//+------------------------------------------------------------------+
class CRect
  {
public:
   CPoint            m_lt;                  // upper left point
   CPoint            m_rb;                  // lower right point

public:
                     CRect(void);
                     CRect(const int l,const int t,const int r,const int b);
                    ~CRect(void);
   //--- data
   int               Left(void)               const { return(m_lt.m_x);       }
   void              Left(const int x)              { m_lt.m_x=x;             }
   int               Top(void)                const { return(m_lt.m_y);       }
   void              Top(const int y)               { m_lt.m_y=y;             }
   int               Right(void)              const { return(m_rb.m_x);       }
   void              Right(const int x)             { m_rb.m_x=x;             }
   int               Bottom(void)             const { return(m_rb.m_y);       }
   void              Bottom(const int y)            { m_rb.m_y=y;             }
   //--- methods
   int               Width(void)              const { return(Right()-Left()); }
   void              Width(const int w)             { m_rb.m_x=m_lt.m_x+w;    }
   int               Height(void)             const { return(Bottom()-Top()); }
   void              Height(const int h)            { m_rb.m_y=m_lt.m_y+h;    }
   void              SetBound(const int l,const int t,const int r,const int b);
   void              SetBound(const CRect& rect);
   void              Move(const int x,const int y);
   void              Shift(const int dx,const int dy);
   bool              Contains(const int x,const int y) const;
   //--- format
   string            Format(string& fmt)      const;
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRect::CRect(void) : m_lt(), m_rb()
  {
  }
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRect::CRect(const int l,const int t,const int r,const int b) : m_lt(l,t), m_rb(r,b)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRect::~CRect(void)
  {
  }
//+------------------------------------------------------------------+
//| Set parameters of area                                           |
//+------------------------------------------------------------------+
void CRect::SetBound(const int l,const int t,const int r,const int b)
  {
//--- save parameters
   m_lt.m_x=l;
   m_lt.m_y=t;
   m_rb.m_x=r;
   m_rb.m_y=b;
  }
//+------------------------------------------------------------------+
//| Set parameters of area                                           |
//+------------------------------------------------------------------+
void CRect::SetBound(const CRect& rect)
  {
//--- save parameters
   m_lt.m_x=rect.Left();
   m_lt.m_y=rect.Top();
   m_rb.m_x=rect.Right();
   m_rb.m_y=rect.Bottom();
  }
//+------------------------------------------------------------------+
//| Absolute movement of area                                        |
//+------------------------------------------------------------------+
void CRect::Move(const int x,const int y)
  {
//--- calculate shifts
   int dx=x-Left();
   int dy=y-Top();
//--- move points
   m_lt.Move(x,y);
   m_rb.Shift(dx,dy);
  }
//+------------------------------------------------------------------+
//| Relative movement of area                                        |
//+------------------------------------------------------------------+
void CRect::Shift(const int dx,const int dy)
  {
//--- move points
   m_lt.Shift(dx,dy);
   m_rb.Shift(dx,dy);
  }
//+------------------------------------------------------------------+
//| Check if a point is within the area                              |
//+------------------------------------------------------------------+
bool CRect::Contains(const int x,const int y) const
  {
//--- check and return the result
   return(x>=Left() && x<=Right() && y>=Top() && y<=Bottom());
  }
//+------------------------------------------------------------------+
//| Formatted output to row                                          |
//+------------------------------------------------------------------+
string CRect::Format(string& fmt) const
  {
   string lt,rb;
//--- clear
   fmt="";
//--- formatting
   fmt=StringFormat("(%s,%s)",m_lt.Format(lt),m_rb.Format(rb));
//--- return
   return(fmt);
  }
//+------------------------------------------------------------------+
