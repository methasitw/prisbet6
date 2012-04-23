//+------------------------------------------------------------------+
//|                                                     ComboBox.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include "WndContainer.mqh"
#include "Edit.mqh"
#include "BmpButton.mqh"
#include "ListView.mqh"
//+------------------------------------------------------------------+
//| Resources                                                        |
//+------------------------------------------------------------------+
//--- Can not place the same file into resource twice
#resource "res\\DropOn.bmp"                 // image file
#resource "res\\DropOff.bmp"                // image file
//+------------------------------------------------------------------+
//| Class CComboBox                                                  |
//| Usage: drop-down list                                            |
//+------------------------------------------------------------------+
class CComboBox : public CWndContainer
  {
private:
   //--- dependent controls
   CEdit             m_edit;                // the entry field object
   CBmpButton        m_drop;                // the button object
   CListView         m_list;                // the drop-down list object
   //--- set up
   int               m_item_height;         // height of visible row
   int               m_view_items;          // number of visible rows in the drop-down list

public:
                     CComboBox(void);
                    ~CComboBox(void);
   //--- create
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
   //--- chart event handler
   virtual bool      OnEvent(const int id,const long& lparam,const double& dparam,const string& sparam);
   //--- fill
   bool              AddItem(const string item,const long value=0);
   //--- set up
   void              ListViewItems(const int value) { m_view_items=value;     }
   //--- data
   string            Select(void)                   { return(m_edit.Text());  }
   bool              Select(const int index);
   bool              SelectByText(const string text);
   bool              SelectByValue(const long value);
   //--- data (read only)
   long              Value(void)                    { return(m_list.Value()); }

protected:
   //--- create dependent controls
   virtual bool      CreateEdit(void);
   virtual bool      CreateButton(void);
   virtual bool      CreateList(void);
   //--- handlers of the dependent controls events
   virtual bool      OnClickEdit(void);
   virtual bool      OnClickButton(void);
   virtual bool      OnChangeList(void);
   //--- show drop-down list
   bool              ListShow(void);
   bool              ListHide(void);
  };
//+------------------------------------------------------------------+
//| Common handler of chart events                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CComboBox)
   ON_EVENT(ON_CLICK,m_edit,OnClickEdit)
   ON_EVENT(ON_CLICK,m_drop,OnClickButton)
   ON_EVENT(ON_CHANGE,m_list,OnChangeList)
EVENT_MAP_END(CWndContainer)
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CComboBox::CComboBox(void) : m_item_height(CONTROLS_COMBO_ITEM_HEIGHT),
                             m_view_items(CONTROLS_COMBO_ITEMS_VIEW)

  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CComboBox::~CComboBox(void)
  {
  }
//+------------------------------------------------------------------+
//| Create a control                                                 |
//+------------------------------------------------------------------+
bool CComboBox::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
  {
//--- check height
   if(y2-y1<CONTROLS_COMBO_MIN_HEIGHT)                                        return(false);
//--- call method of the parent class
   if(!CWndContainer::Create(chart,name,subwin,x1,y1,x2,y2))                  return(false);
//--- create dependent controls
   if(!CreateEdit())                                                          return(false);
   if(!CreateButton())                                                        return(false);
   if(!CreateList())                                                          return(false);
//--- succeeded
   return(true);
  }
//+------------------------------------------------------------------+
//| Create main entry field                                          |
//+------------------------------------------------------------------+
bool CComboBox::CreateEdit(void)
  {
//--- create
   if(!m_edit.Create(m_chart_id,m_name+"Edit",m_subwin,0,0,Width(),Height())) return(false);
   if(!m_edit.Text(""))                                                       return(false);
   if(!m_edit.ReadOnly(true))                                                 return(false);
   if(!Add(m_edit))                                                           return(false);
//--- succeeded
   return(true);
  }
