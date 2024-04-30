unit ChOptions;

interface

uses 
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, IniFiles, KbdAPI, KbdDefs, HotKeyDlg, ExtCtrls,
  ChClient;

type
  TfrmOptions = class(TForm)
    tvOptTree: TTreeView;
    pnFrame: TPanel;
    pctrlOptions: TPageControl;
    tsOptions_scaner: TTabSheet;
    gbScanBuffer: TGroupBox;
    lbBuffSize: TLabel;
    edBuffSz: TEdit;
    btnSetBuffSz: TButton;
    gbOptimization: TGroupBox;
    lPriority: TLabel;
    cbPriority: TComboBox;
    cbTimerX: TCheckBox;
    cbFreezze: TCheckBox;
    cbUIupdate: TCheckBox;
    cbIdleRead: TCheckBox;
    tsOptions_interface: TTabSheet;
    gbConsole: TGroupBox;
    lbTransparency: TLabel;
    cbConsole: TCheckBox;
    tbTransp: TTrackBar;
    cbInputCapture: TCheckBox;
    gbTab2View: TGroupBox;
    cbQueryList: TCheckBox;
    cbRuleBtns: TCheckBox;
    tsOptions_hotkeys: TTabSheet;
    lbHotKeys: TLabel;
    edHotKey: TEdit;
    lbxHotKeys: TListBox;
    tsOptions_popup: TTabSheet;
    gbResolution: TGroupBox;
    lClr: TLabel;
    lFreq: TLabel;
    cbResres: TCheckBox;
    cbScrRes: TComboBox;
    cbScrBPP: TComboBox;
    cbScrFreq: TComboBox;
    btnResTest: TButton;
    btnClose: TButton;
    procedure btnSetBuffSzClick(Sender: TObject);
    procedure cbPriorityChange(Sender: TObject);
    procedure cbTimerXClick(Sender: TObject);
    procedure btnResTestClick(Sender: TObject);
    procedure cbRuleBtnsClick(Sender: TObject);
    procedure edHotKeyKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbFreezzeClick(Sender: TObject);
    procedure cbUIupdateClick(Sender: TObject);
    procedure cbQueryListClick(Sender: TObject);
    procedure lbxHotKeysClick(Sender: TObject);
    procedure tvOptTreeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    { Private declarations }
    nActivePage: Integer;
    cfgfile: TIniFile;
    procedure ShowSelectedTab;
    procedure AddOptionsPage(const name: string; page: TTabSheet);  // Файл хранения конфигурации wgc
  public
    { Public declarations }
    procedure LoadCfg;
    procedure SaveCfg;
    procedure Init;
  end;

var
  frmOptions: TFrmOptions;

implementation
uses ChLang, ChCodes, ChSettings, ChForm, ChSimp, ChModeDlg, MISK, ChMsg, ChCmd, ChShare, ChTypes,
     netipc, ChConst;

{$R *.dfm}
procedure TfrmOptions.AddOptionsPage;
begin
 tvOptTree.Items.AddObject (nil, name, Ptr (page.PageIndex));
end;

procedure TfrmOptions.Init;
begin
 // Создание дерева настроек
 AddOptionsPage ('Настройки сканера', tsOptions_scaner);
 AddOptionsPage ('Интерфейс', tsOptions_interface);
 AddOptionsPage ('Горячие клавиши', tsOptions_hotkeys);
 AddOptionsPage ('Всплытие программы', tsOptions_popup); 
 // Создание изменяемого списка горячих клавишах
 lbxHotKeys.Items.AddObject ('Поиск', hotkeys [hkIndex (hkScanStart)]);
 lbxHotKeys.Items.AddObject ('Отсев', hotkeys [hkIndex (hkSieveStart)]);
 lbxHotKeys.Items.AddObject ('Прерывание поиска/отсева', hotkeys [hkIndex (hkBreakScan)]);
 lbxHotKeys.Items.AddObject ('Вставка чит-кода', hotkeys [hkIndex (hkSendChCode)]);
 lbxHotKeys.Items.AddObject ('Останов игры', hotkeys [hkIndex (hkFreeze)]);
 lbxHotKeys.Items.AddObject ('Возобновление игры', hotkeys [hkIndex (hkUnFreeze)]);
 lbxHotKeys.Items.AddObject ('Всплытие программы', hotkeys [hkIndex (hkPopupApp)]);
 lbxHotKeys.Items.AddObject ('Переход в игру', hotkeys [hkIndex (hkToGame)]);
 lbxHotKeys.Items.AddObject ('Вызов консоли', hotkeys [hkIndex (hkShowCons)]);
 ShowSelectedTab;
