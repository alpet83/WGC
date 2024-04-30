unit prcsmap;
{
Модуль содержит:
  - перечисления запущенных процессов в массив Items.
  - отображения массива Items в списки типа TListBox;
}
interface
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Menus, ExtCtrls, StdCtrls, ImgList, Grids, TlHelpEx,
  ChShare, ChTypes, ChSettings, ChLog, ChClient, SimpleArray, PSLists;


type
    PIcon = ^HICON;
    PListBox = ^ TListBox;
    PListView = ^TListView;

  TSPSInfo = packed record
      dwPID: DWORD;
       hWnd: THandle;
     gIndex: Integer; // index in source array
   icoIndex: Integer;
  end;


  TSPSArray = class (TSimpleArray)
  protected
   procedure            SetSize (nSize: Integer); override;
  public
   Items: array of TSPSInfo;
   procedure            AddPS (pid: DWORD; _hWnd: THandle; gIndx: Integer);
   function             FindPS (pid: DWORD; _hWnd: THandle): Integer;
   function             GetDataPtr: Pointer; override;
   function             ItemSize: Integer; override;

  end;

    // Список основных окон-приложений, загружается через соединение
  TWProcessArray = class (TSimpleArray)
  private
    bcvt: TBitmap;
    selPID: DWORD;
    mstr: TStream;
    function GetItem(Index: Integer): TProcessInfo;
    procedure SetItem(Index: Integer; const psinfo: TProcessInfo);
    // procedure StoreNew(pl: TSPSArray; items: TListItems; selpid: DWORD );
    function _updPrcsList (LView: TListView): Boolean;
    procedure CopyPSInfo(li: TListItem; nIndex: Integer);
  protected
     pidhash: DWORD;
     lIndex: Integer;
     prvList: TSPSArray;
     cache: TListItems;
     FItems: array of TProcessInfo;
     function           CalcHash: DWORD;
     procedure          SetSize (nSize: Integer); override;
     procedure          SwapItems (const i1, i2 : dword);
     function           ReadItem: PProcessInfo;
     // сравнение списка с prvList, с получением списка новых элементов
     function           FindAdded: TSPSArray;
     function           MaxItem: Integer;
    public
      addmask: DWORD;
      maskPID: DWORD;
     bShowPID: Boolean;
     ClearIcoList: Boolean;
     OnUpdate: TNotifyEvent;
     property   witems [Index: Integer]: TProcessInfo read GetItem write SetItem; default;

     constructor                Create (ident: Integer);
     destructor                 Destroy; override;
     procedure                  Add (const psa: array of TProcessInfo; cnt: Integer);
     procedure                  AddIcon (const ico: TIconData;
                                imgl: TImageList;
                                lv: TListView);
     procedure                  Clear; override;
     function                   FindProcess (_pid: DWORD; _hWnd: HWND = 0): Integer;
     function                   FindWindow (s: string): Integer;
     procedure                  Free;
     function                   GetDataPtr: Pointer; override;
     function                   ItemSize: Integer; override;               
     procedure                  SetAddFlags (flagsmask: dword; bval: boolean);
     function                   Store (LView: TListView; const force: Bool = false): Bool;
     function                   Update (dwUnused: DWORD = 0): Boolean; override;
    end; // TWProcessArray

   TModuleArray256 = array [0..255] of TModuleInfo;
   PModuleArray256 = ^TModuleArray256;
   TRegionArray256 = array [0..255] of TRegion;
   PRegionArray256 = ^TRegionArray256;
   TThreadArray16 = array [0..15] of TThreadInfo;
   PThreadArray16 = ^TThreadArray16;

var
     mfrm, sfrm: HWND;
     psarray: TProcessArray;
     voidprcs: TProcess;
       wplist: TWProcessArray;
    fLargeIcons: boolean = false;
    void_icon: HICON;

       thArray: TThreadArray = nil;
        mArray: TModuleArray = nil;
        rArray: TRegionArray = nil;

procedure  AddModules (pdata: PModuleArray256; mCount: Integer);
procedure  AddRegions (pdata: PRegionArray256; rCount: Integer);
procedure  AddThreads (pdata: PThreadArray16; tCount: Integer);
procedure  ListModules (tview: TTreeView);
procedure  ListThreads (lbThreads: TListBox);
procedure  ListRegions (lvRegions: TListView);
//procedure  SortMB32List (lbMemBlocks: TListBox);