//+------------------------------------------------------------------+
//| Create button                                                    |
//+------------------------------------------------------------------+
bool CComboBox::CreateButton(void)
  {
//--- right align button (try to make equal offsets from top and bottom)
   int x1=Width()-(CONTROLS_BUTTON_SIZE+CONTROLS_COMBO_BUTTON_X_OFF);
   int y1=(Height()-CONTROLS_BUTTON_SIZE)/2;
   int x2=x1+CONTROLS_BUTTON_SIZE;
   int y2=y1+CONTROLS_BUTTON_SIZE;
//--- create
   if(!m_drop.Create(m_chart_id,m_name+"Drop",m_subwin,x1,y1,x2,y2))          return(false);
   if(!m_drop.BmpNames("::res\\DropOff.bmp","::res\\DropOn.bmp"))             return(false);
   if(!Add(m_drop))                                                           return(false);
   m_drop.Locking(true);
//--- succeeded
   return(true);
  }
//+------------------------------------------------------------------+
//| Create drop-down list                                            |
//+------------------------------------------------------------------+
bool CComboBox::CreateList(void)
  {
//--- create
   if(!m_list.TotalView(m_view_items))                                        return(false);
   if(!m_list.Create(m_chart_id,m_name+"List",m_subwin,0,Height(),Width(),0)) return(false);
   if(!Add(m_list))                                                           return(false);
   m_list.Visible(false);
//--- succeeded
   return(true);
  }
//+------------------------------------------------------------------+
//| Add item (row)                                                   |
//+------------------------------------------------------------------+
bool CComboBox::AddItem(const string item,const long value)
  {
//--- add item to list
   return(m_list.AddItem(item,value));
  }
//+------------------------------------------------------------------+
//| Select item                                                      |
//+------------------------------------------------------------------+
bool CComboBox::Select(const int index)
  {
   if(!m_list.Select(index)) return(false);
//--- call the handler
   return(OnChangeList());
  }
//+------------------------------------------------------------------+
//| Select item (by text)                                            |
//+------------------------------------------------------------------+
bool CComboBox::SelectByText(const string text)
  {
   if(!m_list.SelectByText(text)) return(false);
//--- call the handler
   return(OnChangeList());
  }
//+------------------------------------------------------------------+
//| Select item (by value)                                           |
//+------------------------------------------------------------------+
bool CComboBox::SelectByValue(const long value)
  {
   if(!m_list.SelectByValue(value)) return(false);
//--- call the handler
   return(OnChangeList());
  }
//+------------------------------------------------------------------+
//| Handler of click on main entry field                             |
//+------------------------------------------------------------------+
bool CComboBox::OnClickEdit(void)
  {
//--- change button state
   if(!m_drop.Pressed(!m_drop.Pressed())) return(false);
//--- call the click on button handler
   return(OnClickButton());
  }
//+------------------------------------------------------------------+
//| Handler of click on button                                       |
//+------------------------------------------------------------------+
bool CComboBox::OnClickButton(void)
  {
//--- show or hide the drop-down list depending on the button state
   return((m_drop.Pressed()) ? ListShow():ListHide());
  }
//+------------------------------------------------------------------+
//| Handler of click on drop-down list                               |
//+------------------------------------------------------------------+
bool CComboBox::OnChangeList(void)
  {
   string text=m_list.Select();
//--- hide the list, depress the button
   ListHide();
   m_drop.Pressed(false);
//--- set text in the main entry field
   m_edit.Text(text);
//--- send notification
   return(EventChartCustom(m_chart_id,ON_CHANGE,m_id,0.0,m_name));
  }
//+------------------------------------------------------------------+
//| Show the drop-down list                                          |
//+------------------------------------------------------------------+
bool CComboBox::ListShow(void)
  {
//--- show the list
   return(m_list.Visible(true));
  }
//+------------------------------------------------------------------+
//| Hide drop-down list                                              |
//+------------------------------------------------------------------+
bool CComboBox::ListHide(void)
  {
//--- hide the list
   return(m_list.Visible(false));
  }
//+------------------------------------------------------------------+
