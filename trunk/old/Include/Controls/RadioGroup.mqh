//+------------------------------------------------------------------+
//|                                                   RadioGroup.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include "WndClient.mqh"
#include "RadioButton.mqh"
#include <Arrays\ArrayString.mqh>
#include <Arrays\ArrayLong.mqh>
//+------------------------------------------------------------------+
//| Class CRadioGroup                                                |
//| Usage: view and edit radio buttons                               |
//+------------------------------------------------------------------+
class CRadioGroup : public CWndClient
  {
private:
   //--- dependent controls
   CRadioButton      m_rows[];              // array of the row objects
   //--- set up
   int               m_offset;              // index of first visible row in array of rows
   int               m_total_view;          // number of visible rows
   int               m_item_height;         // height of visible row
   //--- data
   CArrayString      m_strings;             // array of rows
   CArrayLong        m_values;              // array of values
   int               m_current;             // index of current row in array of rows

public:
                     CRadioGroup(void);
                    ~CRadioGroup(void);
   //--- create
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
   //--- chart event handler
   virtual bool      OnEvent(const int id,const long& lparam,const double& dparam,const string& sparam);
   //--- fill
   virtual bool      AddItem(const string item,const long value=0);
   //--- data (read only)
   long              Value(void)       { return(m_values.At(m_current)); }

protected:
   //--- create dependent controls
   bool              CreateButton(const int index);
   //--- handlers of the dependent controls events
   virtual bool      OnVScrollShow(void);
   virtual bool      OnVScrollHide(void);
   virtual bool      OnScrollLineDown(void);
   virtual bool      OnScrollLineUp(void);
   virtual bool      OnChangeItem(const int index);
   //--- redraw
   bool              Redraw(void);
   bool              RowState(const int index,const bool select);
   void              Select(const int index);
  };
//+------------------------------------------------------------------+
//| Common handler of chart events                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CRadioGroup)
   ON_INDEXED_EVENT(ON_CHANGE,m_rows,OnChangeItem)
EVENT_MAP_END(CWndClient)
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRadioGroup::CRadioGroup(void) : m_offset(0),
                                 m_total_view(0),
                                 m_item_height(CONTROLS_LIST_ITEM_HEIGHT),
                                 m_current(CONTROLS_INVALID_INDEX)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRadioGroup::~CRadioGroup(void)
  {
  }
//+------------------------------------------------------------------+
//| Create a control                                                 |
//+------------------------------------------------------------------+
bool CRadioGroup::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
  {
//--- determine the number of visible rows
   m_total_view=(y2-y1)/m_item_height;
//--- check the number of visible rows
   if(m_total_view<1)                                              return(false);
//--- call method of the parent class
   if(!CWndClient::Create(chart,name,subwin,x1,y1,x2,y2))          return(false);
//--- set up
   if(!m_background.ColorBackground(CONTROLS_RADIOGROUP_COLOR_BG)) return(false);
   if(!m_background.ColorBorder(CONTROLS_RADIOGROUP_COLOR_BORDER)) return(false);
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
bool CRadioGroup::CreateButton(const int index)
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
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Add item (row)                                                   |
//+------------------------------------------------------------------+
bool CRadioGroup::AddItem(const string item,const long value)
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
//| Sett current item                                                |
//+------------------------------------------------------------------+
void CRadioGroup::Select(const int index)
  {
//--- disable the "ON" state
   if(m_current!=-1) RowState(m_current-m_offset,false);
//--- enable the "ON" state
   if(index!=-1)     RowState(index-m_offset,true);
//--- save value
   m_current=index;
  }
//+------------------------------------------------------------------+
//| Redraw                                                           |
//+------------------------------------------------------------------+
bool CRadioGroup::Redraw(void)
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
bool CRadioGroup::RowState(const int index,const bool select)
  {
//--- check index
   if(index<0 || index>=ArraySize(m_rows)) return(true);
//--- change state
   return(m_rows[index].State(select));
  }
//+------------------------------------------------------------------+
//| Handler of the "Show vertical scrollbar" event                   |
//+------------------------------------------------------------------+
bool CRadioGroup::OnVScrollShow(void)
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
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Handler of the "Hide vertical scrollbar" event                   |
//+------------------------------------------------------------------+
bool CRadioGroup::OnVScrollHide(void)
  {
//--- check visibility
   if(!IS_VISIBLE) return(true);
//--- loop by "rows"
   for(int i=0;i<m_total_view;i++)
     {
      //--- resize "rows" according to hidden vertical scroll bar
      m_rows[i].Width(Width()-CONTROLS_BORDER_WIDTH);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Handler of the "Scroll up for one row" event                     |
//+------------------------------------------------------------------+
bool CRadioGroup::OnScrollLineUp(void)
  {
//--- get new offset
   m_offset=m_scroll_v.CurrPos();
//--- redraw
   return(Redraw());
  }
//+------------------------------------------------------------------+
//| Handler of the "Scroll down for one row" event                   |
//+------------------------------------------------------------------+
bool CRadioGroup::OnScrollLineDown(void)
  {
//--- get new offset
   m_offset=m_scroll_v.CurrPos();
//--- redraw
   return(Redraw());
  }
//+------------------------------------------------------------------+
//| Handler of changing a "row" state                                |
//+------------------------------------------------------------------+
bool CRadioGroup::OnChangeItem(const int index)
  {
//--- select "row"
   Select(index+m_offset);
//--- send notification
   return(EventChartCustom(m_chart_id,ON_CHANGE,m_id,0.0,m_name));
  }
//+------------------------------------------------------------------+
