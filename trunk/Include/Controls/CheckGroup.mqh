//+------------------------------------------------------------------+
//|                                                   CheckGroup.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include "WndClient.mqh"
#include "CheckBox.mqh"
#include <Arrays\ArrayString.mqh>
#include <Arrays\ArrayLong.mqh>
//+------------------------------------------------------------------+
//| Class CCheckGroup                                                |
//| Usage: view and edit group of flags                              |
//+------------------------------------------------------------------+
class CCheckGroup : public CWndClient
  {
private:
   //--- dependent controls
   CCheckBox         m_rows[];              // array of the row objects
   //--- set up
   int               m_offset;              // index of first visible row in array of rows
   int               m_total_view;          // number of visible rows
   int               m_item_height;         // height of visible row
   //--- data
   CArrayString      m_strings;             // array of rows
   CArrayLong        m_values;              // array of values
   long              m_value;               // group value
   int               m_current;             // index of current row in array of rows

public:
                     CCheckGroup(void);
                    ~CCheckGroup(void);
   //--- create
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
   //--- chart event handler
   virtual bool      OnEvent(const int id,const long& lparam,const double& dparam,const string& sparam);
   //--- fill
   virtual bool      AddItem(const string item,const long value=0);
   //--- data (read only)
   long              Value(void)           { return(m_value); }

protected:
   //--- create dependent controls
   bool              CreateButton(int index);
   //--- handlers of the dependent controls events
   virtual bool      OnVScrollShow(void);
   virtual bool      OnVScrollHide(void);
   virtual bool      OnScrollLineDown(void);
   virtual bool      OnScrollLineUp(void);
   virtual bool      OnChangeItem(const int index);
   //--- redraw
   bool              Redraw(void);
   bool              RowState(const int index,const bool select);
  };
//+------------------------------------------------------------------+
//| Common handler of chart events                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CCheckGroup)
   ON_INDEXED_EVENT(ON_CHANGE,m_rows,OnChangeItem)
EVENT_MAP_END(CWndClient)
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CCheckGroup::CCheckGroup(void) : m_offset(0),
                                 m_total_view(0),
                                 m_item_height(CONTROLS_LIST_ITEM_HEIGHT),
                                 m_current(CONTROLS_INVALID_INDEX),
                                 m_value(0)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CCheckGroup::~CCheckGroup(void)
  {
  }