end;

procedure TFrmOptions.LoadCfg;
// const yno : array [false..true] of string = ('No','Yes');

var fUndefined: Boolean;
function  GetBool (const sect, ident, default: string): boolean;
var S: String;
begin
 S := UpperCase (cfgFile.ReadString (sect, ident, default)); // значение параметра
 result := S = 'YES';
 fUndefined := not result and (s <> 'NO');
end; // GetBool

var
   s : string;
   d : dword;
   i, n : dword;
begin
 pWgcSettings.bUpdateUI := true;
 pWgcSettings.bIdleRead := true;
 with pWgcSettings^ do 
 if (pos ('wgc.ini', cfgFile.FileName) > 0) then
  begin
   s := 'wgceng.txt';
   if (GetSystemDefaultLangID and $7FF = $419) then s := 'none';
   s := cfgFile.ReadString('Interface', 'LocaleFile', s);
   if (s <> 'none') then Localize (s); // Локализация
   s := UpperCase (cfgFile.ReadString('Scaner', 'Priority', 'HIGHEST'));
   if (s = 'NORMAL')  then nScanPriority := THREAD_PRIORITY_NORMAL;
   if (s = 'HIGHEST') then nScanPriority := THREAD_PRIORITY_HIGHEST;
   if (s = 'TIMECRITICAL') then nScanPriority := THREAD_PRIORITY_TIME_CRITICAL;
   if (s <> '') then cbPriority.ItemIndex := cbPriority.Items.IndexOf (s);
   s := cfgFile.ReadString ('Scaner', 'BuffSize', '56');
   if (s <> '') then edBuffSz.Text := s;
   bPrefetch := GetBool ('Scaner', 'Prefetch', 'No');
   mform.cbPrefetch.Checked := bPrefetch;
   bUseMMX := GetBool ('Scaner', 'UseMMX', 'No');
   mform.cbMMX.Checked := bUseMMX;
   maxRegSize := cfgFile.ReadInteger ('Scaner', 'MaxRegionsSize', 64);
   mform.edMaxRegsize.Text := IntToStr (maxRegSize);
   nTimerInt := cfgFile.ReadInteger ('Interface', 'MainTimer', 50);
   if (nTimerInt = 0) or (nTimerInt > 500) then nTimerInt := 50;
   mform.FastTimer.Interval := nTimerInt;
   cbRuleBtns.Checked := GetBool ('Interface', 'ShowRuleButtons', 'No');
   bShowIcons := GetBool ('Interface', 'ShowIcons', 'Yes');
   mform.cbAutoselect.Checked := GetBool ('Interface', 'AutoselectGame', 'No');
   bSimpleView := GetBool ('Interface', 'SimpleView', 'Undefined');
   cbQueryList.Checked := GetBool ('Interface', 'ShowQueryList', 'No');
   mform.ShowQueryList (cbQueryList.Checked);
   if fUndefined then RunModeSelDialog (bSimpleView);
   bUpdateUI := GetBool ('Interface', 'UIupdate', 'No');
   cbUIupdate.Checked := bUpdateUI;
   mform.RuleBtns.Visible := cbRuleBtns.Checked;
   mform.pscparams.scanPages.MaxRegionSize := pWgcSettings.maxRegSize;
   ServerAddr := cfgFile.ReadString ('Network', 'ServerAddress', 'localhost');
   serverPort := cfgFile.ReadInteger ('Network', 'ServerPort', serverPort);
   serverIdent := cfgFile.ReadInteger ('Network', 'ServerIdent', serverIdent);
   // Чтение настроек горячих клавиш
   for i := 1 to High (hkList) do
    begin
     n := HkIndex (hkList [i]);
     if (n > 0) then
     with hotkeys [n] do
      begin
       // Чтение горячей клавиши из файла настроек
       d := cfgFile.ReadInteger('Hotkeys', hkList [i], key + dword (flags) shl 16);
       key := d and $FFFF;
       flags := (d shr 16) and $FF;
      end;
    end; // for control
  end;
