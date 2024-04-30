unit CheatTable;

interface
{  Модуль обеспечения обработки значений на стороне клиента.
}
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Grids, Menus, ComCtrls, Math, ChTypes,
  ChCmd, ChClient;

const
     sgCaptionsEng : array [0..6] of string =
     ('Lock', 'Описание', 'Адрес', 'Значение', 'Cheat', 'Размер', 'Группа');

     X_LOCK = 0;
    X_DESCR = 1;
     X_ADDR = 2;
    X_VALUE = 3;
    X_CHEAT = 4;
     X_TYPE = 5;
    X_GROUP = 6;
   X_FILTER = 7;
type

  { Список значений для клиентского процесса }
  TValueList = class
  private
    function NeedUpdate(sgt: TStringGrid): Boolean;
  protected
   FValues: Array of TTextValue;
    FSize: Integer;
   FCount: Integer;
   function             GetItem (index: Integer): TTextValue;
   procedure            SetSize (newSize: Integer);
  public
   iMutex: Integer;
   MutexState: Integer; // 1 - acquired, 0 - unknow, -1 - free
   SelectedGroup: String;  
   property             Count: Integer read FCount;
   property             Items [Index: Integer]: TTextValue read GetItem; default;
   constructor          Create;
   destructor           Destroy; override;
   function             Add (Row: TStrings): Integer;
   function             AddImport (const sDescr, sAddr, sType, sCheat, sGroup: String): Integer;
   procedure            Clear;
   procedure            Delete (Index: Integer);
   procedure            FilteredClear;
   function             ItemExport (Index: Integer; var fr: TWgcFileRec): Boolean;
   function             FindByAddr (const sAddr: String): Integer;
   procedure            LoadFromTable(sgTable: TStringGrid; bClear: Boolean = FALSE);
   procedure            ScanForGroups (result: TStrings);
   procedure            SetPatchValue(Index: Integer; const S: String);
   procedure            SendList; // отправить серверному процессу
   procedure            UpdateItems (ilist: PUpdValueList; cnt: Integer);
   function             RowUsed (row: TStrings) : Boolean;
  end;

  TfrmAddrs = class(TForm)
    sgCheat: TStringGrid;
    pnBtns: TPanel;
    lTableFntSz: TLabel;
    btnCheat: TButton;
    btnLock: TButton;
    btnSave: TButton;
    btnLoad: TButton;
    btnClear: TButton;
    btnToDbg: TButton;
    btnmem: TButton;
    btnVAdd: TButton;
    btnVSub: TButton;
    cbFilter: TCheckBox;
    btnTrainer: TButton;
    pmDescriptions: TPopupMenu;
    mi_descMoney: TMenuItem;
    mi_descLife: TMenuItem;
    mi_descHealth: TMenuItem;
    mi_descSome: TMenuItem;
    mi_descPower: TMenuItem;
    mi_descTime: TMenuItem;
    mi_descBPS: TMenuItem;
    mi_descPistons: TMenuItem;
    mi_descGranati: TMenuItem;
    mi_descArrows: TMenuItem;
    mi_descDynamite: TMenuItem;
    mi_descRes: TMenuItem;
    mi_descTree: TMenuItem;
    mi_descGold: TMenuItem;
    mi_descMinerals: TMenuItem;
    mi_descGas: TMenuItem;
    mi_descSpace: TMenuItem;
    mi_descOil: TMenuItem;
    pmChTable: TPopupMenu;
    miKillRow: TMenuItem;
    miKillAll: TMenuItem;
    cbGroup: TComboBox;
    lbActiveGroup: TLabel;
    btnAddGroup: TButton;
    btnDeleteGroup: TButton;
    pmValues: TPopupMenu;
    mi1h: TMenuItem;
    mi1t: TMenuItem;
    mi10t: TMenuItem;
    mi100t: TMenuItem;
    mi1m: TMenuItem;
    miCustom: TMenuItem;
    miDefaultGroup: TMenuItem;
    pmTypes: TPopupMenu;
    mi_TypeByte: TMenuItem;
    mi_TypeWord: TMenuItem;
    mi_TypeDword: TMenuItem;
    miHex: TMenuItem;
    mi_TypeAnsiStr: TMenuItem;
    mi_TypeWideStr: TMenuItem;
    mi_TypeReal48: TMenuItem;
    mi_TypeSingle: TMenuItem;
    mi_TypeDouble: TMenuItem;
    mi_TypeExtended: TMenuItem;
    mi_DelStrings: TMenuItem;
    mi_move2group: TMenuItem;
    procedure btnLockClick(Sender: TObject);
    procedure btnCheatClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnmemClick(Sender: TObject);
    procedure sgCheatMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure miKillRowClick(Sender: TObject);
    procedure OnTypeItem(Sender: TObject);
    procedure miValuePasteClick(Sender: TObject);
    procedure sgCheatMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure sgCheatMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure btnVAddClick(Sender: TObject);
    procedure btnVSubClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormEndDock(Sender, Target: TObject; X, Y: Integer);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddGroupClick(Sender: TObject);
    procedure miDefaultGroupClick(Sender: TObject);
    procedure cbGroupSelect(Sender: TObject);
    procedure btnDeleteGroupClick(Sender: TObject);
    procedure sgCheatSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: String);
  private
    { Private declarations }
    chSelecting: Boolean;