{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
implementation
uses ChCmd, ChMsg, misk, ChSimp, ChConst,
     ListViewXp, ChIcons, ChForm;
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


var
   prvThCount: Integer = -1;

procedure  AddModules (pdata: PModuleArray256; mCount: Integer);
begin
 if not Assigned (pdata) then exit;
 mArray.Add(pdata^, mCount);
end;

procedure  AddRegions;
var n: Integer;
begin
 if not Assigned (pdata) or not Assigned (rArray) then exit;
 for n := 0 to rCount - 1 do
     rArray.AddRegion (pdata [n]);
end; // AddRegions;

procedure  AddThreads (pdata: PThreadArray16; tCount: Integer);
begin
 thArray.Add(pdata^, tCount);
end;

procedure  ListModules;
var n: word;
    base: Pointer;
    tmp, child: TTreeNode;
begin
 if not Assigned (mArray) then exit;
 tview.Items.BeginUpdate;
 if mArray.ItemsCount = 0 then exit;
 tview.Items.Clear;
 {tmp := tview.items.Add(nil, 'Process Modules');
 tmp := tview.items.AddChild (tmp, '[!]');}
 tmp := nil;
 with tview do
  for n := 0 to mArray.ItemsCount - 1 do
   begin
    base := ptr (mArray [n].hModule);
    tmp := items.Add (tmp, mArray [n].szModule);
    tmp.ImageIndex := 0;
    tmp.Data := nil;
    child := items.AddChild (tmp, format ('Base: $%P', [base]));
    child.ImageIndex := 0;
    child := items.Add (child, format ('Size: %U', [mArray [n].modBaseSize]));
    child.ImageIndex := 0;
   end;
 tview.Items.EndUpdate;
 tview.Update;
end; // ListModules


procedure  ListThreads;
var n : byte;
begin
 if not Assigned (thArray) then exit;
 if (prvThCount <> thArray.ItemsCount) and
    (thArray.ItemsCount > 0) then
 with lbThreads do
 begin
  items.BeginUpdate;
  items.Clear;
  for n := 0 to thArray.ItemsCount - 1 do
     items.Add ('$' + dword2hex (thArray [n].threadId));
  items.EndUpdate;
  prvThCount := thArray.ItemsCount;
 end;
end; // listThreads


{procedure  SortMB32List;
var tmp : TMemBlockRec;
   i, n, m : byte;
     t : String;
begin
 i := 1;
  repeat
   m := i;
   for n := i to mbList.ItemsCount do
   if dword (mbList [n].base) < dword (mbList [i].base) then
       m := n;
   if m > i then
     begin
      if (m < lbMemBlocks.Items.count) then
      with lbMemBlocks do
       begin
        t := Items [m - 1];
        Items [m - 1] := Items [i - 1];
        Items [i - 1] := t;
       end;
      tmp := mbList [m];
      mbList [m] := mbList [i];
      mbList [i] := tmp;
     end;
   inc (i);
  until (i >= mbList.ItemsCount);
end; {}


var _rhash: dword;

procedure  ListRegions;
var n: Integer;
    i, ii: Integer;
    pc: Int64;
    hash: dword;
    item: TListItem;
    s: string;
    psiz: dword;
begin
 psiz := csm.vmsize;
 hash := 0;
 lvRegions.Items.Clear;
 if rArray.ItemsCount = 0 then exit;
 // рассчет "хэша"
 for n := 0 to rArray.ItemsCount - 1 do
  with rArray [n] do hash := hash + ofst + size;

 if (hash = _rhash) and
    (lvRegions.Items.Count = rArray.ItemsCount) then exit;
 _rhash := hash;
 // if (rArray.ItemsCount = 0) then exit;
 lvRegions.Items.BeginUpdate;
 for n := 0 to rArray.ItemsCount - 1 do
 with rArray [n] do
  begin
   item := lvRegions.Items.Add;
   item.ImageIndex := -1;
   item.Caption := '$' + dword2hex (ofst);  // offset of Region
   s := msdiv (size);         // size + percent view
   if (psiz > size) then
    begin
     pc := 100 * Int64 (size);
     pc := pc div psiz;
     if (pc > 0) then
        s := s + format (' [%d%%]', [pc]);
    end;
   item.SubItems.Add(s);      // size of Region
   ii := 1;
   for i := Low (protList) to High (protList) do
    if (protect and protList [i] <> 0) then ii := i;
   case ii of
    1: item.ImageIndex := 6;  // No Access
    2..5: item.ImageIndex := ii - 1;  // random
    6, 7: item.ImageIndex := 7;  // rwe / re = yellow
   end;
   s := protStrs [ii];
   // Verifying additional flags
   if (protect and PAGE_GUARD <> 0) then s := s + 'g';
   if (protect and PAGE_NOCACHE <> 0) then s := s + 'nc';
   item.SubItems.Add (s); // protection
   s := '?';
   //if state = MEM_COMMIT then s := 'commit';
   //if state = MEM_FREE then s := 'free';
   case rtype of
      MEM_IMAGE: s := 'image';
     MEM_MAPPED: s := 'mapped';
    MEM_PRIVATE: s := 'private';
   end;
   item.SubItems.Add (s);
   //
  end;
 lvRegions.Items.EndUpdate;
 rArray.Clear; // хранить не нужно 
end; // ListRegions


procedure  TWProcessArray.SwapItems (const i1, i2 : dword);
var tmp : TProcessInfo;

begin
 tmp := witems [i1];
 witems [i1] := witems [i2];
 witems [i2] := tmp;
end;

{ TPrcsListEx }

procedure       TWProcessArray.CopyPSInfo; 
var s: String;
    pinfo: PProcessInfo;

begin
 if not CheckIndex (nIndex, ItemsCount) then exit;
 pinfo := @FItems [nIndex];
 // Тестирование системных процессов(?)
 s := pinfo.title;
 // выборка элементов на замену или создание дополнительных
 if bShowPID then
    li.Caption := '[' + FormatHandle (pinfo.pid) + '] ' + s
 else li.Caption := s;
 li.Data := Pointer (pinfo.pid); // universal
 // выделение элемента бывшего выделенным до обновления
 if (selpid > 0) and (pinfo.pid = selpid) then
   begin
    li.Selected := TRUE;
    li.Focused := TRUE;
   end;
 // Получение индекса иконки процесса
 li.ImageIndex := pinfo.icon;
end; // CopyPSInfo

function TWProcessArray._updPrcsList;
 var
     n, ii: Integer;
     pl: TSPSArray;

Begin
   LView.Items.BeginUpdate;
   result := false;
   // Сохранение позиции выделеного элемента
   ii := LView.ItemIndex;
   selpid := 0;
   if (ii >= 0) and (LView.items [ii].Data <> nil) then
     begin
      ii := Integer (LView.items [ii].Data); // to index;
      ASSERT (ii < prvList.ItemsCount);
      selpid := prvList.Items [ii].dwPID;
     end;
   pl := FindAdded;
   // Уравнивание размеров списков
   while (ItemsCount > LView.Items.Count) do LView.Items.Add;
   while (ItemsCount < LView.Items.Count) do LView.Items.Delete (0);
   // RemoveBad (LView.Items);
   for ii := 0 to ItemsCount - 1 do
   with FItems [ii] do
   begin
    // поиск для получения индекса иконки в предыдущем состоянии
    n := prvList.FindPS(pid, hWnd);
    if n > 0 then FItems [ii].icon := prvList.Items [n].icoIndex;
    CopyPSInfo (LView.Items [ii], ii); // обновление информации в списке
   end;
   // Уравнивание массивов
   prvList.Clear;
   for ii := 0 to ItemsCount - 1 do
   with witems [ii] do
        prvList.AddPS ( pid, hwnd, ii ); // сохранить для использования в выделении

   ASSERT (ItemsCount = LView.Items.Count);
   LView.Items.EndUpdate;
   pl.Free;
End;


function        TWProcessArray.Store;
 { Инвариант обработки:
     сравнение массивов процессов (prvList и FItems), с маркировкой
    процессов которые надо добавить в ListView, и удалением отсутствующих.
   1. Составление карты отсутствующих в FItems - матричный цикл.


 }



var fc: boolean;
Begin // .Store
 fc := (ItemsCount = 0) or force;
 _updPrcsList (LView);
 result := fc;
end; // ListArray

{ TWProcessArray }

constructor TWProcessArray.Create;
begin
 addmask := 0;
 OnUpdate := nil; // normal - no handler
 bcvt := TBitmap.Create;
 mstr := TMemoryStream.Create;
 bShowPID := FALSE;
 prvList := TSPSArray.Create (0);
 inherited;
end;

destructor TWProcessArray.Destroy;
begin
 bcvt.Free;
 mstr.Free;
 prvList.Free;
 inherited;
end;

procedure TWProcessArray.Free;
begin
 if (self <> nil) then Destroy;
end; // Free    



var
   addInvisib: Boolean = false;
   addVoidCap: Boolean; // Флаг добавления в список окон с пустыми
                         // заголовками
   addWinless: boolean = false;

function  Filter (h, pid: DWORD; iscap: boolean): boolean;
begin
 result := true;
 // Только с заголовками ли все окна
 if addVoidCap or iscap then else exit;
 // if masked and (maskid <> pid) then exit;
 result := false;
end;



{ Глобальны перемменны }
var
     aa: string;

function TWProcessArray.Update;
var
    nn, i: Integer;
    bUpdate: Boolean;
    phash: DWORD;
begin
 aa := '';
 phash := CalcHash;
 bUpdate := phash  <> pidhash;
 result := bUpdate;
 pidhash := phash;
 // Сортировка по принадлежности к играм, все игровые должны быть первыми
 if ItemsCount > 2 then 
 for nn := ItemsCount - 2 downto 1 do
 for i := 0 to nn do
   if ( wItems [i].game < wItems [i + 1].game ) then SwapItems (i, i + 1);
 if ( bUpdate and Assigned (OnUpdate)) then OnUpdate (self);
end; // ListWndPrcs;

function TWProcessArray.FindWindow;
var n: Integer;

begin
 s := LowerCase  (s);
 result := 0;
 if 0 = FCount then exit;
 for n := 0 to MaxItem do
 if pos (LowerCase (witems [n].title), s) > 0 then
  begin
   result := n;
   break;
  end;
end; // FindWindow

function TWProcessArray.FindProcess;
var n: Integer;
begin
 result := -1;
 for n := 0 to MaxItem do
 with wItems [n] do
 if (_pid = pid) and ((_hWnd = 0) or (_hWnd = hWnd)) then
  begin
   result := n;
   break;
  end;
end; // FindProcess

procedure TWProcessArray.SetAddFlags(flagsmask: dword; bval: boolean);
begin
 if bval then
    addmask := addmask or flagsmask
 else addmask := addmask and (not flagsmask);
 Update;
end; // SetAddFlags

procedure TWProcessArray.Add;
var iadd, n: Integer;
begin
 iadd := AddItems (cnt);
 for n := 0 to cnt - 1 do
    WItems [iadd + n] := psa [n];
end;

function TWProcessArray.CalcHash: DWORD;

function StrSum (const s: string) : dword;
var n : dword;
begin
 result := 0;
 for n := 1 to Length (s) do
     result := result + Byte (n) xor byte (s [n])
end; // StrSum

var n: Integer;
begin
 result := 1;
 for n := 0 to ItemsCount - 1 do
  begin
   result := result xor witems [n].pid  + 1;
   result := result + StrSum (witems [n].title);
  end;
end;

function TWProcessArray.GetItem(Index: Integer): TProcessInfo;
begin
 FillChar (result, sizeof (result), 0);
 if ChkIndex (Index) then result := FItems [Index];
end; // GetItem

procedure TWProcessArray.SetSize(nSize: Integer);
begin
 inherited;
 SetLength (FItems, nSize);
end;

procedure TWProcessArray.SetItem(Index: Integer; const psinfo: TProcessInfo);
begin
 if ChkIndex (Index) then FItems [Index] := psinfo;
end;


function TWProcessArray.ReadItem: PProcessInfo;
begin
 ASSERT (lIndex >= 0);
 result := nil;
 if (lIndex < ItemsCount) then
  begin
   result := @FItems [lIndex];
   Inc (lIndex);
  end;
end;

function TWProcessArray.GetDataPtr: Pointer;
begin
 result := FItems;
end;

function TWProcessArray.ItemSize: Integer;
begin
 result := sizeof (FItems[0]);
end;

procedure TWProcessArray.AddIcon;
var n, i: Integer;
    li: TListItem;
    pid: DWORD;
    vico: TIcon;
begin
 mstr.Seek (0, soFromBeginning);
 mstr.Write(ico.IcoStream, ico.IcoDataSz);
 mstr.Seek (0, soFromBeginning);
 bcvt.LoadFromStream(mstr);
 if ClearIcoList then
  begin
   ClearIcoList := FALSE;
   imgl.Clear;
   vico := TIcon.Create;
   vico.Handle := void_icon;
   imgl.AddIcon (vico); // zero icon
   vico.Free;
  end;
 i := imgl.Add(bcvt, nil);
 for n := 0 to ItemsCount - 1 do
 begin
  if (n < prvList.ItemsCount) and
        (prvList.Items [n].hWnd = ico.hWndOwner) then
      prvList.Items [n].icoIndex := i;

  if WItems [n].hWnd = ico.hWndOwner then
  begin
   FItems [n].icon := i;
   pid := FItems [n].pid;
   li := lv.FindData(0, ptr (pid), TRUE, FALSE);
   if Assigned (li) then li.ImageIndex := i;
  end;
 end;
end; // AddIcon

procedure TWProcessArray.Clear;
begin
 inherited;
 ClearIcoList := TRUE; // default operation 
end; // Clear

function TWProcessArray.FindAdded: TSPSArray;
var n: Integer;
    pid: DWORD;
    hWnd: THandle;
begin
 result := TSPSArray.Create (0);
 // поиск процессов отсутствующих в prvList
 for n := 0 to FCount - 1 do
 begin
  pid := witems [n].pid;
  hWnd := witems [n].hWnd;
  // scan for hwnd-process items exist
  if prvList.FindPS (pid, hWnd) < 0 then // если не найден
     result.AddPS (pid, hWnd, n); // новый процесс в списке

 end;
end; // FoundAdded


function TWProcessArray.MaxItem: Integer;
begin
 result := FCount - 1;
end;

{ TSPSArray }


procedure TSPSArray.AddPS;
var iadd: Integer;
begin
 iadd := AddItems (1);
 Items [iadd].gIndex := gIndx;
 Items [iadd].dwPID := pid;
 Items [iadd].hWnd := _hWnd;
 Items [iadd].icoIndex := 0;
end;

function TSPSArray.FindPS(pid: DWORD; _hWnd: THandle): Integer;
var nn: Integer;
begin
 // Scaning for hWnd-Process item.
 result := -1;
 for nn := 0 to ItemsCount - 1 do
 with Items [nn] do
 if (dwPID = pid) and ((_hWnd = 0) or (hWnd = _hWnd)) then
  begin
   result := nn;
   break;
  end;
end; // FindPS

function TSPSArray.GetDataPtr: Pointer;
begin
 result := @Items;
end;

function TSPSArray.ItemSize: Integer;
begin
 result := sizeof (Items [0]);
end;

procedure TSPSArray.SetSize(nSize: Integer);
begin
 inherited;
 SetLength (Items, nSize); 
end;

initialization
 mfrm := 0;
 sfrm := 0;
 void_icon := LoadIcon (hInstance, MakeIntResource (12001));
 FillChar (voidprcs, sizeof (voidprcs), 0);
 psArray := TProcessArray.Create (IDPROCESSLIST);
 psArray.Update;
 wplist := TWProcessArray.Create (IDPROCESSLIST);
 thArray := TThreadArray.Create (IDTHREADLIST);
 rArray := TRegionArray.Create (IDREGIONLIST);
 mArray := TModuleArray.Create (IDMODULELIST);
 // wlist.Update;
finalization
 psArray.Free;
 wplist.Free;
 thArray.Free;
 mArray.Free;
 rArray.Free;
 LogStr('#NOTIFY: prcsmap - finalization complete');
 // mbList.Free;
end.