end;

procedure TFrmOptions.SaveCfg;
const
     blstr : array [false..true] of string = ('No', 'Yes');
var s : string;
    i, n: dword;
begin
 if (pos ('wgc.ini', cfgFile.FileName) > 0) then
 with cfgFile, pWgcSettings^ do
  begin
   maxRegSize := mform.pscparams.scanPages.MaxRegionSize;
   s := cbPriority.Text;
   if (s = '') then s := 'HIGHEST';
   WriteString ('Scaner', 'Priority', s);
   s := edBuffSz.Text;
   if (s = '') then s := '256';
   WriteString  ('Scaner', 'BuffSize', s);
   WriteString  ('Scaner', 'Prefetch', blstr [ByteBool (bPrefetch)]);
   WriteInteger ('Scaner', 'MaxRegionsSize', maxRegSize);
   WriteString ('Scaner', 'UseMMX', blstr [bUseMMX]);
   WriteString  ('Interface', 'AutoselectGame', blstr [mform.cbAutoselect.checked]);
   WriteString  ('Interface', 'LocaleFile', lclFile);
   WriteInteger ('Interface', 'MainTimer', nTimerInt);
   WriteString ('Interface', 'ShowIcons', blstr [bShowIcons]);
   WriteString  ('Interface', 'ShowRuleButtons', blstr [cbRuleBtns.checked]);
   WriteString  ('Interface', 'ShowQueryList', blstr [cbQueryList.Checked]);
   WriteString  ('Interface', 'SimpleView', blstr [bSimpleView]);
   WriteString  ('Interface', 'UIupdate', blstr [bUpdateUI]);
   WriteString  ('Network', 'ServerAddress', serverAddr);
   WriteInteger ('Network', 'ServerPort', serverPort);
   WriteInteger ('Network', 'ServerIdent', serverIdent);

   // Сохранение списка горячих клавиш
   for i := 1 to High (hkList) do
    begin
     n := HkIndex (hkList [i]);
     if (n > 0) then
     with hotkeys [n] do // Запись горячей клавиши в файл настроек
       cfgFile.WriteString ('Hotkeys', hkList [i], '$' + dword2hex (key + dword (flags) shl 16));
    end; // for control
  end;
end;

procedure TfrmOptions.btnSetBuffSzClick(Sender: TObject);
var e : Integer;
    sz : dword;
begin
 val (edBuffSz.text , sz, e);
 if sz < 32 then sz := 32;
 if sz > 8192 then sz := 8192;  // Небольше 8 мегабайт
 edBuffSz.text := IntToStr (sz);
 sz := (sz shr 2) shl 2; // кратно 4
 pWgcSettings.buffSize := sz * 1024;
 SendMsgEx (CM_RESIZE, pWgcSettings.buffSize);
end;

procedure TfrmOptions.cbPriorityChange(Sender: TObject);
begin
 with pWgcSettings^ do
 case cbPriority.ItemIndex of
  0 : nScanPriority := THREAD_PRIORITY_NORMAL;
  1 : nScanPriority := THREAD_PRIORITY_HIGHEST;
  2 : nScanPriority := THREAD_PRIORITY_TIME_CRITICAL;
 end;
end;

procedure TfrmOptions.cbTimerXClick(Sender: TObject);
begin
 mform.Uit.Enabled := cbTimerX.Checked;
end;

procedure TfrmOptions.btnResTestClick(Sender: TObject);
var

   dm : _deviceModeA;

procedure  SetRes (const w, h : dword);
begin
 dm.dmPelsWidth := w;
 dm.dmPelsHeight := h;