//    prvGroup: String;
    procedure FillSelected(const ADefault: TGridCoord; sgTab: TStringGrid;
      const value: string);
    procedure PopupValuesMenu(x, y: Integer);

  public
    { Public declarations }
    dstcell: TGridCoord;
      stype: string;
    ptSelStart: TPoint;
    bCellsChanged: Boolean;
    procedure SyncGrids; // Режим выделения
    // procedure WMSysCommand (var msg: TMessage); message WM_SYSCOMMAND;
  end;

var
  frmAddrs: TfrmAddrs;
     vlist: TValueList;
{ wtRecvMode: Boolean = FALSE;
  wtRecvReq: Integer = 0;
 wtSendMode: Boolean = FALSE;{}
  wtUpdated: Boolean = FALSE;
   gAddrTable: TStringGrid = nil;

procedure ListAddrs (sgtCheat: TStringGrid; const sGroup: String; bForce: Boolean); // отображение значений текущей группы.

implementation
uses ChConst, ChText, ChSimp, ChForm, Misk, ChSettings,
     ConfDlg, SocketAPI, netipc, DataProvider, LocalIPC, ShareData;
{$R *.dfm}

function FindString (strings: TStrings; const sExample: String): Integer;
var n: Integer;
begin
 result := -1;
 for n := 0 to strings.Count - 1 do
  if strings [n] = sExample then
    begin result := n; break; end;
end;

procedure ClearTable (sgt: TStringGrid;
                        exc: Integer = -1;
                        exr: Integer = -1; bForce: Boolean = FALSE);
var r, c: Integer;
begin
 sgt.RowCount := 5;
 with sgt do
 for r := 1 to 4 do
 for c := 0 to ColCount do
  if (not bForce) and (r = exr) and (c = exc) then else
             Cells [c, r] := ''; //
end;

procedure TfrmAddrs.btnLockClick(Sender: TObject);
var r : byte;
begin
 r := gAddrTable.row;
 if gAddrTable.cells [X_LOCK, r] <> '' then
      gAddrTable.cells [X_LOCK, r] := ''
 else gAddrTable.cells [X_LOCK, r] := 'LOCK';
end;

procedure TfrmAddrs.btnCheatClick(Sender: TObject);
begin
 // Преобразование строковых данных в бинарные
 vlist.LoadFromTable (mform.sgt);
 while wtUpdated do
 begin
  application.ProcessMessages;
  vlist.SendList;
  Sleep (20);
 end;
 SendMsg (CM_WTCHEAT);
end;

procedure TfrmAddrs.btnClearClick(Sender: TObject);
begin
 vlist.Clear;
 SendMsgEx (CM_CLEARLIST, IDWATCHLIST); // очистка списка значений сервера
 ClearTable (mform.sgt);
 bCellsChanged := FALSE; // лишней работы не выполнять
 mform.ReListAddrs; // по идее должно быть чисто
end;

procedure TfrmAddrs.FormCreate(Sender: TObject);
var n: Integer;
begin
 vlist := TValueList.Create;
 for n := 0 to High (sgCaptionsEng) do
     sgcheat.cells [n, 0] := sgCaptionsEng [n];
end;

procedure TfrmAddrs.btnmemClick(Sender: TObject);
var n : dword;
    s : string;
begin
 // Отображение формы HEX редактора
 if (medit = nil) then medit := TMedit.Create (self);
 with medit do
 begin
  lbAddrs.Items.BeginUpdate;
  lbAddrs.Items.Clear;
  for n := 1 to sgCheat.RowCount - 1 do
   begin
    s := sgCheat.cells [2, n];
    if s <> '' then medit.lbAddrs.Items.Add(s);
   end;
  lbAddrs.Items.EndUpdate;
 end;
 medit.show;
end;

procedure TfrmAddrs.sgCheatMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
   gc: TGridCoord;
   pt: TPoint;
begin
 gc := sgCheat.MouseCoord (x, y);
 chSelecting := false;
 if (gc.Y > 0) and (gc.Y < sgCheat.RowCount) then
 with sgCheat do
  begin
   dstcell := gc;
   if (gc.X = 0) then
     if Cells [X_LOCK, gc.y] = 'LOCK' then Cells [0, gc.y] := ''
      else
        Cells [X_LOCK, gc.y] := 'LOCK';
   if (button <> mbRight) then exit;
   pt.x := x;
   pt.y := y;
   pt := sgCheat.ClientToScreen (pt);
   if (gc.X = X_DESCR) then pmDescriptions.Popup (pt.x, pt.y);
   // default menu for addr and value columns
   if (gc.X in [2..3]) then pmChTable.Popup (pt.x, pt.y);
   if (gc.X = X_CHEAT) then PopupValuesMenu (pt.x, pt.y);
   if (gc.X = X_TYPE) then
    begin
     miHex.Checked := pos ('H', UpperCase (sgcheat.cells [gc.x, gc.y])) > 0;
     pmTypes.Popup (pt.x, pt.y);
    end;
   if (gc.X = X_FILTER) then sgCheat.Cells [gc.x, gc.y] := ''; // фильтрация
   vlist.LoadFromTable(sgCheat, TRUE);
   wtUpdated := TRUE;
  end;
end;

procedure TfrmAddrs.miKillRowClick(Sender: TObject);
//var x: Integer;
begin
 vlist.Delete (dstcell.y - 1); // удаление полного значения
 wtUpdated := TRUE;
 bCellsChanged := FALSE;
 ListAddrs (mform.sgt, cbGroup.Text, TRUE);
end;

procedure TfrmAddrs.OnTypeItem(Sender: TObject);
var s : string;
    pct: ^TPageControl;
begin
 s := 'DWORD';
 if (Sender is TMenuItem) then
     s := (Sender as TMenuItem).Caption;
 if Pos ('&', s) > 0 then Delete (s, Pos ('&', s), 1);
 // Обработка в таблице
 stype := s;
 if (visible) then
   pct := @mform.pctrl
 else
   pct := @sform.pcMain;
 if (pct.TabIndex = 2) and ConvType2 (s) then
   begin
    if (s = 'HEX') then
     begin
      s := gAddrTable.Cells [dstcell.x, dstcell.y];
      if (pos ('H', UpperCase (s)) = 0) then  s := s + 'h'
                    else DelChar (s, 'h');
      miHex.Checked := (pos ('H', UpperCase (s)) > 0);
     end; // test for hex
    gAddrTable.Cells [dstcell.x, dstcell.y] := s;
   end;
end;

procedure TFrmAddrs.FillSelected (const ADefault: TGridCoord;
                               sgTab: TStringGrid; const value: string);
// Установка выделенных значений таблицы
var x, y: dword;
begin
 with sgtab.Selection do
 begin
   if InRect (ADefault.X, ADefault.Y, TRect (sgTab.Selection)) then
     for y := Top to Bottom do
     for x := Left to Right do
       sgtab.cells [x, y] := value
   else
     sgtab.cells [ADefault.x, ADefault.Y] := value;
 end;      
end; // FillSelected


procedure TfrmAddrs.miValuePasteClick(Sender: TObject);
var s: string;
begin
 // Установщик стандартных значений
 if (sender is TMenuItem) then
  begin
   if TMenuItem (sender) = miCustom then
     s := InputBox ('InputBox', 'Input custom value:', '1m')
   else
     s := (sender as TMenuItem).Caption;
   FillSelected (dstcell, sgcheat, s);
   sform.sgtable.Selection := sgcheat.Selection; // copy selection
   FillSelected (dstcell, sform.sgtable, s);
   //sgcheat.Cells [dstcell.X, dstcell.Y] := s;
   //sform.sgtable.cells [dstcell.x, dstcell.y] := s;
  end;
end; // 

procedure TFrmAddrs.SyncGrids;
var x, y: Integer;
    srctab, dsttab: TStringGrid;
begin
 // по умолчанию копировать в таблицу sform
 srctab := sgcheat;
 dsttab := sform.sgtable; 
 if (pWgcSettings.bSimpleView) then
  begin
   srctab := sform.sgtable;
   dsttab := sgcheat;
  end;
 for y := 1 to sgcheat.RowCount - 1 do
 for x := 0 to sgcheat.ColCount - 1 do
 if (srctab.cells [x, y] <> dsttab.cells [x, y]) then
     dsttab.cells [x, y] := srctab.cells [x, y]
end; // SyncGrids

procedure TfrmAddrs.PopupValuesMenu (x, y: Integer);
var item: TMenuItem;
    n: Integer;
begin
 // Добавление всех групп.
 with mi_move2group do
  begin
   Clear;
   // Add(miDefaultGroup);
   for n := 1 to cbGroup.Items.Count - 1 do
    begin
     item := TMenuItem.Create (self);
     item.OnClick := miDefaultGroupClick;
     item.Caption := cbGroup.Items [n];
     Add (item);
    end;
  end;
 // pmValues.Get
 pmValues.Popup (x, y);
end;
procedure TfrmAddrs.sgCheatMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 chSelecting := true; // начато выделение в табличке
 ptSelStart := Point (x, y);
end;

procedure TfrmAddrs.sgCheatMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var xcol, xrow: Integer;
    r: TGridRect;
begin
 if chSelecting then
 with sgcheat do
  begin
   r := Selection;
   MouseToCell (x, y, xcol, xrow);
   if (xrow >= RowCount) then exit;
   xrow := max (1, xrow);
   // xrow := min (RowCount - 1, xrow);
   if xcol <> 4 then exit; // not select other Column
   if (xcol >= ColCount) then exit;
   xcol := min (ColCount - 1, xcol);
   r.Left := 4;
   r.Right := 4;
   //if r.left > xcol then r.Left := xcol;
   //if r.Right < xcol then r.Right := xcol;
   if r.Top > xrow then r.Top := xrow;
   if r.Bottom < xrow then r.Bottom := xrow;
   Selection := r;
  end;
end;

procedure TfrmAddrs.btnVAddClick(Sender: TObject);
begin
 with sgCheat do
  begin
   if DefaultRowHeight < 30 then
      DefaultRowHeight := DefaultRowHeight + 1;
   Font.Height := DefaultRowHeight - 3;
  end;
end;

procedure TfrmAddrs.btnVSubClick(Sender: TObject);
begin
 with sgCheat do
  begin
   if DefaultRowHeight > 14 then
      DefaultRowHeight := DefaultRowHeight - 1;
   Font.Height := DefaultRowHeight - 3;
  end;
end;


procedure TfrmAddrs.btnSaveClick(Sender: TObject);
const recsz = sizeof (TWgcFileRec);
var   fd: file;
    fname: string;
      i, n: byte;
      fr: TWgcFileRec;
      fl: array [1..20] of TWgcFileRec;
      fs, ar, wr: dword;
      flag: boolean;
begin
 flag := false;
 vlist.LoadFromTable(mform.sgt);
 with mform do
 repeat
  if SaveDlg.Execute then
  begin
   fname := SaveDlg.FileName;
   if (pos ('.chx', fname) = 0) then fname := fname + '.chx';
   if FileExists (fname) then
   with ConfirmDlg do
    begin
     if not Assigned (ConfirmDlg) then
        ConfirmDlg := TConfirmDlg.Create (self);
     ConfirmDlg.ShowModal;
     if Result = 0 then exit;
     if Result = r_other then continue; // Recycle
     AssignFile (fd, fname);
     case Result of
      r_append :
        begin
        {$I-}
         Reset (fd, 1);
         if IOresult <> 0 then ReWrite (fd, 1);
        {$I+}
         ar := 0;
         n := 0;
         fs := FileSize (fd);
         repeat
          BlockRead (fd, fl [n + 1], recsz, wr); // Считать что есть
          if (wr = recsz) then inc (n);
          ar := ar + wr;
         until (ar >= fs) or (Eof (fd)) or (n > 18);
         CloseFile (fd);
         ReWrite (fd, 1); // Открыть для записи
         for i := 1 to n do
             BlockWrite (fd, fl [i], recsz, wr);
         wr := FilePos (fd);
        end;
      r_overwr : ReWrite (fd, 1);
     end;
    end // FileExist
    else
     begin
      AssignFile (fd, fname);
      ReWrite (fd, 1);
      end;
     // Цикл сохранения в файл
     for n := 0 to vlist.count - 1 do
     begin
      FillChar (fr, sizeof (fr), 0);
      if vlist.ItemExport(n, fr) then
       begin
        BlockWrite (fd, fr, recsz, wr);
        if (wr = 0) then break;
        wr := filepos (fd);
        if (wr = 0) then break;
       end;  
    end;
   CloseFile (fd);
  end;
  flag := true;
 until flag;
end;

procedure TfrmAddrs.btnLoadClick(Sender: TObject); 

var fd: file;
    fr: TWgcFileRec;
    fo: TWgcFileRecOld;
    rd: DWORD;
    ex: Boolean;
begin
 mform.OpenDlg.Filter := sWGCtablesFilter;
 with mform do
 if OpenDlg.execute then
 if FileExists (OpenDlg.FileName) then
 with OpenDlg do
  begin
   AssignFile (fd, FileName);
   Reset (fd, 1);
   seek (fd, 0);
   ex := pos ('.chx', lowerCase (FileName)) > 0;
   if ex then
   while not eof (fd) do
    begin
     FillChar (fr, sizeof (fr), 0);
     BlockRead (fd, fr, sizeof (fr), rd);
     if (fr.offst <> '') then
     begin
      vlist.AddImport (fr.descr, fr.offst, fr.stype, fr.chval, fr.group);
     end;
    end
   else
   while not eof (fd) do
   with fo do
    begin
     FillChar (fo, sizeof (fo), 0);
     BlockRead (fd, fo, sizeof (fo), rd);
     if (offst <> 0) then
     begin
      vlist.AddImport (descr,
                Format ('$%x', [offst]), stype, chval, 'Default');
     end;
    end;
   CloseFile (fd);
  end;
  wtUpdated := TRUE;
  bCellsChanged := FALSE;
  mform.ReListAddrs;
  vlist.ScanForGroups(cbGroup.Items);
end;


procedure TfrmAddrs.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action := caNone;
end;

procedure TfrmAddrs.FormEndDock(Sender, Target: TObject; X, Y: Integer);
var h: Integer;
begin
 if (Target is TWinControl) then
  begin
   h := TWinControl (Target).Height;
   if (height + 10 > h) then Height := h - 10;
  end;
end;

{ TValueList }
function TValueList.Add;
begin
 result := -1;
 if Row.Count >= 8 then else exit;
 result := FCount;
 if FindByAddr (row [X_ADDR]) > 0 then exit; // already exist
 Inc (FCount);
 if FCount > FSize then SetSize (count + 64);
 with FValues [result] do
 begin
  StrCopyAL (sLock, row [X_LOCK], 8);
  StrCopy32 (sDescription, row [X_DESCR]);
  StrCopy32 (sAddress, row [X_ADDR]);
  StrCopy32 (sValue, row [X_VALUE]); // save old value
  StrCopy32 (sPatchValue, row [X_CHEAT]);
  StrCopyAL (sValueType,  row [X_TYPE], 16);
  StrCopy32 (sValueGroup, row [X_GROUP]);
  // preventing fails
  if StrLen (sValueGroup) = 0 then StrPCopy (sValueGroup, 'Default'); 
  StrCopyAL (sFilter, row [X_FILTER], 2);
 end;
end;

function TValueList.AddImport;
const s_len = sizeof (TAnsiStr32);
begin
 result := FCount;
 Inc (FCount);
 if FCount > FSize then SetSize (count + 64);
 with FValues [result] do
  begin
   StrCopyAL (sDescription, sDescr, s_len);
   StrCopyAL (sAddress,     sAddr, s_len);
   StrCopyAL (sValueType,   sType, s_len);
   StrCopyAL (sPatchValue,  sCheat, s_len);
   if sGroup = '' then
     StrPCopy (sValueGroup, 'Default') else
     StrCopyAL (sValueGroup, sGroup, s_len);
  end;
end; // Add item

procedure TValueList.Clear;
begin
 FCount := 0;
end;

constructor TValueList.Create;
begin
 iMutex := -1;
 mutexState := -1;
 SetSize (256);
end;

procedure TValueList.Delete(Index: Integer);
var n: Integer;
begin
 // После удаления элементов нужно обновить Watch-Table сервера!
 if (Index < 0) or (Index >= Count) then exit;
 for n := Index to Count - 2 do
     FValues [n] := FValues [n + 1];
 Dec (FCount);
 wtUpdated := TRUE;
end;

destructor TValueList.Destroy;
begin
 SetSize (0);
end;

function TValueList.FindByAddr(const sAddr: String): Integer;
var n: Integer;
begin
 result := -1;
 for n := 0 to count - 1 do
 if Items [n].sAddress = sAddr then
  begin
   result := n;
   break;
  end;
end;

function TValueList.GetItem(index: Integer): TTextValue;
begin
 ASSERT (index < count);
 result := FValues [index];
 if (result.sAddress = '') then
     result.sValue [0] := #0;  
end;

procedure TValueList.SetSize(newSize: Integer);
begin
 FSize := newSize;
 if FCount > FSize then FCount := FSize;
 SetLength (FValues, newSize);
end;

procedure TfrmAddrs.FormDestroy(Sender: TObject);
begin
 if Assigned (vlist) then vlist.Free;
 vlist := nil;
end;

procedure ListAddrs;
var
   n, nadd: Integer;
   addall: Boolean;
   value: TTextValue;
   nrow, ncol: Integer;
   slRow: TStrings;

procedure SetCell (col :Integer; const s: string);
begin
 if not Assigned (slRow) then Exit;
 // блокировка перезаписи значения под курсором
 if (not bForce) and (nadd = nrow) and
    (col = ncol) and (col <> X_VALUE) then exit;
 if s = slRow [col] then exit;
 slRow [col] := s;
end; // set cell


begin
 with sgtCheat do
 begin
  vlist.SelectedGroup := sGroup;
  ncol := sgtCheat.Col;
  nrow := sgtCheat.Row;
  ClearTable (sgtCheat, ncol, nrow, bForce);
  sgtCheat.RowCount := vlist.Count + 2; // установка кол-ва столбцов
  // предв. очистка таблицы
  nadd := 1; // first used row
  addall := UpperCase (sGroup) = 'ALL';
  ods (format ('#DEBUG: listing table, all values count = %d', [vlist.Count]));
  for n := 0 to vlist.Count - 1 do
  begin
   value := vlist [n];
   if AddAll or (value.sValueGroup = sGroup) then else continue;
   slRow := sgtCheat.Rows [nadd];
   slRow.BeginUpdate;
   SetCell (X_LOCK,  value.sLock);
   SetCell (X_DESCR, value.sDescription);
   SetCell (X_ADDR,  value.sAddress);
   SetCell (X_VALUE, value.sValue);
   SetCell (X_CHEAT, value.sPatchValue);
   SetCell (X_TYPE,  value.sValueType);
   SetCell (X_GROUP, value.sValueGroup);
   slRow.EndUpdate;
   Inc (nadd);
   if nadd >= RowCount then RowCount := nadd + 4;
  end;
 end;

end;

procedure TValueList.LoadFromTable;
var
   prv, n: Integer;
   s: String;
begin
 // Обновление значений в списке из таблицы
 prv := vlist.Count;
 if not NeedUpdate (sgTable) then exit;
 if bClear then vlist.FilteredClear;
 with sgTable do
 for n := 1 to RowCount - 1 do
 begin
  if not RowUsed (sgTable.Rows [n]) then continue;
  s := cells [X_ADDR, n];
  if not bClear then  with vlist do Delete(FindByAddr (s));
  vlist.Add (Rows [n]);
 end;
 ods (format ('#DEBUG: Loading vlist from table precount = %d, count = %d',
                [prv, vlist.count]));
end; // LoadFromTable

function TValueList.NeedUpdate (sgt: TStringGrid): Boolean;
var
   n, cnt, i: Integer;
   row: TStrings;
begin
 result := TRUE;
 cnt := 0;
 for n := 1 to sgt.RowCount - 1 do
   if RowUsed (sgt.Rows [n]) then Inc (cnt);
 if cnt <> Count then exit;
 i := 0;
 for n := 1 to sgt.RowCount - 1 do
 begin
  row := sgt.Rows [n];
  if RowUsed (row) then
  begin
   with Items [i] do
   if (row [X_LOCK] <> sLock) or
      (row [X_DESCR] <> sDescription) or
      (row [X_ADDR] <> sAddress) or
      (row [X_VALUE] <> sValue) or
      (row [X_CHEAT] <> sPatchValue) or
      (row [X_TYPE] <> sValueType) or
      (row [X_GROUP] <> sValueGroup) or
      (row [X_FILTER] <> sFilter) then exit;
   Inc (i);
  end;
 end;
 result := False;
end;

procedure TfrmAddrs.btnAddGroupClick(Sender: TObject);
var sName: String;
begin
 sName := cbGroup.Text;
 // InputBox ('Добавление новой группы', 'Введите название группы', '');
 if (sName <> '') and (FindString (cbGroup.Items, sName) < 0) then
        cbGroup.Items.Add(sName);
end;

procedure TfrmAddrs.miDefaultGroupClick(Sender: TObject);
var n: Integer;
  sGroup: String;
begin
 if not (sender is TMenuItem) then exit;
 sGroup := TMenuItem (sender).Caption;
 with sgCheat.Selection do
 for n := Top to Bottom do
     sgCheat.cells [X_GROUP, n] := sGroup;
 vlist.LoadFromTable (sgCheat);
end;

function TValueList.ItemExport;
var item: ^TTextValue;
begin
 result := (Index >= 0) and (Index < Count);
 if not result then exit;
 item := @FValues [Index];
 StrPCopy (fr.descr, item.sDescription);  // описание
 StrPCopy (fr.offst, item.sAddress);  // смещение
 StrPCopy (fr.chval, item.sPatchValue);  // что лучше записать
 StrPCopy (fr.stype, item.sValueType);  // выражение типа
 StrPCopy (fr.group, item.sValueGroup);
end;


procedure TfrmAddrs.cbGroupSelect(Sender: TObject);
begin
 vlist.LoadFromTable (sgCheat); // сохранить что изменилось
 ListAddrs (sgCheat, cbGroup.Text, TRUE); // вывести из другой группы
end;

procedure TfrmAddrs.btnDeleteGroupClick(Sender: TObject);
begin
 with cbGroup do
 if (ItemIndex >= 0) and (Text <> 'Default') and (Text <> 'All') then
  Items.Delete (ItemIndex);
end;

procedure TValueList.ScanForGroups(result: TStrings);
var n: Integer;
    sGrp: String;
begin
 if Assigned (result) then
 for n := 0 to count - 1 do
  begin
   sGrp := Items [n].sValueGroup;
   if FindString (result, sGrp) = -1 then
     result.Add (sGrp);
  end;
end;

procedure TValueList.SendList;
var n: Integer;
    sl: TSmallWatchList;
    cnt: Integer;
// Отправка всех значений списка серверу
begin
 cnt := 0;
 // просьба
 // после обработки запроса на добавление, должно приидти соглашение
 if mutexState <> 1 then
  begin
   // мьютекс освобожден
   if mutexState = -1 then
     begin
      SendMsgEx (CM_ACQUIREMUTEX, iMutex, ClientId);
      Sleep (100);
      incoming.WaitEvent(_RECVEVENT, 100);
     end;
   Exit;
  end;
 SendMsgEx (CM_CLEARLIST, IDWATCHLIST); // очистить список перед добавлением
 FillChar (sl, sizeof (sl), 0);
 for n := 0 to Count - 1 do
 begin
  FValues [n].Index := n;
  sl [cnt].Index := n;
  StrCopyAL (sl [cnt].sLock,  FValues [n].sLock, 8);
  StrCopy32 (sl [cnt].sAddress,  FValues [n].sAddress);
  StrCopy32 (sl [cnt].sPatchValue,  FValues [n].sPatchValue);
  StrCopyAL (sl [cnt].sValueType,  FValues [n].sValueType, 16);
  Inc (cnt);
  // if array filled, or last iteration
  if (cnt >= 16) or (n = Count - 1) then
  begin
   SendMsg (CM_LDATA);
   SendDataEx (sWTADDVALS, @sl, sizeof (TSmallWatchList), cnt, cnt);
   cnt := 0;
  end;
 end;
 SendMsgEx (NM_LISTADDCOMPLETE, IDWATCHLIST, Count);
 SendMsgEx (CM_RELEASEMUTEX, iMutex, ClientId);
 mutexState := 0; // перевод мьютекса в неопределенное состояние
 wtUpdated := FALSE;
 // wtSendMode := FALSE;
end; // SendList   

procedure TValueList.SetPatchValue (Index: Integer; const S: String);
begin
 StrCopyAL (FValues [Index].sPatchValue, S, s32_len);
end;

procedure TValueList.UpdateItems(ilist: PUpdValueList; cnt: Integer);
var n, i: Integer;
begin
 if Assigned (ilist) then
 for n := 0 to cnt - 1 do
 begin
  // запись значения по адресам соответствия
  for i := 0 to count - 1 do
   if StrComp (FValues[i].sAddress, ilist [n].sAddr) = 0 then
      StrCopyAL (FValues [i].sValue, ilist [n].sValue, 32);
 end;
end; // AddItems

procedure TfrmAddrs.sgCheatSetEditText(Sender: TObject; ACol,
  ARow: Integer; const Value: String);
begin
 bCellsChanged := TRUE;
end;

function TValueList.RowUsed;
var i: Integer;
begin
 result := TRUE;
 for i := 0 to row.Count - 1 do
     if row [i] <> '' then Exit;
 result := FALSE;
end;

procedure TValueList.FilteredClear;
var n: Integer;
    bAll: Boolean;
begin
 bAll := scmpi (SelectedGroup, 'all');
 n := 0;
 while (n < count) do
    with Items [n] do
  if bAll or (scmpi (sValueGroup, SelectedGroup)) or
    (StrLen (sValueGroup) = 0) or (StrLen (sAddress) = 0)  then
        delete (n) else inc (n);
end;

end.
