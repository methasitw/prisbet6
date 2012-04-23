//+------------------------------------------------------------------+
//|                                                        Panel.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include "WndObj.mqh"
#include <ChartObjects\ChartObjectsTxtControls.mqh>
//+------------------------------------------------------------------+
//| Class CPanel                                                     |
//| Usage: control that is displayed by                              |
//|             the CChartObjectRectLabel object                     |
//+------------------------------------------------------------------+
class CPanel : public CWndObj
  {
private:
   CChartObjectRectLabel  m_rectangle;      // chart object
   //--- parameters of the chart object
   ENUM_BORDER_TYPE  m_border;              // border type

public:
                     CPanel(void);
                    ~CPanel(void);
   //--- create
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
   //--- parameters of the chart object
   ENUM_BORDER_TYPE  BorderType(void)       const { return(m_border);                                  }
   bool              BorderType(const ENUM_BORDER_TYPE type);

protected:
   //--- handlers of object settings
   virtual bool      OnSetText(void)              { return(m_rectangle.Description(m_text));           }
   virtual bool      OnSetColorBackground(void)   { return(m_rectangle.BackColor(m_color_background)); }
   virtual bool      OnSetColorBorder(void)       { return(m_rectangle.Color(m_color_border));         }
   //--- internal event handlers
   virtual bool      OnCreate(void);
   virtual bool      OnShow(void);
   virtual bool      OnHide(void);
   virtual bool      OnMove(void);
   virtual bool      OnResize(void);
   virtual bool      OnChange(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPanel::CPanel(void) : m_border(BORDER_FLAT)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPanel::~CPanel(void)
  {
  }
//+------------------------------------------------------------------+
//| Create a control                                                 |
//+------------------------------------------------------------------+
bool CPanel::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
  {
//--- call method of the parent class
   if(!CWndObj::Create(chart,name,subwin,x1,y1,x2,y2))               return(false);
//--- create the chart object
   if(!m_rectangle.Create(chart,name,subwin,x1,y1,Width(),Height())) return(false);
//--- call the settings handler
   return(OnChange());
  }
//+------------------------------------------------------------------+
//| Set border type                                                  |
//+------------------------------------------------------------------+
bool CPanel::BorderType(const ENUM_BORDER_TYPE type)
  {
//--- save new value of parameter
   m_border=type;
//--- set up the chart object
   return(m_rectangle.BorderType(type));
  }
//+------------------------------------------------------------------+
//| Create object on chart                                           |
//+------------------------------------------------------------------+
bool CPanel::OnCreate(void)
  {
//--- create the chart object by previously set parameters
   return(m_rectangle.Create(m_chart_id,m_name,m_subwin,m_rect.Left(),m_rect.Top(),m_rect.Width(),m_rect.Height()));
  }
//+------------------------------------------------------------------+
//| Display object on chart                                          |
//+------------------------------------------------------------------+
bool CPanel::OnShow(void)
  {
//--- position the chart object "in place"
   return(OnMove());
  }
//+------------------------------------------------------------------+
//| Hide object from chart                                           |
//+------------------------------------------------------------------+
bool CPanel::OnHide(void)
  {
//--- position the chart object beyond the left border of chart
   return(m_rectangle.X_Distance(CONTROLS_HIDE_X) && m_rectangle.Y_Distance(CONTROLS_HIDE_Y));
  }
//+------------------------------------------------------------------+
//| Absolute movement of the chart object                            |
//+------------------------------------------------------------------+
bool CPanel::OnMove(void)
  {
//--- position the chart object
   return(m_rectangle.X_Distance(m_rect.Left()) && m_rectangle.Y_Distance(m_rect.Top()));
  }
//+------------------------------------------------------------------+
//| Resize the chart object                                          |
//+------------------------------------------------------------------+
bool CPanel::OnResize(void)
  {
//--- resize the chart object
   return(m_rectangle.X_Size(m_rect.Width()) && m_rectangle.Y_Size(m_rect.Height()));
  }
//+------------------------------------------------------------------+
//| Set up the chart object                                          |
//+------------------------------------------------------------------+
bool CPanel::OnChange(void)
  {
//--- set up the chart object
   return(CWndObj::OnChange() && m_rectangle.BorderType(m_border));
  }
//+------------------------------------------------------------------+