end;

var e : Integer;
begin
 case cbScrRes.ItemIndex of
  0 : SetRes (640, 480);
  1 : SetRes (720, 480);
  2 : SetRes (800, 600);
  3 : SetRes (1024, 768);
  4 : SetRes (1280, 1024);
 end;
 val (cbScrBpp.Text, dm.dmBitsPerPel, e);
 if e <> 0 then dm.dmBitsPerPel := 32;
 val (cbScrFreq.text, dm.dmDisplayFrequency, e);
 if e <> 0 then dm.dmDisplayFrequency := 85;	
 dm.dmSize := SizeOf (dm);
 dm.dmFields := DM_BITSPERPEL or DM_PELSWIDTH or
                DM_PELSHEIGHT or DM_DISPLAYFREQUENCY;
 ChangeDisplaySettingsA (dm, 0);
end;

procedure TfrmOptions.cbRuleBtnsClick(Sender: TObject);
begin
 mform.ruleBtns.Visible := cbRuleBtns.Checked;
end;

procedure TfrmOptions.edHotKeyKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
   indx: Integer;
   flags: byte;
begin
 indx := lbxHotKeys.ItemIndex;
 if (indx < 0) then exit; // Не выбран элемент для горячей клавишы
 flags := byte (shift) and $7F; // Перевести в флажки
 if IsPressed (VK_LWIN) then flags := flags or KF_WIN;
 StoreHotKey (lbxHotKeys.Items.objects [indx], key, flags);
 // Попытка замены горячей клавиши
 edHotKey.Text := StrKey (key, flags);
end;

procedure TfrmOptions.cbFreezzeClick(Sender: TObject);
begin
 pWgcSettings.bSuspend := cbFreezze.Checked;
end;

procedure TfrmOptions.cbUIupdateClick(Sender: TObject);
begin
 pWgcSettings.bUpdateUI := cbUIupdate.Checked;
end;

procedure TfrmOptions.cbQueryListClick(Sender: TObject);
begin
 mform.ShowQueryList (cbQueryList.Checked);
end;

procedure TfrmOptions.lbxHotKeysClick(Sender: TObject);
var indx: Integer;
    sobj: TObject;
begin
 indx := lbxHotKeys.ItemIndex;
 if (indx < 0) then exit;
 sobj := lbxHotKeys.Items.Objects [indx];
 // Получить горячую клавишу в текстовом виде
 if Assigned (sobj) and (sobj is THotKeyData) then
    edHotKey.Text := THotKeyData (sobj).str;
end;

procedure TFrmOptions.ShowSelectedTab;
var n: Integer;
begin
 if Assigned (pctrlOptions.ActivePage) then
    pctrlOptions.ActivePage.TabVisible := false; {}

 for n := 0 to pctrlOptions.PageCount - 1 do
  with pctrlOptions.Pages [n] do
   begin
    TabVisible := false;
    Visible := (n = nActivePage);
   end;
end;


procedure TfrmOptions.tvOptTreeClick(Sender: TObject);
begin
 if Assigned (tvOptTree.Selected) then
    nActivePage := Integer (tvOptTree.Selected.Data);
 ShowSelectedTab;
end;


procedure TfrmOptions.FormCreate(Sender: TObject);
begin
 cfgFile := TIniFile.Create (csm.wgcPath + 'wgc.ini');
 nActivePage := 0;
 // pctrlOptions.Top := -15;
 ShowSelectedTab;
end;

procedure TfrmOptions.FormShow(Sender: TObject);
begin
 Caption := mform.tsOptions.Caption;
 if parent = nil then
  begin
   btnClose.Show;
   Top := Screen.Height div 2 - Height div 2;
   Height := btnClose.Top + btnClose.Height + 32;
  end
 else
  begin
   Top := 0;
   Height := pnFrame.Top + pnFrame.Height + 2;
   btnClose.Hide;
  end;
end; // OnShow

procedure TfrmOptions.btnCloseClick(Sender: TObject);
begin
 close;
end;

end.
