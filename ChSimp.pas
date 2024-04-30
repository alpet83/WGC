unit ChSimp;
// Упрощенная версия интерфейса программы
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, Buttons, Menus, Grids, ChSettings, ChClient;

type
  Tsform = class(TForm)
    pcMain: TPageControl;
    tsh1: TTabSheet;
    tsh2: TTabSheet;
    tsh3: TTabSheet;
    lvApps: TListView;
    appmenu: TMainMenu;
    miFile: TMenuItem;
    miExit: TMenuItem;
    miView: TMenuItem;
    miClassic: TMenuItem;
    mhint1: TMemo;
    btnClassic: TButton;
    btnExit: TButton;
    edexmin: TEdit;
    cbTypes: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    cbRules: TComboBox;
    Label3: TLabel;
    btnScan: TButton;
    btnSieve: TButton;
    mhint2: TMemo;
    btnAdd: TButton;
    lFound: TLabel;
    cbAddrs: TComboBox;
    sgtable: TStringGrid;
    mhint3: TMemo;
    btnCheat: TButton;
    btnSaveTab: TButton;
    btnLoadTab: TButton;
    miHelp: TMenuItem;
    btnClear: TButton;
    pmSettings: TMenuItem;
    procedure btnExitClick(Sender: TObject);
    procedure btnClassicClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lvAppsClick(Sender: TObject);
    procedure lvAppsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure sgtableMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure sgtableSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: String);
    procedure btnCheatClick(Sender: TObject);
    procedure pcMainChanging(Sender: TObject; var AllowChange: Boolean);
    procedure cbTypesSelect(Sender: TObject);
    procedure cbRulesSelect(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pmSettingsClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure OnComplete;
  end;

var
  sform: Tsform;

implementation
uses ChForm, ChShare, ChCmd, misk, RqsTable, Prcsmap, ChOptions, CheatTable;

{$R *.dfm}

procedure SetMargins (const hwnd: THandle; ml, mr: dword);
begin
 SendMessage (hwnd, EM_SETMARGINS,
                EC_LEFTMARGIN or EC_RIGHTMARGIN,
                MAKELONG (ml, mr));

end; // SetMargins


procedure Tsform.btnExitClick(Sender: TObject);
begin
 PostMessage (mform.Handle, WM_SYSCOMMAND, SC_CLOSE, 0);
 //mform.miExitClick (sender);
 //close;
end;

procedure Tsform.btnClassicClick(Sender: TObject);
begin
 hide;
 mform.Show;
 pWgcSettings.bSimpleView := false;
end;

procedure Tsform.FormCreate(Sender: TObject);
begin
 sfrm := handle;
 SetMargins (mhint1.Handle, 2, 4);
 SetMargins (mhint2.Handle, 2, 4);
 SetMargins (mhint3.Handle, 2, 4);
 btnScan.OnClick := mform.btnScanClick;
 btnSieve.OnClick := mform.BtnSieveClick;
 btnClear.OnClick := frmAddrs.btnClearClick;
 btnSaveTab.OnClick := frmAddrs.btnSaveClick;
 btnLoadTab.OnClick := frmAddrs.btnLoadClick;
 edexmin.OnChange := mform.ed_minexChange;
 miHelp.OnClick := mform.miHelpClick;
 OnMouseWheel := mform.FormMouseWheel;
 pcMain.ActivePageIndex := 0;
 btnAdd.OnClick := mform.btnAddClick;
 with sgtable do
  begin
   cells [X_LOCK, 0] := 'Lock';
   cells [X_DESCR, 0] := 'Название значения';
   cells [X_ADDR, 0] := 'Адрес';
   cells [X_VALUE, 0] := 'Значение';
   cells [X_CHEAT, 0] := 'Новое';
   cells [X_TYPE, 0] := 'Тип';
   cells [X_GROUP, 0] := 'Группа';
   cells [X_FILTER, 0] := '№';
  end;
end;

procedure Tsform.lvAppsClick(Sender: TObject);
begin
 mform.lvPSlist.Selected := lvApps.Selected;
 mform.lvPSlistDblClick (sender);
 if (csm.svars.aliased) then
  begin
   pcMain.ActivePageIndex := 1;
   caption := 'WinnerGameCheater - "' + csm.prcs.title + '"';
  end; 
end;

procedure Tsform.lvAppsSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
 mform.lvPSlist.ItemIndex := lvApps.ItemIndex;
 mform.lvPSlistSelectItem(sender, item, selected);
end; // lvApps

procedure Tsform.sgtableMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
   gc: TGridCoord;
   pt: TPoint;
begin
 gc := sgtable.MouseCoord (x, y);
 if (gc.Y > 0) and (gc.Y < sgtable.RowCount) then
 with sgtable, mform, frmAddrs do
  begin
   dstcell := gc;
   pt.x := x;
   pt.y := y;
   pt := sgtable.ClientToScreen (pt);
   if (gc.X = 0) then
     if   Cells [0, gc.y] = 'LOCK' then Cells [0, gc.y] := ''
     else Cells [0, gc.y] := 'LOCK';
   if (button <> mbRight) then exit;
   if (gc.X = 1) then pmDescriptions.popup (pt.x, pt.y);
   if (gc.X in [2..3]) then pmChTable.Popup (pt.x, pt.y);
   if (gc.X = 4) then pmValues.Popup (pt.x, pt.y);
   if (gc.X = 5) then
    begin
     pt.x := x;
     pt.y := y;
     pt := sgtable.ClientToScreen (pt);
     pmType.Popup (pt.x, pt.y);
    end;
   if (gc.X = 6) then cells [gc.x, gc.y] := ''; // фильтрация 
  end;
end;

procedure Tsform.sgtableSetEditText(Sender: TObject; ACol, ARow: Integer;
  const Value: String);
begin
 with frmAddrs.sgCheat do
   if (cells [acol, arow] <> value) then cells [acol, arow] := value;
end; // Метод синхронизации

procedure Tsform.btnCheatClick(Sender: TObject);
begin
 frmAddrs.btnCheatClick (sender);
end;

procedure Tsform.pcMainChanging(Sender: TObject; var AllowChange: Boolean);
begin
 AllowChange := (csm.svars.aliased);
 if not AllowChange then
   pcMain.ActivePageIndex := 0;
end;

procedure Tsform.cbTypesSelect(Sender: TObject);
var s: string;
begin
 s := cbTypes.Text;
 s := StrInQts (s, '(', ')');
 frmAddrs.stype := s;
 mform.btnType.Caption := s;
 SaveRqs;
end;

procedure Tsform.OnComplete;
begin
 lfound.Caption := 'Найдено значений: ' + IntToStr (csm.FoundAll);
end;

procedure Tsform.cbRulesSelect(Sender: TObject);
var s: string;
begin
 s := cbRules.Text;
 s := StrInQts (s, '(', ')');
 mform.btnRule.Caption := s;
 SaveRqs;
end;

procedure Tsform.FormShow(Sender: TObject);
begin
 frmOptions.BorderStyle := bsDialog;
 frmOptions.Align := alNone;
 frmOptions.Parent := nil;
 frmOptions.Visible := false;
 if Assigned (csm) then
 begin
  tsh2.Enabled := csm.svars.aliased;
  tsh3.Enabled := csm.svars.aliased;
 end; 
end;
              
procedure Tsform.pmSettingsClick(Sender: TObject);
begin
 frmOptions.ShowModal;
end;

end.