//+------------------------------------------------------------------+
//| Create a control                                                 |
//+------------------------------------------------------------------+
bool CCheckGroup::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
  {
//--- determine the number of visible rows
   m_total_view=(y2-y1)/m_item_height;
//--- check the number of visible rows
   if(m_total_view<1)                                              return(false);
//--- call method of the parent class
   if(!CWndClient::Create(chart,name,subwin,x1,y1,x2,y2))          return(false);
//--- set up
   if(!m_background.ColorBackground(CONTROLS_CHECKGROUP_COLOR_BG)) return(false);
   if(!m_background.ColorBorder(CONTROLS_CHECKGROUP_COLOR_BORDER)) return(false);
//--- create dependent controls
   ArrayResize(m_rows,m_total_view);
   for(int i=0;i<m_total_view;i++)
      if(!CreateButton(i))                                         return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create "row"                                                     |
//+------------------------------------------------------------------+
bool CCheckGroup::CreateButton(int index)
  {
//--- calculate coordinates
   int x1=CONTROLS_BORDER_WIDTH;
   int y1=CONTROLS_BORDER_WIDTH+m_item_height*index;
   int x2=Width()-CONTROLS_BORDER_WIDTH;
   int y2=y1+m_item_height;
//--- create
   if(!m_rows[index].Create(m_chart_id,m_name+"Item"+IntegerToString(index),
                            m_subwin,x1,y1,x2,y2))                 return(false);
   if(!m_rows[index].Text(""))                                     return(false);
   if(!Add(m_rows[index]))                                         return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Add item (row)                                                   |
//+------------------------------------------------------------------+
bool CCheckGroup::AddItem(const string item,const long value)
  {
//--- add
   if(!m_strings.Add(item)) return(false);
   if(!m_values.Add(value)) return(false);
//--- number of items
   int total=m_strings.Total();
//--- exit if number of items does not exceed the size of visible area
   if(total<m_total_view+1) return(Redraw());
//--- if number of items exceeded the size of visible area
   if(total==m_total_view+1)
     {
      //--- enable vertical scrollbar
      if(!VScrolled(true)) return(false);
      //--- and immediately make it invisible (if needed)
      if(!IS_VISIBLE)      m_scroll_v.Visible(false);
      
     }
//--- set up the scrollbar
   m_scroll_v.MaxPos(m_strings.Total()-m_total_view);
//--- redraw
   return(Redraw());
  }
//+------------------------------------------------------------------+
//| Redraw                                                           |
//+------------------------------------------------------------------+
bool CCheckGroup::Redraw(void)
  {
//--- loop by "rows"
   for(int i=0;i<m_total_view;i++)
     {
      //--- copy text
      if(!m_rows[i].Text(m_strings.At(i+m_offset))) return(false);
      //--- select
      if(!RowState(i,(m_current==i+m_offset)))      return(false);
     }
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Change state                                                     |
//+------------------------------------------------------------------+
bool CCheckGroup::RowState(const int index,const bool select)
  {
//--- check index
   if(index<0 || index>=ArraySize(m_rows)) return(true);
//--- change state
   return(m_rows[index].Checked(select));
  }
//+------------------------------------------------------------------+
//| Handler of the "Show vertical scrollbar" event                   |
//+------------------------------------------------------------------+
bool CCheckGroup::OnVScrollShow(void)
  {
//--- loop by "rows"
   for(int i=0;i<m_total_view;i++)
     {
      //--- resize "rows" according to shown vertical scrollbar
      m_rows[i].Width(Width()-(CONTROLS_SCROLL_SIZE+CONTROLS_BORDER_WIDTH));
     }
//--- check visibility
   if(!IS_VISIBLE)
     {
      m_scroll_v.Visible(false);
      return(true);
     }
//--- event is handled
   return(true);
  }
//+------------------------------------------------------------------+
//| Handler of the "Hide vertical scrollbar" event                   |
//+------------------------------------------------------------------+
bool CCheckGroup::OnVScrollHide(void)
  {
//--- check visibility
   if(!IS_VISIBLE) return(true);
//--- loop by "rows"
   for(int i=0;i<m_total_view;i++)
     {
      //--- resize "rows" according to hidden vertical scroll bar
      m_rows[i].Width(Width()-CONTROLS_BORDER_WIDTH);
     }
//--- event is handled
   return(true);
  }
//+------------------------------------------------------------------+
//| Handler of the "Scroll up for one row" event                     |
//+------------------------------------------------------------------+
bool CCheckGroup::OnScrollLineUp(void)
  {
//--- get new offset
   m_offset=m_scroll_v.CurrPos();
//--- redraw
   return(Redraw());
  }
//+------------------------------------------------------------------+
//| Handler of the "Scroll down for one row" event                   |
//+------------------------------------------------------------------+
bool CCheckGroup::OnScrollLineDown(void)
  {
//--- get new offset
   m_offset=m_scroll_v.CurrPos();
//--- redraw
   return(Redraw());
  }
//+------------------------------------------------------------------+
//| Handler of changing a "row" state                                |
//+------------------------------------------------------------------+
bool CCheckGroup::OnChangeItem(const int index)
  {
//--- change value
   if(m_rows[index].Checked())    m_value+=m_values.At(index+m_offset);
   else                           m_value-=m_values.At(index+m_offset);
//--- send notification
   return(EventChartCustom(m_chart_id,ON_CHANGE,m_id,0.0,m_name));
  }
//+------------------------------------------------------------------+
