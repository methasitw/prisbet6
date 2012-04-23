//+------------------------------------------------------------------+
//|                                                  ArrayDouble.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include "Array.mqh"
//+------------------------------------------------------------------+
//| Class CArrayDouble.                                              |
//| Puprpose: Class of dynamic array variables of double type.       |
//|           Derives from class CArray.                             |
//+------------------------------------------------------------------+
class CArrayDouble : public CArray
  {
protected:
   double            m_data[];           // data array
   double            m_delta;            // search tolerance

public:
                     CArrayDouble(void);
                    ~CArrayDouble(void);
   //--- methods of access to protected data
   void              Delta(const double delta)                      { m_delta=MathAbs(delta); }
   //--- method of identifying the object
   virtual int       Type(void)                               const { return(TYPE_DOUBLE);    }
   //--- methods for working with files
   virtual bool      Save(const int file_handle);
   virtual bool      Load(const int file_handle);
   //--- methods of managing dynamic memory
   bool              Reserve(const int size);
   bool              Resize(const int size);
   bool              Shutdown(void);
   //--- methods of filling the array
   bool              Add(const double element);
   bool              AddArray(const double &src[]);
   bool              AddArray(const CArrayDouble *src);
   bool              Insert(const double element,const int pos);
   bool              InsertArray(const double &src[],const int pos);
   bool              InsertArray(const CArrayDouble *src,const int pos);
   bool              AssignArray(const double &src[]);
   bool              AssignArray(const CArrayDouble *src);
   //--- method of access to the array
   double            At(const int index)                      const;
   //--- methods of changing
   bool              Update(const int index,const double element);
   bool              Shift(const int index,const int shift);
   //--- methods of deleting
   bool              Delete(const int index);
   bool              DeleteRange(int from,int to);
   //--- methods for comparing arrays
   bool              CompareArray(const double &Array[])      const;
   bool              CompareArray(const CArrayDouble *Array)  const;
   //--- methods for working with a sorted array
   bool              InsertSort(const double element);
   int               Search(const double element)             const;
   int               SearchGreat(const double element)        const;
   int               SearchLess(const double element)         const;
   int               SearchGreatOrEqual(const double element) const;
   int               SearchLessOrEqual(const double element)  const;
   int               SearchFirst(const double element)        const;
   int               SearchLast(const double element)         const;
   int               SearchLinear(const double element)       const;

protected:
   virtual void      QuickSort(int beg,int end,const int mode=0);
   int               QuickSearch(const double element)        const;
   int               MemMove(const int dest,const int src,const int count);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CArrayDouble::CArrayDouble(void) : m_delta(0.0)
  {
   m_data_max=ArraySize(m_data);
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CArrayDouble::~CArrayDouble(void)
  {
   if(m_data_max!=0) Shutdown();
  }
//+------------------------------------------------------------------+
//| Moving the memory within a single array.                         |
//+------------------------------------------------------------------+
int CArrayDouble::MemMove(const int dest,const int src,const int count)
  {
   int i;
//--- checking
   if(dest<0 || src<0 || count<0) return(-1);
   if(dest+count>m_data_total)
     {
      if(Available()<dest+count) return(-1);
      else                       m_data_total=dest+count;
     }
//--- no need to copy
   if(dest==src || count==0) return(dest);
//--- copy
   if(dest<src)
     {
      //--- copy from left to right
      for(i=0;i<count;i++) m_data[dest+i]=m_data[src+i];
     }
   else
     {
      //--- copy from right to left
      for(i=count-1;i>=0;i--) m_data[dest+i]=m_data[src+i];
     }
//--- succeed
   return(dest);
  }
//+------------------------------------------------------------------+
//| Request for more memory in an array. Checks if the requested     |
//| number of free elements already exists; allocates additional     |
//| memory with a given step.                                        |
//+------------------------------------------------------------------+
bool CArrayDouble::Reserve(const int size)
  {
   int new_size;
//--- checking
   if(size<=0) return(false);
//--- resizing array
   if(Available()<size)
     {
      new_size=m_data_max+m_step_resize*(1+(size-Available())/m_step_resize);
      if(new_size<0)
        {
         //--- overflow occurred when calculating new_size
         return(false);
        }
      m_data_max=ArrayResize(m_data,new_size);
     }
//--- result
   return(Available()>=size);
  }
//+------------------------------------------------------------------+
//| Resizing (with removal of elements on the right).                |
//+------------------------------------------------------------------+
bool CArrayDouble::Resize(const int size)
  {
   int new_size;
//--- checking
   if(size<0) return(false);
//--- resizing array
   new_size=m_step_resize*(1+size/m_step_resize);
   if(m_data_max!=new_size) m_data_max=ArrayResize(m_data,new_size);
   if(m_data_total>size) m_data_total=size;
//--- result
   return(m_data_max==new_size);
  }
//+------------------------------------------------------------------+
//| Complete cleaning of the array with the release of memory.       |
//+------------------------------------------------------------------+
bool CArrayDouble::Shutdown(void)
  {
//--- checking
   if(m_data_max==0) return(true);
//--- cleaning
   if(ArrayResize(m_data,0)==-1) return(false);
   m_data_total=0;
   m_data_max=0;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Adding an element to the end of the array.                       |
//+------------------------------------------------------------------+
bool CArrayDouble::Add(const double element)
  {
//--- checking/reserve elements of array
   if(!Reserve(1)) return(false);
//--- adding
   m_data[m_data_total++]=element;
   m_sort_mode=-1;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Adding an element to the end of the array from another array.    |
//+------------------------------------------------------------------+
bool CArrayDouble::AddArray(const double &src[])
  {
   int num=ArraySize(src);
//--- checking/reserve elements of array
   if(!Reserve(num)) return(false);
//--- adding
   for(int i=0;i<num;i++) m_data[m_data_total++]=src[i];
   m_sort_mode=-1;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Adding an element to the end of the array from another array.    |
//+------------------------------------------------------------------+
bool CArrayDouble::AddArray(const CArrayDouble *src)
  {
   int num;
//--- checking
   if(!CheckPointer(src)) return(false);
//--- checking/reserve elements of array
   num=src.Total();
   if(!Reserve(num)) return(false);
//--- adding
   for(int i=0;i<num;i++) m_data[m_data_total++]=src.m_data[i];
   m_sort_mode=-1;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Inserting an element in the specified position.                  |
//+------------------------------------------------------------------+
bool CArrayDouble::Insert(const double element,const int pos)
  {
//--- checking/reserve elements of array
   if(pos<0 || !Reserve(1)) return(false);
//--- inserting
   m_data_total++;
   if(pos<m_data_total-1)
     {
      MemMove(pos+1,pos,m_data_total-pos-1);
      m_data[pos]=element;
     }
   else
      m_data[m_data_total-1]=element;
   m_sort_mode=-1;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Inserting elements in the specified position.                    |
//+------------------------------------------------------------------+
bool CArrayDouble::InsertArray(const double &src[],const int pos)
  {
   int num=ArraySize(src);
//--- checking/reserve elements of array
   if(!Reserve(num)) return(false);
//--- inserting
   MemMove(num+pos,pos,m_data_total-pos);
   for(int i=0;i<num;i++) m_data[i+pos]=src[i];
   m_sort_mode=-1;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Inserting elements in the specified position.                    |
//+------------------------------------------------------------------+
bool CArrayDouble::InsertArray(const CArrayDouble *src,const int pos)
  {
   int num;
//--- checking
   if(!CheckPointer(src)) return(false);
//--- checking/reserving elements of array
   num=src.Total();
   if(!Reserve(num)) return(false);
//--- inserting
   MemMove(num+pos,pos,m_data_total-pos);
   for(int i=0;i<num;i++) m_data[i+pos]=src.m_data[i];
   m_sort_mode=-1;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Assignment (copying) of another array.                           |
//+------------------------------------------------------------------+
bool CArrayDouble::AssignArray(const double &src[])
  {
   int num=ArraySize(src);
//--- checking/reserving elements of array
   Clear();
   if(m_data_max<num)
     {
      if(!Reserve(num)) return(false);
     }
   else   Resize(num);
//--- copying array
   for(int i=0;i<num;i++)
     {
      m_data[i]=src[i];
      m_data_total++;
     }
   m_sort_mode=-1;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Assignment (copying) of another array.                           |
//+------------------------------------------------------------------+
bool CArrayDouble::AssignArray(const CArrayDouble *src)
  {
   int num;
//--- checking
   if(!CheckPointer(src)) return(false);
//--- checking/reserving elements of array
   num=src.m_data_total;
   Clear();
   if(m_data_max<num)
     {
      if(!Reserve(num)) return(false);
     }
   else   Resize(num);
//--- copying array
   for(int i=0;i<num;i++)
     {
      m_data[i]=src.m_data[i];
      m_data_total++;
     }
   m_sort_mode=src.SortMode();
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Access to data in the specified position.                        |
//+------------------------------------------------------------------+
double CArrayDouble::At(const int index) const
  {
//--- checking
   if(index<0 || index>=m_data_total) return(DBL_MAX);
//--- result
   return(m_data[index]);
  }
//+------------------------------------------------------------------+
//| Updating element in the specified position.                      |
//+------------------------------------------------------------------+
bool CArrayDouble::Update(const int index,const double element)
  {
//--- checking
   if(index<0 || index>=m_data_total) return(false);
//--- updating
   m_data[index]=element;
   m_sort_mode=-1;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Moving element from the specified position                       |
//| on the specified shift.                                          |
//+------------------------------------------------------------------+
bool CArrayDouble::Shift(const int index,const int shift)
  {
   double tmp_double;
//--- checking
   if(index<0 || index+shift<0 || index+shift>=m_data_total) return(false);
   if(shift==0) return(true);
//--- moving
   tmp_double=m_data[index];
   if(shift>0) MemMove(index,index+1,shift);
   else        MemMove(index+shift+1,index+shift,-shift);
   m_data[index+shift]=tmp_double;
   m_sort_mode=-1;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Deleting element from the specified position.                    |
//+------------------------------------------------------------------+
bool CArrayDouble::Delete(const int index)
  {
//--- checking
   if(index<0 || index>=m_data_total) return(false);
//--- deleting
   if(index<m_data_total-1) MemMove(index,index+1,m_data_total-index-1);
   m_data_total--;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Deleting range of elements.                                      |
//+------------------------------------------------------------------+
bool CArrayDouble::DeleteRange(int from,int to)
  {
//--- checking
   if(from<0 || to<0)                return(false);
   if(from>to || from>=m_data_total) return(false);
//--- deleting
   if(to>=m_data_total-1) to=m_data_total-1;
   MemMove(from,to+1,m_data_total-to);
   m_data_total-=to-from+1;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Equality comparison of two arrays.                               |
//+------------------------------------------------------------------+
bool CArrayDouble::CompareArray(const double &Array[]) const
  {
//--- comparison
   if(m_data_total!=ArraySize(Array)) return(false);
   for(int i=0;i<m_data_total;i++)
      if(m_data[i]!=Array[i]) return(false);
//--- equal
   return(true);
  }
//+------------------------------------------------------------------+
//| Equality comparison of two arrays.                               |
//+------------------------------------------------------------------+
bool CArrayDouble::CompareArray(const CArrayDouble *Array) const
  {
//--- checking
   if(!CheckPointer(Array)) return(false);
//--- comparison
   if(m_data_total!=Array.m_data_total) return(false);
   for(int i=0;i<m_data_total;i++)
      if(m_data[i]!=Array.m_data[i]) return(false);
//--- equal
   return(true);
  }
//+------------------------------------------------------------------+
//| Method QuickSort.                                                |
//+------------------------------------------------------------------+
void CArrayDouble::QuickSort(int beg,int end,const int mode)
  {
   int    i,j;
   double p_double,t_double;
//--- checking
   if(beg<0 || end<0) return;
//--- sort
   i=beg;
   j=end;
   while(i<end)
     {
      //--- ">>1" is quick division by 2
      p_double=m_data[(beg+end)>>1];
      while(i<j)
        {
         while(m_data[i]<p_double)
           {
            //--- control the output of the array bounds
            if(i==m_data_total-1) break;
            i++;
           }
         while(m_data[j]>p_double)
           {
            //--- control the output of the array bounds
            if(j==0) break;
            j--;
           }
         if(i<=j)
           {
            t_double=m_data[i];
            m_data[i++]=m_data[j];
            m_data[j]=t_double;
            //--- control the output of the array bounds
            if(j==0) break;
            else     j--;
           }
        }
      if(beg<j) QuickSort(beg,j);
      beg=i;
      j=end;
     }
  }
//+------------------------------------------------------------------+
//| Inserting element in a sorted array.                             |
//+------------------------------------------------------------------+
bool CArrayDouble::InsertSort(const double element)
  {
   int pos;
//--- checking
   if(!IsSorted()) return(false);
//--- checking/reserving elements of array
   if(!Reserve(1)) return(false);
//--- if the array is empty, add an element
   if(m_data_total==0)
     {
      m_data[m_data_total++]=element;
      return(true);
     }
//--- search position and insert
   pos=QuickSearch(element);
   if(m_data[pos]>element) Insert(element,pos);
   else                    Insert(element,pos+1);
//--- restore the sorting flag after Insert(...)
   m_sort_mode=0;
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Search of position of element in a array.                        |
//+------------------------------------------------------------------+
int CArrayDouble::SearchLinear(const double element) const
  {
//--- checking
   if(m_data_total==0) return(-1);
//---
   for(int i=0;i<m_data_total;i++)
      if(MathAbs(m_data[i]-element)<=m_delta) return(i);
//--- not found
   return(-1);
  }
//+------------------------------------------------------------------+
//| Quick search of position of element in a sorted array.           |
//+------------------------------------------------------------------+
int CArrayDouble::QuickSearch(const double element) const
  {
   int    i,j,m=-1;
   double t_double;
//--- search
   i=0;
   j=m_data_total-1;
   while(j>=i)
     {
      //--- ">>1" is quick division by 2
      m=(j+i)>>1;
      if(m<0 || m>=m_data_total) break;
      t_double=m_data[m];
      //--- compared with a tolerance
      if(MathAbs(t_double-element)<=m_delta) break;
      if(t_double>element) j=m-1;
      else                 i=m+1;
     }
//--- position
   return(m);
  }
//+------------------------------------------------------------------+
//| Search of position of element in a sorted array.                 |
//+------------------------------------------------------------------+
int CArrayDouble::Search(const double element) const
  {
   int pos;
//--- checking
   if(m_data_total==0 || !IsSorted()) return(-1);
//--- search
   pos=QuickSearch(element);
//--- comparing with the tolerance
   if(MathAbs(m_data[pos]-element)<=m_delta) return(pos);
//--- not found
   return(-1);
  }
//+------------------------------------------------------------------+
//| Search position of the first element which is greater than       |
//| specified in a sorted array.                                     |
//+------------------------------------------------------------------+
int CArrayDouble::SearchGreat(const double element) const
  {
   int pos;
//--- checking
   if(m_data_total==0 || !IsSorted()) return(-1);
//--- searching
   pos=QuickSearch(element);
//--- comparing with the tolerance
   while(m_data[pos]<=element+m_delta)
      if(++pos==m_data_total) return(-1);
//--- position
   return(pos);
  }
//+------------------------------------------------------------------+
//| Search position of the first element which is less than          |
//| specified in the sorted array.                                   |
//+------------------------------------------------------------------+
int CArrayDouble::SearchLess(const double element) const
  {
   int pos;
//--- checking
   if(m_data_total==0 || !IsSorted()) return(-1);
//--- searching
   pos=QuickSearch(element);
//--- comparing with the tolerance
   while(m_data[pos]>=element-m_delta)
      if(pos--==0) return(-1);
//--- position
   return(pos);
  }
//+------------------------------------------------------------------+
//| Search position of the first element which is greater than or    |
//| equal to the specified in a sorted array.                        |
//+------------------------------------------------------------------+
int CArrayDouble::SearchGreatOrEqual(const double element) const
  {
   int pos;
//--- checking
   if(m_data_total==0 || !IsSorted()) return(-1);
//--- searching
   if((pos=SearchGreat(element))!=-1)
     {
      //--- comparing with the tolerance
      if(pos!=0 && MathAbs(m_data[pos-1]-element)<=m_delta) return(pos-1);
      else                                                  return(pos);
     }
//--- not found
   return(-1);
  }
//+------------------------------------------------------------------+
//| Search position of the first element which is less than or equal |
//| to the specified in a sorted array.                              |
//+------------------------------------------------------------------+
int CArrayDouble::SearchLessOrEqual(const double element) const
  {
   int pos;
//--- checking
   if(m_data_total==0 || !IsSorted()) return(-1);
//--- searching
   if((pos=SearchLess(element))!=-1)
     {
      //--- comparing with the tolerance
      if(pos!=m_data_total-1 && MathAbs(m_data[pos+1]-element)<=m_delta) return(pos+1);
      else                                                               return(pos);
     }
//--- not found
   return(-1);
  }
//+------------------------------------------------------------------+
//| Find position of first appearance of element in a sorted array.  |
//+------------------------------------------------------------------+
int CArrayDouble::SearchFirst(const double element) const
  {
   int pos;
//--- checking
   if(m_data_total==0 || !IsSorted()) return(-1);
//--- searching
   pos=QuickSearch(element);
   if(m_data[pos]==element)
     {
      //--- comparing with the tolerance
      while(MathAbs(m_data[pos]-element)<=m_delta)
         if(pos--==0) break;
      return(pos+1);
     }
//--- not found
   return(-1);
  }
//+------------------------------------------------------------------+
//| Find position of last appearance of element in a sorted array.   |
//+------------------------------------------------------------------+
int CArrayDouble::SearchLast(const double element) const
  {
   int pos;
//--- checking
   if(m_data_total==0 || !IsSorted()) return(-1);
//--- searching
   pos=QuickSearch(element);
   if(m_data[pos]==element)
     {
      //--- comparing with the tolerance
      while(MathAbs(m_data[pos]-element)<=m_delta)
         if(++pos==m_data_total) break;
      return(pos-1);
     }
//--- not found
   return(-1);
  }
//+------------------------------------------------------------------+
//| Writing array to file.                                           |
//+------------------------------------------------------------------+
bool CArrayDouble::Save(const int file_handle)
  {
   int i=0;
//--- checking
   if(!CArray::Save(file_handle)) return(false);
//--- writing array length
   if(FileWriteInteger(file_handle,m_data_total,INT_VALUE)!=INT_VALUE) return(false);
//--- writing array
   for(i=0;i<m_data_total;i++)
      if(FileWriteDouble(file_handle,m_data[i])!=sizeof(double)) break;
//--- result
   return(i==m_data_total);
  }
//+------------------------------------------------------------------+
//| Reading array from file.                                         |
//+------------------------------------------------------------------+
bool CArrayDouble::Load(const int file_handle)
  {
   int i=0,num;
//--- checking
   if(!CArray::Load(file_handle)) return(false);
//--- reading array length
   num=FileReadInteger(file_handle,INT_VALUE);
//--- reading array
   Clear();
   if(num!=0)
     {
      if(!Reserve(num))           return(false);
      for(i=0;i<num;i++)
        {
         m_data[i]=FileReadDouble(file_handle);
         m_data_total++;
         if(FileIsEnding(file_handle)) break;
        }
     }
   m_sort_mode=-1;
//--- result
   return(m_data_total==num);
  }
//+------------------------------------------------------------------+