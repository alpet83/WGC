{$DEFINE WINDOWS}

unit ChForm;


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Menus, TlHelp32, StdCtrls, ImgList, Grids, prcsmap,
  ChAbout,  Buttons, ChSpy, ChTypes, ChShare, Math, ChLog, SocketAPI,
  netipc, ChClient, DataProvider, ChConst, TlHelpEx,
  IniFiles, ActnList, Spin, ExtCtrls, Gauges, KbdAPI, ChOptions, ChSettings;


const
  sWGCtablesFilter = 'WGC cheat files|*.chf|WGC cheatX files|*.chx';
  
var
   gbAppTerminate: Boolean = FALSE;
type


  TMForm = class (TForm)
    mmenu: TMainMenu;
    pmView: TMenuItem;
    UIT: TTimer;
    pmProcess: TMenuItem;
    miTh32: TMenuItem;
    miUser32: TMenuItem;
    FastTimer: TTimer;
    SaveDlg: TSaveDialog;
    OpenDlg: TOpenDialog;
    pmHelp: TMenuItem;
    miAbout: TMenuItem;
    IML1: TImageList;
    pmDebug: TMenuItem;
    miTerminate: TMenuItem;
    ReadyIL: TImageList;
    pmType: TPopupMenu;
    BYTE1: TMenuItem;
    WORD1: TMenuItem;
    DWORD1: TMenuItem;
    span: TPanel;
    miMem: TMenuItem;
    miMsgs: TMenuItem;
    SBAR: TStatusBar;
    miLocalize: TMenuItem;
    miAlwaysOnTop: TMenuItem;
    pmFile: TMenuItem;
    miExit: TMenuItem;
    pctrl: TPageControl;
    ts1: TTabSheet;
    lbICount: TLabel;
    l7: TLabel;
    btnHide: TButton;
    btnRestore: TButton;
    ed_hwnd: TEdit;
    ts2: TTabSheet;
    sb_up: TSpeedButton;
    sb_down: TSpeedButton;
    lRqsNum: TLabel;
    LMin: TLabel;
    LMax: TLabel;
    readyImage: TImage;
    lRqsText: TLabel;
    sspan: TPanel;
    lbDeltaX: TLabel;
    btnScan: TButton;
    btnBreak: TButton;
    BtnSieve: TButton;
    btnIncSv: TButton;
    BtnDecSv: TButton;
    ed_minex: TEdit;
    ed_maxex: TEdit;
    cb_enabled: TCheckBox;
    btnType: TButton;
    btnRule: TButton;
    ts3: TTabSheet;
    Ts4: TTabSheet;
    tsOptions: TTabSheet;
    lHWND: TLabel;
    EXT1: TMenuItem;
    REAL1: TMenuItem;
    SINGLE1: TMenuItem;
    DOUBLE1: TMenuItem;
    EXTENDED1: TMenuItem;
    btnCodes: TButton;
    EXT2: TMenuItem;
    pmRule: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    N10: TMenuItem;
    N11: TMenuItem;
    N12: TMenuItem;
    N13: TMenuItem;
    N14: TMenuItem;
    N15: TMenuItem;
    N16: TMenuItem;
    N17: TMenuItem;
    miHelp: TMenuItem;
    pmPlugins: TMenuItem;
    ctrlPan: TPanel;
    sbPrevTab: TSpeedButton;
    sbNextTab: TSpeedButton;
    ruleBtns: TPanel;
    btnUnk: TButton;
    btnPP: TButton;
    btnMM: TButton;
    btnPE: TButton;
    btnME: TButton;
    bntNE: TButton;
    bntEQ: TButton;
    btnAbove: TButton;
    btnBelow: TButton;
    btnNotBelow: TButton;
    btnNoAbove: TButton;
    btnNotEqual: TButton;
    btnMult: TButton;
    btnRange: TButton;
    mstate: TMemo;
    miALL: TMenuItem;
    gProgress: TGauge;
    delta: TSpinEdit;
    lvPSlist: TListView;
    IconList: TImageList;
    multp: TSpinEdit;
    lbProcess: TLabel;
    lbRules: TLabel;
    btnDestroy: TButton;
    miSimple: TMenuItem;
    btnGame: TButton;
    cbAutoselect: TCheckBox;
    toolbarImages: TImageList;
    btnSite: TButton;
    btnExit: TButton;
    pgMem: TPageControl;
    tsLibrarys: TTabSheet;
    tvMemBlocks: TTreeView;
    cb_text: TCheckBox;
    cb_bss: TCheckBox;
    cb_rdata: TCheckBox;
    cb_data: TCheckBox;
    cb_rsrc: TCheckBox;
    cb_edata: TCheckBox;
    cb_idata: TCheckBox;
    cb_stack: TCheckBox;
    cb_heap: TCheckBox;
    edLib: TEdit;
    btnFind: TButton;
    lDLL: TLabel;
    lbFunc: TLabel;
    edProc: TEdit;
    edResultPtr: TEdit;
    tsRegions: TTabSheet;
    lvRegions: TListView;
    colorsIL: TImageList;
    lRegionsDescr: TLabel;
    miNewTrainer: TMenuItem;
    miCheatCodes: TMenuItem;
    edMaxRegsize: TEdit;
    lbMaxRegSize: TLabel;
    gbByTypes: TGroupBox;
    cbMem_Image: TCheckBox;
    cbMem_Mapped: TCheckBox;
    cbMem_Private: TCheckBox;
    gbByAttrs: TGroupBox;
    cbNoCache: TCheckBox;
    cbReadOnly: TCheckBox;
    cbExecutable: TCheckBox;
    cb_aligned: TCheckBox;
    Panel3: TPanel;
    lregion: TLabel;
    ed_gLimit: TEdit;
    ed_gbase: TEdit;
    cbMMX: TCheckBox;
    cbPrefetch: TCheckBox;
    cbRWtest: TCheckBox;
    panQueryList: TPanel;
    RqsList: TListBox;
    rqs1: TButton;
    rqs2: TButton;
    rqs3: TButton;
    rqs4: TButton;
    rqs5: TButton;
    rqs6: TButton;
    rqs7: TButton;
    rqs8: TButton;
    rqs9: TButton;
    addrPanel: TPanel;
    lAddrs: TLabel;
    btnSavRslts: TButton;
    BtnLoadRslts: TButton;
    btnAdd: TButton;
    btnOnlyOne: TButton;
    llistdesc: TLabel;
    sshot_panel: TPanel;
    imGameView: TImage;
    lbxAddrs: TListBox;
    miUnfreeze: TMenuItem;
    btnHideQueryList: TButton;
    btnHideRulePan: TButton;
    lbFoundCount: TLabel;
    actlist: TActionList;
    seltab: TAction;
    pnTable: TPanel;
    lbHah: TLabel;
    pnPSchkboxs: TPanel;
    cbVis: TCheckBox;
    cbVoid: TCheckBox;
    cbChilds: TCheckBox;
    cb_shwnd: TCheckBox;
    cb_oone: TCheckBox;
    cbShowPID: TCheckBox;
    cbWindowless: TCheckBox;
    btnUnloadSpy: TButton;
    lbxThreads: TListBox;
    lThreads: TLabel;
    imConnect: TImage;
    ilLamps: TImageList;
    plvx_cache: TListView;
    IconList2: TImageList;
    procedure UITTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miTh32Click(Sender: TObject);
    procedure miUser32Click(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure pctrlChange(Sender: TObject);
    procedure lvPSlistClick(Sender: TObject);
    procedure btnBreakClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure FastTimerTimer(Sender: TObject);
    procedure miAboutClick(Sender: TObject);
    procedure cb_textClick(Sender: TObject);
    procedure btnSetRuleClick(Sender: TObject);
    procedure cb_rqs1Click(Sender: TObject);
    procedure BtnSieveClick(Sender: TObject);
    procedure btnIncSvClick(Sender: TObject);
    procedure BtnDecSvClick(Sender: TObject);
    procedure sb_upClick(Sender: TObject);
    procedure sb_downClick(Sender: TObject);
    procedure OnUpdate (Sender : TObject);
    procedure sgCheatKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnHideClick(Sender: TObject);
    procedure btnRestoreClick(Sender: TObject);
    procedure cb_ooneClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure BtnSppRestClick(Sender: TObject);
    procedure BtnSppMClick(Sender: TObject);
    procedure btnWinClick(Sender: TObject);
    procedure miTerminateClick(Sender: TObject);
    procedure btnUnloadSpyClick(Sender: TObject);
    procedure rqs1Click(Sender: TObject);
    procedure ed_gLimitExit(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure ed_minexMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure miHookClick(Sender: TObject);
    procedure miMsgsClick(Sender: TObject);
    procedure cbPriorityChange(Sender: TObject);
    procedure miLocalizeClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnFindClick(Sender: TObject);
    procedure miAlwaysOnTopClick(Sender: TObject);
    procedure btnSavRsltsClick(Sender: TObject);
    procedure BtnLoadRsltsClick(Sender: TObject);
    procedure rqs1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnCodesClick(Sender: TObject);
    procedure miHelpClick(Sender: TObject);
    procedure miPluginClick(Sender: TObject);
    procedure SelectPrevTab(Sender: TObject);
    procedure SelectNextTab(Sender: TObject);
    procedure pctrlChanging(Sender: TObject; var AllowChange: Boolean);
    procedure RqsListClick(Sender: TObject);
    procedure imGameViewDblClick(Sender: TObject);
    procedure btnTypeClick(Sender: TObject);
    procedure imGameViewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure lvPSlistDblClick(Sender: TObject);
    procedure lvPSlistKeyPress(Sender: TObject; var Key: Char);
    procedure lvPSlistSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure lvPSlistMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ed_minexChange(Sender: TObject);
    procedure ed_maxexChange(Sender: TObject);
    procedure ed_minexKeyPress(Sender: TObject; var Key: Char);
    procedure miSimpleClick(Sender: TObject);
    procedure sgCheatSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: String);
    procedure btnGameClick(Sender: TObject);
    procedure btnOnlyOneClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnTrainerClick(Sender: TObject);
    procedure btnSiteClick(Sender: TObject);
    procedure lvRegionsCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure cbNoCacheClick(Sender: TObject);
    procedure cbReadOnlyClick(Sender: TObject);
    procedure cbExecutableClick(Sender: TObject);
    procedure lvRegionsColumnClick(Sender: TObject; Column: TListColumn);
    procedure cbPSComboClick(Sender: TObject);
    procedure cbMem_MappedClick(Sender: TObject);
    procedure cbMem_ImageClick(Sender: TObject);
    procedure cbMem_PrivateClick(Sender: TObject);
    procedure cb_alignedClick(Sender: TObject);
    procedure cbMMXClick(Sender: TObject);
    procedure cbRWtestClick(Sender: TObject);
    procedure btnHideQueryListClick(Sender: TObject);
    procedure btnHideRulePanClick(Sender: TObject);
    procedure cbPrefetchClick(Sender: TObject);
    procedure edMaxRegsizeExit(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure BYTE1Click(Sender: TObject);
    procedure cbShowPIDClick(Sender: TObject);

  private
    fdblclick: boolean;
        fnone: boolean;
     psrcount: Integer;
   mmsUpdated: Boolean; // Memory Map Settings Updated
   bPSCanSelect: Boolean;
    procedure  AddOrSub (var s: string;const dx, mul: Integer);
    function   AddOrSubEx (const c: TCaption; const dx, mul: Integer):  TCaption;
    procedure  SearchValues (const s : string);
    procedure  AddAddr (const frec: TFoundRec; ii: Integer);
    procedure  AddAddrs (n: Integer);
    procedure  ListFound (n: byte);
    procedure  PaintReady;
    procedure  PaintBusy;
    procedure  OpenThisProcess;
    procedure  InitHints;
    function   GetGrid: TStringGrid;
    procedure SetScanRange;
    procedure TerminationStart;
    procedure SendMapRescan;

    function  Ready: Boolean;
    procedure ShowInterface;
    { Private declarations }
public
    { Public declarations =================================================== }
    pscparams: PScanProcessParam;

   vpositions: array [1..3] of Short; // Вертикальные позиции вкладки 2
      factive: boolean; // Текущее приложение - WGC
        fBusy: Boolean; // Занят поиском/отсевом
       dllico: HICON;
       fClick: Boolean;  // Процесс открывается кликом
       iTicks: DWORD;
      sortcol: word;
      sortdir: Integer;  // Направление
     nSelfPID: DWORD;
    bInterfaceReady: Boolean;

   property  sgt: TStringGrid read GetGrid; // Текущая таблица с кодами

   procedure UpdatePlvx (Sender: TObject);
   procedure OnAliasing (const fAliasing : boolean);
   procedure UpdateProgress;
   procedure AfterInit;
   procedure ClearAddrs;
   procedure CopyPSListCache;


   procedure ListChCodes;
   procedure ListTable;         // Вывод указателей в консоль

   procedure PopupApp (mgame: boolean = true);
   // Преобразование строкового запроса
   procedure ParseCmd (const s: string);

   procedure ReceiveScanResults(prec: PFoundRec);

   procedure SetConState (bConnect: Boolean); // визуализации состояния подключения

   procedure ShowQueryList(bShow: Boolean);
   procedure ShowScanResults(const inf: PScanProcessInfo);

   procedure SyncRqs;           // Синхронизация запросов

   procedure OnGameTerminated;
   procedure OnProcessClosed;
   procedure OnPSListAddComplete;

   procedure OnOpenMutex(pszName: PAnsiChar; Index: Integer);
   procedure OnAcquireMutex(index: Integer);
   procedure OnSyncMessage(msgid, wp, lp: Integer);
   procedure OnOpenProcess(const p: TBasePacket);
   procedure OnReleaseMutex(index: Integer);
   procedure OnScanProgress(scanCount, times: Int64);
   procedure OnScanComplete;
   procedure OnVMSMapCreated (vmsize: DWORD);


   procedure OnUserMsg (var msg: TMessage); message WM_USER;
   procedure OnSysMsg (var msg: TMessage); message WM_SYSCOMMAND;
   procedure ReListAddrs;
   procedure UpdateProcessList;
  end; // TMForm declaration


type
    TSegRec = record
     name : string;
      sel : boolean;
    end;

var
   MForm: TMForm;
   firstLoad : boolean = false;
   ThCheck, AppExit : boolean;
   _alias : THandle;
   fmapx : boolean;
   firstHwnd: HWND;
   killThreads: Boolean = false;

implementation
uses
     vmisk, misk, RqsTable, ChSimp, ChModeDlg,
     Scandlg, ChTrain, LocalIPC,
     ChCodes, StrSrv, ChHelp, ChPlugin, ChView, spthread, ShellApi,
     TimeRts, ChCmd, ChDecomp, ChText, ChMsg, ChLang, ConfDlg, ChConsole,
     ChSource, HotKeyDlg, KbdDefs, CheatTable, Splash;

{$R *.DFM}
const
   segnames : array [1..8] of String =
   ('.text', '.bss', '.rdata', '.data',
    '.rsrc', '.edata', '.idata', '.stack');

var
   segsel : array [1..8] of boolean; 


procedure TMForm.btnBreakClick(Sender: TObject);
begin
 csm.svars.fbreak := true;
end; // прерывание поиска

procedure TMForm.btnAddClick(Sender: TObject);
begin
 AddAddrs (csm.CurrRqs);
 wtUpdated := TRUE;
end;

procedure TMForm.OnAliasing;
begin
 ts2.TabVisible := true;
 ts3.TabVisible := true;
 ts4.TabVisible := true;
 tsOptions.TabVisible := true;
 miTerminate.Enabled := fAliasing;
end; // OnAliasing

procedure TMform.UpdateProgress;
var
   c, m, p : int64;
begin
 c := csm.svars.scanAll;
 m := csm.vmsize;
 if m = 0  then p := 1000
           else p := int64 (c * 1000) div int64(m);
 // assert (p <= 100, 'Ошибка в расчетах процентов');
 if p > 1000 then p := 1000;
 scpdlg.SetProgress(p, csm.FoundAll);
 gProgress.Progress := p;
 sbar.panels [0].text :=
    format ('Ptr: $%p    Mem: ', [pointer (csm.SVars.sofst)]) +
    msdiv (c) + ' / ' + msdiv (m);
{
 if (fcons) then
     con.SetLast (' Завершено: ' + IntToStr (p div 10) + '% '); {}
 Application.ProcessMessages;
end; // UpdateInSP;


procedure  TMform.ListFound (n : byte);
var i : byte;

begin
 lbxAddrs.Items.Clear;
 lbxAddrs.Items.BeginUpdate;
 with csm, csm.svars.fnds [n] do
 if AddedCount > 0 then
 // Добавление адресов
 for i := 1 to AddedCount do
     lbxAddrs.items.Add (format ('$%x', [DWORD (addrs [i].vaddr)]))
 else lbxAddrs.items.Add ('Нет');
 if lbxAddrs.Items.Count > 0 then lbxAddrs.ItemIndex := 0
                             else lbxAddrs.ItemIndex := -1;
 lbxAddrs.Items.EndUpdate;
 sform.cbAddrs.Clear;
 sform.cbAddrs.Items := lbxAddrs.Items;
 sform.cbAddrs.ItemIndex := 0;
end;

procedure  TMform.AddAddr;
var
    sType: String;
begin
 with frec do
 if (ii > 0) and (ii <= AddedCount) then
 with addrs [ii] do
 begin
  sType := IntToStr (vsize); // Размер значения
  case vclass of                    // Класс значения
    st_text: sType := 'T' + sType;
    st_wide: sType := 'W' + sType;
    st_real: sType := 'R' + sType;
   end; // case
  vlist.AddImport ('',
                  format ('$%x', [vaddr]),
                  sType, '', 'Default')
 end;

end; // AddCheat

procedure  TMform.AddAddrs;
var ii:  byte;
begin
 with csm.svars.fnds [n] do
 for ii := 1 to AddedCount do
     AddAddr (csm.svars.fnds [n], ii);
 ReListAddrs;   
 frmAddrs.SyncGrids;
end; // AddCheats;

procedure TMForm.ClearAddrs;
var n: Integer;
begin
 lbxAddrs.Clear;
 for n := 1 to MaxRqs do
  FillChar (csm.svars.fnds [n], sizeof (TFoundRec), 0);
end;

procedure TMForm.ReListAddrs;
begin
 with frmAddrs do
 begin
  if bCellsChanged then
  // пересечение событий обновления списка/таблицы
    begin
     wtUpdated := TRUE;
     bCellsChanged := FALSE;
     vlist.LoadFromTable(sgt, TRUE);
     vlist.SendList;
     exit;
    end;
 end;
 ListAddrs (sgt, frmAddrs.cbGroup.Text, FALSE);
end;

procedure TMForm.FormCreate(Sender: TObject); 
begin
 // fsimple := false;
 bInterfaceReady := FALSE;
 netReady := false;
 firstHwnd := GetWindow (handle, GW_HWNDFIRST);
 nSelfPID := GetCurrentProcessId ();
 gProgress.Progress := 0;
 firstLoad := true;
 OnAliasing (false);
 Inherited;
 csm := nil;
 segsel [4] := true;
 fBusy := false;
 mwrect.left := 0;
 mwrect.top := 0;
 mwrect.Right := imGameView.Width;
 mwrect.bottom := imGameView.Height;
 Caption := wgc_text + ' ' + wgcver;

 mfrm := handle;
 SetWindowText (mfrm, PChar (wgc_text + ' ' + wgcver));
 btnSite.hint := 'Открыть страницу программы: ' + ProgSite + #13#10 +
                 'P.S. Нужно подключение к интернету.';
 visible := FALSE;
end;

           
procedure TMForm.AfterInit;
// Код процедуры *ChForm* TMForm.AfterInit
var h, w : DWORD;
    s : string;
begin
 Hide;
 mmsUpdated := TRUE;
 ilLamps.GetBitmap (0, imConnect.Picture.Bitmap);
 bConsoleCreated := GetStdHandle (STD_OUTPUT_HANDLE) <> 0;
 LogStr ('WGC-Client Initialization', TRUE, TRUE);
 psrcount := 0;
 lvPSlist.Visible := false;
 vpositions [1] := btnRule.Top;
 vpositions [2] := 172;
 vpositions [3] := ruleBtns.Top;
 iticks := 0;
 makeAlias := false;            // Создание обьекта в общей памяти
 csm := TShareMem.Create;
 smObj := csm;
 pWgcSettings := @csm.Settings;
 pscparams := @csm.svars.params;
 csm.svars.params.ScanPages.MaxRegionSize := pWgcSettings.MaxRegSize;
 s := ExtractFilePath (ParamStr (0));
 if (s = '') or (s [Length (s)] <> '\') then s := s + '\';
 StrPCopy (csm.wgcPath, s);
 frmAddrs := TFrmAddrs.Create(Application);
 frmOptions := TFrmOptions.Create(Application);
 strPCopy (csm.wgcver, wgcver); // записать номер версии библиотеки
 // Получение пути
 csm.ownerId := GetCurrentThreadId;
 csm.mainWnd := handle;                  // Главное окно
 pWgcSettings.buffSize := 112 * 1024;    // Буфер большой
 csm.SpyVars.fSIS := false;
 frmOptions.LoadCfg;
 LogStr ('Performing network initialization...');
 client := TNetClient.Create;
 client.Init;
 //InitNetwork;
 { -------------------------------------------------------------- }
 csm.SVars.orNeed := False;
 csm.SVars.aliased := false;
 csm.SpyVars.fSIS := false;
 pctrl.ActivePageIndex := 0;
 csm.prcs.pid := 0;
 csm.CurrRqs := 1;
 RqsInit (_noact);
 h := csm.ActiveClient;
 if (h > 0) then
  begin
   // dstID := csm.clients [h].ThreadId;     // ID поискового потока
   hSpyTHRD := csm.clients [h].hThread;   // Дескриптор поискового потока
  end;
 rqsList.Color := clCream;
 rqsList.Font.Color := clBlue;
 // Код для chmsg.Addmsg
 frmOptions.Init;
 ed_gLimit.Text := '$' + dword2hex (GMEM_LIMIT);
 h := btnExit.Top;
 height := h + 170;
 w := pctrl.Left + pctrl.Width + 10;
 width := w;
 span.Width := w - 10;
 constraints.MinWidth  := 645;
 Constraints.MaxWidth := 700;
 // TODO:{ StoreToMenu (pmPlugins);}
 InitBitmap;
 PaintBusy;
 fMessages.ManualDock (span);
 fMessages.Visible := true;
 uit.Enabled := true;
 UITTimer (self);
 cbPriorityChange (self); // Выставить Приоритет
 fmessages.Messages.OnMouseMove := ListMouseMove;
 Application.Title := wgc_text;
 lbProcess.caption := LocStr ('%ProcessNotSelected%');
 con := TConsole.Create;
 InitStrings;
 InitHints;
 sbar.Panels [0].Text := 'HINT: Смотри подсказки у кнопок. ';
 SendMessage (ed_minex.handle, EM_SETMARGINS, EC_LEFTMARGIN, 4);
 SendMessage (ed_maxex.handle, EM_SETMARGINS, EC_LEFTMARGIN, 4);
 if (lvPSlist.items.count > 0) then
     lvPSlist.Items.Item[0].Selected := true;
 
 with pscparams.ScanPages do
  begin
   // страницы доступные при поиске по умолчанию
   attrs := PAGE_READWRITE or
                PAGE_WRITECOPY or ExecutablePages;
   // attrs := SetBit (attrs, , true);
   fMemImage := true;
   fMemMapped := true;
   fMemPrivate := true;
   fTestRW := true;
  end;
 exmin := '0';
 sortcol := 0;
 sortdir := 1;
 csm.svars.fAligned := true;
 {$IFOPT D-}
  cbPrefetch.Hide;
  pWgcSettings.bPrefetch := false;
  IsReleaseBuild := true;
 {$ELSE}
  height := 650;
  AddMsg ('Warning: This is debug release!');
 {$ENDIF}
 wplist.OnUpdate := UpdatePlvx;
 // wlist.Update; // получить список основных процессов.
 gKbdInput := TKeybInput.Create;
 gKbdInput.Active := true;
 if (nil = AboutBox) then
  Application.CreateForm(TAboutBox, AboutBox);
 SnapShot;
 self.FormStyle := fsNormal;
 seltab.Execute;
 gAddrTable := sgt;
 FastTimer.Enabled := true;
 frmAddrs.Height := 360;
 SetForegroundWindow (Handle);
 SetScanRange;
 // ModifyStyle (cbQueryList.Handle, 0, BS_PUSHLIKE);
end; // AfterInit

procedure TMForm.InitHints;
begin
 btnType.hint := LoadStr (14000);
 sform.mhint1.text := LoadStr (14001);
 sform.mhint2.text := LoadStr (14002);
 sform.mhint3.text := LoadStr (14003);
end;

procedure TMForm.PaintReady;
begin
 fBusy := False;
 ReadyImage.Canvas.FillRect(ReadyImage.ClientRect);
 ReadyIL.Draw (ReadyImage.Canvas, 0, 0, 0);
 ReadyImage.Repaint;
end;

procedure TMForm.PaintBusy;
begin
 fBusy := True;
 ReadyImage.Canvas.FillRect(ReadyImage.ClientRect);
 ReadyIL.Draw (ReadyImage.Canvas, 0, 0, 1);
 ReadyImage.Repaint;
end;

function TMForm.Ready: Boolean;
begin
 result := csm.svars.aliased and
           (csm.vmsize > 0);
end;
{ Обновление списка процессов на форме }
procedure TMForm.UpdatePlvx;
var
   wlst: TWProcessArray;
begin
 // Эта функция вызывается как обработчик из метода TWProcessArray.Update
 if (sender is TWProcessArray) then wlst := TWProcessArray (sender)
                                else exit;

 wlst.Store (plvx_cache);
 // ListArray (@sform.lvApps);
end; //

procedure TMForm.UITTimer(Sender: TObject);
begin
// SendMsg (CM_ECHO);
end;

procedure TMForm.TerminationStart;
begin
 try
  LogStrEx ('#NOTIFY: Termination startups', 10);
  FastTimer.Enabled := FALSE;
  SendMsg (CM_UNLOAD);
  sleep (100); // passive client mode
  SetPriorityClass (GetCurrentProcess, NORMAL_PRIORITY_CLASS);
  SetThreadPriority (GetCurrentThread, THREAD_PRIORITY_NORMAL);
  gbAppTerminate := true;
  inputBreak := true;
  UIT.Enabled := false;
  frmOptions.SaveCfg;
  ffbreak := True;
  client.Disconnect;
  Hide;
  PostQuitMessage (0); // forcing exitting
 except
  On EAccessViolation do
    LogStrEx ('#ERROR: While termination progress, causing exception', 12);
 end;
end;

procedure TMForm.miExitClick(Sender: TObject);
begin
 TerminationStart;
end; // miExitClick

procedure TMForm.miTh32Click(Sender: TObject);
begin
 miTh32.Checked := True;
 miUser32.Checked := false;
 Uit.enabled := true;
end; // miTh32Click

procedure TMForm.miUser32Click(Sender: TObject);
begin
 miUser32.Checked := True;
 miTh32.Checked := false;
 Uit.enabled := true;
end; // miUser32Click

procedure TMForm.pctrlChange(Sender: TObject);
begin
 if bPSCanSelect then OpenThisProcess;
end; // pctrlChange

procedure TMForm.lvPSlistDblClick(Sender: TObject);
begin
 if bPSCanSelect then OpenThisProcess;
end; // lvPSlist double click

procedure TMForm.OpenThisProcess;

begin
 Uit.Enabled := pctrl.ActivePageIndex = 0; // запрещать таймер
 // if FirstLoad then else csm.prcs.pid := GetCurrentProcessId;
 if csm.prcs.pid = 0 then pctrl.ActivePageIndex := 0
 else
 if csm.svars.AliasedPID <> csm.prcs.pid then
  begin
   SendMsgEx (CM_PSOPEN, csm.prcs.pid);
  end;
end;

procedure TMForm.OnAcquireMutex (index: Integer);
begin
 if index = vlist.iMutex then
    vlist.MutexState := 1;
end;

procedure TMForm.OnReleaseMutex (index: Integer);
begin
 if index = vlist.iMutex then
    vlist.MutexState := -1;
end;

procedure TMForm.OnOpenMutex;
begin
 // Запоминание номеров сетевых мьютексов
 if StrComp (pszName, swtMutex) = 0 then
    vlist.iMutex := Index;
end;

procedure TMForm.OnSyncMessage;
begin
 if lp = ClientId then
 case msgid of
   NM_MUTEXACQUIRED: OnAcquireMutex (wp);
   NM_MUTEXRELEASED: OnReleaseMutex (wp);
 end;
end;

procedure TMForm.OnOpenProcess (const p: TBasePacket);
var pid: DWORD;
begin
 _alias := p.data0;
 pid := p.data1;
 if client.localMode and (pid <> 0) then
 // Локальное открытие описателя процесса
      _alias := OpenProcess (PROCESS_ALL_ACCESS, FALSE, pid);

 // Обработка ошибки открытия
 if _alias = 0 then
    begin
     csm.SVars.aliased := false;
     AddMsg ('OpenProcess Error : ' + err2str (p.data0));
     AddMsg ('Возможно процесс запущен от другого пользователя. Не хватает прав доступа.');
     exit;
    end;

 if Assigned (dsrc) and (dsrc is TProcessSrc) then
             (dsrc as TProcessSrc).hProcess := _alias;
 csm.svars.alias := _alias;
 csm.svars.aliasedPID := pid;
 csm.SVars.aliased := true;
 sbar.Panels [0].Text := '';
 sbar.Panels [1].Text := '';
 lbProcess.Caption := csm.prcs.title;
 mmsUpdated := TRUE;
 PaintBusy;

 try
  AddMsg (Format (LocStr ('%AliasCreated%'),
             [csm.prcs.pid, csm.SVars.alias]));
 except
    on EConvertError do
        AddMsg ('Translation string has wrong params: ' +LocStr ('%AliasCreated%'));
 end;
 AddMsg (LocStr ('%MapCreatingMsg%')); //
 fmapx := false;
 OnAliasing (true);
 //ListModules;
 //ListThreads;
 if pctrl.ActivePageIndex = 1 then csm.WDelay := 10
                              else csm.WDelay := 100;
 if (csm.svars.aliased) then
     pctrl.ActivePageIndex := 1;

end;

procedure TMForm.OnProcessClosed;
begin
 OnAliasing (false);
 AddMsg(Format (LocStr ('%AliasKilled%'), [pointer (csm.prcs.pid)]));
 if client.localMode then CloseHandle (_alias);
 _alias := 0;
 if Assigned (dsrc) and (dsrc is TProcessSrc) then
             (dsrc as TProcessSrc).hProcess := 0;
 lbProcess.caption := LocStr ('%ProcessNotSelected%');
end;

procedure TMForm.OnPSListAddComplete;
begin // Обработка получения списка процессов
 // Проверка на готовность интерфейса
 if not bInterfaceReady then ShowInterface;
 if not lvPSlist.Visible then
   begin
    lvPSlist.Visible := true;
    if lvPSlist.Enabled then lvPSlist.SetFocus;
   end;
 Inc (psrcount);
 // Автоматический выбор игры из списка
 if (cbAutoselect.Checked) and (psrcount = 1) then
  begin
   if (wplist.ItemsCount > 0) then
   with wplist do
   if  (witems [0].game >= 200) and (lvPSlist.Items.Count > 0) then
    begin
     lvPSlist.Items [0].Selected := true;
     lvPSlistDblClick (self);
    end;
  end else wplist.Update; // обновление окна
end;

procedure TMForm.CopyPSListCache;
begin
 lvPSlist.Items.BeginUpdate;
 IconList.Assign (IconList2);
 lvPSlist.Items.Assign(plvx_cache.Items);
  with sform.lvApps do
  begin
   items.BeginUpdate;
   items.Assign (plvx_cache.Items);
   items.EndUpdate;
  end;
 lvPSlist.Items.EndUpdate;
 bPSCanSelect := TRUE;
end;

procedure TMForm.OnScanComplete;
var
       n: DWORD;
  ffound: boolean;
       s: string;
begin
 csm.fComplete := false;
 FastTimer.Interval := pWgcSettings.nTimerInt;
 SetSpyPrior (THREAD_PRIORITY_IDLE);
 gProgress.visible := false;
 UpdateRqsList;
 ListFound (csm.CurrRqs);
 UpdateProgress;
 s := csm.svars.ScanType;
 if (fcons) then
     con.SetLast (' Завершено: 100%'); // Что бы без обмана
 Addmsg (Format (LocStr ('%Process_Complete%'), [s]));
 { if csm.error <> '' then addmsg (
    Format (LocStr ('%ScanError%'), [s, csm.error]));{}
 // Обработка времменых данных
 lbFoundCount.Caption := IntToStr (csm.FoundAll);
 sform.onComplete;
 ffound := false;
 for n := 1 to MaxRqs do
 begin
  ffound := ffound or (csm.svars.fnds [n].foundCount > 0);
  csm.RqsLst [n].PlgAssigned := false;
 end;
 sbar.panels [1].Text := '';
 if (fBusy) then PaintReady;
 csm.fScanmode := false;
 if (fcons) then con.Hide (500);
 gProgress.Hide;
 if (csm.fPlgDisp) then SendMsg (CM_DISPPG); // Вернуть окно плагина
end; // if complete

procedure TMForm.OnScanProgress;
begin
  if (not fBusy) then
  if not gProgress.Visible then
   begin
    gProgress.show;
    PaintBusy;
   end;
 csm.svars.scanAll := scanCount;  
 if fBusy then UpdateProgress;
 //sbar.panels [1].Text := 'Прошло времени: ' + SysTime2Str (csm.timers [9]);
end;

procedure TMForm.OnGameTerminated;
begin
 // Проверка исследуемого процесса, вдруг рухнул
 if fbusy then PaintReady;
 csm.svars.aliased := false;
 AddMsg ('Процесс ' + csm.prcs.title + ' был завершен');
 lbProcess.Caption := csm.prcs.title + ' [завершен]';
end;

procedure TMForm.ShowInterface;
begin
 // отображение главной формы
 if pWgcSettings.bSimpleView then
    miSimpleClick (self) // show small form
 else show; // show self
 frmSplash.Hide;
 bInterfaceReady := TRUE;
end; //

procedure TMForm.ShowScanResults (const inf: PScanProcessInfo);
var secs, speed: Double;
    tm, s: String;
begin
 if not Assigned (inf) then exit;
 secs := inf.scanTime + 0.02;
 s := csm.svars.ScanType;
 csm.svars.scanAll := inf.scanCount;
 csm.svars.readAll := inf.scanCount;
 if (secs < 0.5) then             
     tm := FormatFloat ('0.000', secs)
 else
     tm := FormatFloat ('0.00', secs);
 if secs > 0 then
    speed := (inf.scanCount) / secs else speed := 0;
 AddMsg (
    Format (LocStr ('%TimeOfProcess%'), [s, tm, msdiv (speed)]));
 // Добавление в диалог информации
 scpdlg.OnComplete (msdiv (speed), tm, msdiv (inf.scanCount) );
 AddMsg (
    Format (LocStr ('%FoundValues%'), [inf.foundVals]));
end;

procedure TMForm.lvPSlistClick (Sender: TObject);
var
   n, indx: Integer;
   pid: DWORD;
begin
 Uit.Enabled := FALSE;
 indx := lvPSlist.ItemIndex;
 // В указателе data хранится дескриптор процесса
 if (indx >= 0) then pid := DWORD (lvPSlist.Items [indx].Data) else exit;
 if pid = 0 then exit;
 n := wplist.FindProcess (pid, 0);
 if n < 0 then exit;
 // what must be selected
 csm.prcs := wplist.witems [n];
 if (n >= 0) and (csm.prcs.pid <> 0) and fClick then
      lvPSlistDblClick (self);
 if cb_shwnd.Checked then
      ed_hwnd.Text :=  '$' + DWORD2HEX (csm.prcs.hwnd);  
 Uit.Enabled := TRUE;
end; // selecting process without open it

procedure TMForm.lvPSlistKeyPress;
begin
 if (key = #13) and (lvPSlist.itemIndex >= 0) then lvPSlistDblClick (sender);
end; // plvxKeyPress


procedure TMform.ReceiveScanResults (prec: PFoundRec);
begin
 if not Assigned (prec) then exit;
 with csm do
  Move (prec^, svars.fnds [prec.rqsn], sizeof (TFoundRec));
end;

type
    ist = record
     speed : extended;
      time : extended;
    end;

var
   lastAll : DWORD;
   lastTks : int64;





procedure TMForm.ListChCodes;
var n: DWORD;
begin
 if Assigned (fcodes) then 
  with fcodes.CodesMemo do
    begin
     for n := 1 to Lines.Count do
      if (Lines [n] <> '') then con.WriteText (Lines [n]);
    end;
end; // ListCheats

var
      chmode: DWORD;

     fattach: boolean = false;
        nwnd: THandle = 0;
     fwindow: boolean = false;
          dc: HDC = 0;
         rgn: HRGN = 0;




procedure TMForm.FastTimerTimer(Sender: TObject);





procedure      HandleKeyboard ();

begin
 { Мучение клавиатуры }
 if HotKeyPress (hkToGame) then btnGameClick (self);
 // Продолжение в отладке
 // if HotKeyPress (hkRunProcess) and Waiting then RunProcess (true);
 if HotKeyPress (hkPopupApp) then
  begin
   Snapshot (false);
   PopupApp; // Функция всплытия подводной лодки
   if pWgcSettings.bResRestore then frmOptions.btnResTestClick (self);
  end; // Всплытие программы
 if HotKeyPress (hkScanStart) and not csm.fScanmode then
  begin
   // Если не выбрана консоль - прямой запуск сканирования
   if fcons then
    begin
     ParseCmd (con.HandleInput (1)); // scan
     rqsUpdated := TRUE;
    end;
   if fnone then con.hide else btnScanClick (self); // Поиск значения (с блокировкой)
   con.WriteText ('');
  end;
 if HotKeyPress (hkSieveStart) and not csm.fScanmode then
  begin
   // Если не выбрана консоль - прямой запуск отсева
   if fcons then
    begin
     ParseCmd (con.HandleInput (2)); // sieve
     rqsUpdated := TRUE;
    end;
   if fnone then con.hide else btnSieveClick (self); // Отсев значений (с блокировкой)
   con.WriteText (''); // for erasing
  end;
 if (HotKeyPress (hkShowCons)) then
   begin // Показ консоли в режиме ввода команд
    con.HandleInput (3);
    con.Hide;
   end;

 // if HotKeyPress (hkFreeze) then SuspendThread (ThrdArray [1].h);
 // if HotKeyPress (hkUnFreeze) then ResumeThread (ThrdArray [1].h);
 if HotKeyPress (hkBreakScan) then
   begin
    csm.svars.fbreak := true; // ctrl-break - прерывание
    csm.fcomplete := true;
   end;
 // Копирование в файл копии экрана
 if HotKeyPress (hkPrintScrn) then Snapshot else
 if (IsPressed (VK_SNAPSHOT)) then Snapshot (false); // просто скопировать в буффер
 if csm.wgcActive then
  begin
   if HotKeyPress (hkPrevTab) then SelectPrevTab (self);
   if HotKeyPress (hkNextTab) then SelectNextTab (self);
    if (IsPressed (VK_F4) and (GetActiveWindow = Handle)) and (visible) and
       (pctrl.ActivePageIndex = 1) then
    begin
     if (gLastKey.flags = KF_SHIFT) then ed_maxex.SetFocus
                          else ed_minex.SetFocus;
     end;
  end;
 // Режим вставки чит кода
 if (HotKeyPress (hkSendChCode)) then
     chmode := chmode or $10; // Установка флажка режима "чит-код"
 // Вывод чит-кодов в окно сообщений
 if (HotKeyPress (hkPrintCodes)) then
     ListChCodes;
 // Если в чит-режиме
 if (chmode and $10 > 0) then
   if fcodes.SendCheatByHotKey then chmode := 0; // Выключение режима после вывода чит-кода
end;   // HandleKeyboard

var s : string;

procedure    FillState;
begin
 with mstate do
  begin
   while (Lines.Count < 12) do Lines.Add(' ');
   s := 'Count of copys ' + mainLib + ':        ' + IntToStr (csm.CopyNum);
   if (Lines [0] <> s) then Lines [0] := s;
   csm.memInfo;
   s := 'Used memory:                    ' +  msdiv (csm.AllCommit);
   if (Lines [1] <> s) then Lines [1] := s;
   s := 'Main buffer size:                ' + msdiv (pWgcSettings.buffSize);
   if (Lines [2] <> s) then Lines [2] := s;
   {$IFOPT D+}
   s := 'Gdi Resources used:              ' +
                IntToStr (GetGuiResources (GetCurrentProcess, GR_GDIOBJECTS));
   if (Lines [3] <> s) then Lines [3] := s;
   s := 'User Resources used:             ' +
                IntToStr (GetGuiResources (GetCurrentProcess, GR_USEROBJECTS));
   if (Lines [4] <> s) then Lines [4] := s;
   {$ENDIF}
  end;
end;

procedure OnFastTimer;
{ [[[[[[[[[[[[[ OnTIMER ]]]]]]]]]]]]]]]] =============}
var
    ready : Boolean;
    fwnd: HWND;
    nPID: DWORD;
    msg: TMessage;
begin
 msg.WParam := 0;

 if (iticks and 7 = 0) then
   begin
    psArray.Update; // обновить если что добавилось
    // if (wgc_copy > 1) then PopupApp (false);
    // обработка тихого подключения
    if not client.prvConState and CheckConReady then
     begin
      client.prvConState := TRUE;
      client.OnConnect (IPCIdent, 0);
     end;
    // if rqsUpdated then SendRqsList; -- only on scan event
    if mmsUpdated then SendMapRescan;
   end;
 if (visible and pWgcSettings.bSimpleView) then miSimpleClick (self);
 // обработка разрыва сетевого соединения
 client.CheckConnection;
 fwnd := GetForegroundWindow;
 GetWindowThreadProcessId (fwnd, nPID);
 csm.wgcActive := (nPID = nSelfPID);
 factive := csm.wgcActive;
 if (height < 510) and factive then height := 570; // Восстановление размера
 If (csm = nil) then exit;       // Обработка пока не возможна
 ready := (csm.copyNum > 0) or (client.bConnectionStable);
 imGameView.Visible := (ssht <> nil);
 // TODO: Требуется пересоединение
 FillState;
 if (csm.CurrRqs <> RqsList.ItemIndex + 1) then RqsList.ItemIndex := csm.CurrRqs - 1;
 ready := ready and csm.svars.aliased;
 btnScan.Enabled := ready;
 btnSieve.Enabled := ready;
 if csm.wgcActive then csm.daWait := 5 else csm.daWait := 500;
 if (csm.svars.aliased) then  // Есть захваченный процесс
 with pWgcSettings^ do
 Begin
  wtUpdated := wtUpdated or frmAddrs.bCellsChanged;
  frmAddrs.bCellsChanged := FALSE;
  if wtUpdated then
   begin
    vlist.LoadFromTable(sgt, TRUE);
    vlist.SendList;
   end;
  // проверка на возможность вывода консоли
  fcons :=  (bShowCons and not csm.wgcActive);
  UpdateRqsList;
 end;
 gLastKey.pack := 0;
 if Assigned (gKbdInput) then
  while gKbdInput.ReadKey(gLastKey) do
   begin
    if (gLastKey.flags and KF_PRESS <> 0) and
       (not frmOptions.edHotKey.focused) then
        HandleKeyboard (); // Обработка клавы
   end;
 // afx
end;


Begin // timer
 FastTimer.Enabled := FALSE;
 Enabled := TRUE;
 {SendMsg (CM_ECHO);}
 inc (iTicks);
 // startup checking
 if iTicks < 100 then
  begin
   if visible and not bInterfaceReady then Hide;
  end;
 try
  Client.OnTimer ();
  OnFastTimer;
 finally
  FastTimer.Enabled := TRUE;
 end;
end; // OnTimer TCT



procedure TMForm.miAboutClick(Sender: TObject);
begin
 ChAbout.AboutBox.ShowModal;
end;

procedure TMForm.cb_textClick(Sender: TObject);
var n : byte;
begin
 if (sender is TCheckBox) then
 for n := 1 to High (segsel) do
  if segnames [n] = (sender as TCheckBox).Caption then
     segsel [n] := (sender as TCheckBox).Checked;
end;


procedure TMForm.btnSetRuleClick(Sender: TObject);
var s : string;
begin
 s := '';
 if (sender is TButton) then
     s := (sender as TButton).caption;
 if (sender is TMenuItem) then
     s := (sender as TMenuItem).Caption;
 if (s = '++') then s := '+';
 if (s = '--') then s := '-';
 if (s <> '') then btnRule.Caption := s;
 SaveRqs;
 rqsUpdated := TRUE;
end;

procedure TMForm.cb_rqs1Click(Sender: TObject);
var s : string;
    e, i : integer;
begin
 btnScan.Font.Style := [];
 btnSieve.Font.Style := [];
 if (sender is TCheckBox) then else exit;
 s := (sender as tCheckBox).caption;
 Val (s, i, e);
 if (e = 0) and (i >= 1) and (i <= MaxRqs) then
     csm.RqsLst [i].enabled := (sender as TCheckBox).Checked;
end;

procedure TMForm.SendMapRescan;
begin // обновление информации о диапазоне сканирования
 // if csm.svars.aliased then else exit;
 LogStr (Format ('Setting scan range from $%x to $%x',
                [pscparams.startofs, pscparams.limitofs]));
 SendMsgEx (CM_UPDMAP, pscparams.startofs, pscparams.limitofs);
 SendMsg (CM_LDATA);
 SendDataEx (sSCANPARAMS, @csm.svars.params, sizeof (TScanProcessParam));
 mmsUpdated := FALSE;
end;

procedure TMForm.SetScanRange;
var e: Integer;
begin
 with csm.svars.params do
 begin
  val (ed_gBase.text, pscparams.startofs, e);
  val (ed_gLimit.text, pscparams.limitofs, e);
 end;
 mmsUpdated := TRUE;
end;

{ Form.SearchValues
   Назначение инициализация таймеров и переменных поиска.
   Посылка команды удаленному запросу на поиск. }
procedure TMForm.SearchValues (const s : string);

begin
 InputBreak := true;
 FastTimer.Interval := 200;
 gProgress.Progress := 0;
 csm.svars.readAll := 0;
 // csm.error := '';
 lastAll := csm.svars.params.startofs;
 lastTks := GetTickCount;
 if mmsUpdated then SetScanRange;
 if rqsUpdated then SendRqsList;
 if (not visible) then
   begin
    scpdlg.prcsn := s;
    scpdlg.Show;
   end;
 StartCounter (1); // Аппаратный счетчик тактов CPU
 AddMsg (format (LocStr ('%Process_Start%'), [s]));
 //PrcsMsgs;            // Очистка сообщений
 SendMsg (CM_SEARCH); // Посылка сообщения "Поиск"
 csm.svars.scanAll := 0;
 SetSpyPrior (csm.svars.Priority);
 StrPCopy (csm.svars.ScanType, s);
 csm.fComplete := false;
 csm.fScanmode := true;
 sbar.panels [1].Text := '';
end; // SearchValues


procedure TMForm.btnScanClick(Sender: TObject);
var n : byte;

begin
 if csm = nil then exit;
 if csm.fScanmode then exit;
 SaveRqs;
 btnScan.Font.Style := [];
 csm.SVars.fbreak := false;
 for n := 1 to MaxRqs do
  with csm.RqsLst [n] do
  if Enabled then
   begin
    if unknow then sactn := _copy
              else sactn := _scan;
   end;
 rqsUpdated := TRUE;
 LogStrEx ('Начало сканирования.', 14);
 SearchValues (LocStr ('%FirstScan%'));
 btnSieve.Font.Style := [fsBold];
end;

procedure TMForm.BtnSieveClick(Sender: TObject);
var
   n : byte;
   w : DWORD;
begin
 if csm = nil then exit;
 if csm.fScanmode then exit;
 SaveRqs;
 for n := 1 to MaxRqs do
 with csm.RqsLst [n] do
  if enabled then
   begin
    sactn := _sieve;
    if unknow and csm.svars.fnds [n].unk then // Unk = true after copy
       sactn := _scan;
   end;
 rqsUpdated := TRUE;
 SearchValues (LocStr ('%NextScan%'));
 for n := 1 to MaxRqs do
 with csm.RqsLst [n] do
  if enabled then
   begin
    if unknow and csm.svars.fnds [n].unk then // Unk = true after copy
       csm.svars.fnds [n].unk := false;
   end;
 w := 0;
 if (w = 0) then  btnSieve.Font.Style := [];
end;


procedure  TMForm.AddOrSub;
var i, i2 : Int64;
    v : extended;
    d : Int64;
    e : Integer; // Вещественные значение не поддерживаются
begin
 val (delta.Text, i, e);;
 repeat
  e := pos (',', s);
  if e = 0 then break;
  s [e] := '.';
 until false;
 if (pos ('$', s) = 1) then
  begin
   val (s, d, e);
   v := d * 1.0;
  end
 else
  val (s, v, e);
 if e = 0 then
  begin
   v := v + 1.0 * dx * i * mul;
   i2 := round (v);
   if Frac (v) = 0 then s := IntToStr (i2) else
                        s := formatFloat('0.000', v);
  end;
end; // proc AddOrSub

function  TMForm.AddOrSubEx;
var s: string;
    hex: boolean;
    v: Int64;
    e: Integer;
begin
 result := c;
 if (c = '') then exit;
 s := UniHex (c);
 hex := (pos ('$', s) = 1);
 AddOrSub (s, dx, mul);
 result := s;
 if (hex) then
   begin
    val (s, v, e);
    result := format ('$%x', [v]);
   end;
end; // AddOrSubEx


procedure TMForm.btnIncSvClick(Sender: TObject);

begin
 exmin := addOrSubEx (exmin, 1, 1);
 exmax := addOrSubEx (exmax, 1, 1);
 SyncRqs;
 rqsUpdated := TRUE;
end; // incSv

procedure TMForm.BtnDecSvClick(Sender: TObject);
begin
 exmin := addOrSubEx (exmin, -1, 1);
 exmax := addOrSubEx (exmax, -1, 1);
 SyncRqs;
 rqsUpdated := TRUE;
end;

procedure TMForm.sb_upClick(Sender: TObject);
begin
 SaveRqs;
 rqsUpdated := TRUE;
 if csm.CurrRqs > 1 then Dec (csm.CurrRqs);
 LoadRqs;
 ListFound (csm.CurrRqs);
 RqsList.ItemIndex := csm.CurrRqs - 1;
end;

procedure TMForm.sb_downClick(Sender: TObject);
begin
 SaveRqs;
 rqsUpdated := TRUE;
 if csm.CurrRqs < MaxRqs then Inc (csm.CurrRqs);
 LoadRqs;
 ListFound (csm.CurrRqs);
 RqsList.ItemIndex := csm.CurrRqs - 1;
end;

function StrToDig (s : string) : DWORD;
var n : byte;
    d : string;
    e : integer;
begin
 d := '';
 for n := 1 to Length (s) do
  if s [n] in ['0'..'9'] then d := d + s [n];
 Val (d, result, e);
end; // StrToDig

procedure TMForm.OnUpdate(Sender: TObject);
begin
 SaveRqs;
 rqsUpdated := TRUE;
end;

procedure TMForm.sgCheatKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if (shift = [ssSHIFT]) and (key = VK_DELETE) then
  begin
   vlist.Delete(sgt.Row);
   ReListAddrs;
  end;
end; // Handler of SHIFT+DEL combination

procedure TMForm.btnHideClick(Sender: TObject);
var h : THandle;
begin
 h := S2I (ed_hwnd.text);
 if h <> 0 then ShowWindowAsync (h, SW_HIDE);
end;

procedure TMForm.btnRestoreClick(Sender: TObject);
var h : THandle;
begin
 h := S2I (ed_hwnd.text);
 if h <> 0 then ShowWindowAsync (h, SW_RESTORE);
end;

procedure TMForm.cb_ooneClick(Sender: TObject);
begin
 if cb_oone.checked then
  wplist.maskPID := csm.prcs.pid
 else wplist.maskPID := 0;
 UpdateProcessList;
end;

procedure TMForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
 if FastTimer.Enabled then TerminationStart;
 uit.Enabled := false;
 FastTimer.Enabled := false;
 sleep (10);
 // btnUnloadSpyClick (self);
 AppExit := true;
end;

procedure TMForm.BtnSppRestClick(Sender: TObject);
begin
 SendMsg (CM_WRST);
end;

procedure TMForm.BtnSppMClick(Sender: TObject);
var h : THandle;
begin
 h := csm.prcs.hwnd;
 ShowWindowAsync (h, SW_MINIMIZE);
end;

procedure TMForm.btnWinClick(Sender: TObject);
begin
 PopupApp;
end; // btnWinClick

procedure TMForm.PopupApp;
var tid, pid, stid: THandle;
     hwnd: THandle;

begin
 // FormStyle := fsStayOnTop;
 if (csm <> nil) and (mgame) then
        ShowWindow (csm.prcs.hwnd, SW_MINIMIZE);
 // miAlwaysOnTop.checked := true;
 // Узнать текущее окошко
 hwnd := GetForegroundWindow;
 if hwnd = handle then exit; // нечего себя убирать
 // Узнать активный Поток
 AddMsg (format ('Всплытие подлодки: From = %x, To = %x', [hwnd, handle]));
 tid := GetWindowThreadProcessId (hwnd, pid);
 stid := GetWindowThreadProcessId (Handle, pid);
 // Получить у процесса фокус ввода
 AttachThreadInput (tid, stid, true);
 // Вывести окно на поверхность
 ShowWindowAsync (handle, SW_RESTORE);
 ForceForegroundWindow (handle);
 // SetForegroundWindow (handle);
 SetActiveWindow (handle);
 ShowWindowAsync (handle, SW_SHOWDEFAULT);
 AttachThreadInput (tid, stid, false);
end;

procedure TMForm.miTerminateClick(Sender: TObject);
begin
 if (csm.SVars.alias <> 0) and
  (MessageBox (handle,
    'Сэр! Это же "мокруха". Вы хотите просто так убить процесс',
    'Убийство процесса', MB_YESNO) = IDYES)  then
    begin
     btnUnloadSpyClick (self);
     SendMsg (CM_PSKILL);
    end; 
end;

procedure TMForm.btnUnloadSpyClick(Sender: TObject);
var
   hdll: THandle;
      n: DWORD;
begin
 if (csm <> nil) and (csm.SpyVars.fSpyMode) then
  begin
  try
   while (csm.CopyNum > 0) do KillLibs;
   if (csm.CopyNum = 0) then
        AddMsg ('Все копии CHDIP.DLL выгружены');
   csm.SpyVars.fSpyMode := false;
   csm.SpyVars.fSIS := false;
   csm.CopyNum := 0; // Нет дополнительных копий
   hdll := GetModuleHandle ('CHDIP.DLL');
   if (hdll <> 0) then FreeLibrary (hdll);
   // Повторная загрузка DLL
   if LoadLibrary ('CHDIP.DLL') <> 0 then
       AddMsg ('Основная копия CHDIP.DLL перезагружена'); // Подождать загрузки

   n := csm.ActiveClient;
   hSpyTHRD := csm.clients [n].hThread;
  except
   on E:Exception do;
  end;// try
  end;
end; // UnloadSpyClick

procedure TMForm.rqs1Click(Sender: TObject);
var v : word;
    e : integer;
begin
 if (sender is TButton) then
  begin
   val ((sender as TButton).Caption, v, e);
   if e = 0 then
    begin
     if v in [1..MaxRqs] then
      begin
       SaveRqs;
       rqsUpdated := TRUE;
       csm.CurrRqs := v;
       LoadRqs;
       ListFound (csm.CurrRqs);
      end;
     UpdateRqsList;
     btnScan.SetFocus;
    end; // Converter
  end;
end;



procedure TMForm.rqs1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  // Активация и деактивация запросов
var v : word;
    e : integer;

begin
 if (sender is TButton) and (Button = mbRight)  then // По правой кнопке
  begin
   val ((sender as TButton).Caption, v, e);
   if (e = 0) and (v in [1..MaxRqs]) then
    begin
     csm.RqsLst [v].enabled := not csm.RqsLst [v].enabled;
     if v = csm.CurrRqs then
        with cb_enabled do checked := csm.RqsLst [v].enabled;
    end;
   UpdateRqsList;
   btnScan.SetFocus;
  end;
end;

procedure TMForm.ed_gLimitExit(Sender: TObject);
var s : string;
begin
 if sender is TEdit then else exit;
 s := (sender as TEdit).text;
 if length (s) > 9 then s := copy (s, 1, 9);
 (sender as TEdit).text := s;
 SetScanRange;
end;

function  InRect (const p : TPoint; const r : TRect) : boolean;
 begin
  result := InRange (p.X, r.Left, r.Right) and
            InRange (p.y, r.Top, r.Bottom);
 end; // InRect

function TextVal (const v : Extended) : string;
var x : Extended;
    s : string;
    i : byte;
begin
 result := '';
 x := v;
 s := '';
 i := 0;
 if (abs (x) >= 10000) then
 while (abs (x) > 1000) do
  begin
   x := x / 1000;
   inc (i)
  end;
 str (x:3:3, result);
 case i of
  1 : s := ' тыс.';
  2 : s := ' млн.';
  3 : s := ' млрд.';
  4 : s := ' трилл.';
  5 : s := ' квадрл.';
  6 : s := ' квинтл.';
  7..255 : s := ' E' + IntToStr (i * 3);
 end;
 result := result + s;
end; // TextVal

var cctrl : string;

procedure TMForm.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  var s : string;
      mul : int64;
       wc : TComponent;
      h: HWND;
begin
 handled := false;
 s := cctrl;
 h := WindowFromPoint (mousePos);
 if h = ed_minex.handle then s := 'ed_minex';
 if h = ed_maxex.handle then s := 'ed_maxex';
 if h = sform.edexmin.Handle then s := 'edexmin';
 if h = delta.handle then s := 'delta';
 if h =  multp.handle then s := 'delta';
 mul := 1;
 if ssLeft in shift then mul := mul * 10;
 if ssCtrl in shift then mul := mul * 10;
  begin
   if (s = 'ed_maxex') or
      (s = 'ed_minex') or
      (s = 'delta') or
      (s = 'edexmin') then
    begin
     wc := mform.FindComponent(s);
     if (wc = nil) then wc := sform.FindComponent(s);
     if (wc <> nil) then
     if (wc is TEdit) then
      with (wc as TEdit) do
       begin
        if (WheelDelta > 0) then text := AddOrSubEx (text, 1, mul);
        if (WheelDelta < 0) then text := AddOrSubEx (text, -1, mul);
       end
     else
      if (wc is TSpinEdit) and (wheelDelta <> 0) then
       with (wc as TSpinEdit) do Value := Value + (mul * WheelDelta div abs (WheelDelta));
     handled := true;
    end;
  end;
end;


procedure TMForm.ed_minexMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
 cctrl := (sender as TWinControl).Name;
end;

procedure TMForm.miHookClick(Sender: TObject);
var n: DWORD;
begin
 n := pctrl.ActivePageIndex;
 cbPrefetch.visible := true; // показать для управления предвыборкой
 cbPrefetch.Checked := true;
 pWgcSettings.bPrefetch := true;
 pctrl.ActivePageIndex := n;
 // if (csm.svars.aliased and not csm.SpyVars.fSpyMode) then InfiltrateHook;
end;

procedure TMForm.miMsgsClick(Sender: TObject);
begin
 span.Width := width - 7;
 span.Visible := not span.Visible;
 fMessages.Visible := span.Visible;
 miMsgs.Checked := span.Visible;
end;

procedure TMForm.cbPriorityChange(Sender: TObject);
begin
end; // Изменение приоритета поиска

procedure TMForm.miLocalizeClick(Sender: TObject);
begin
 OpenDlg.Filter := 'Text files|*.txt';
 if OpenDlg.Execute then Localize (OpenDlg.FileName)
  else lclFile := 'none';
end; // Локализация программы

procedure TMForm.FormDestroy(Sender: TObject);
var ticks: DWORD;
begin
 try
  gbAppTerminate := true;
  gKbdInput.Free;
  killThreads := true;
  inputBreak := true;
  bmp.Free;
  iconList.Clear;
  con.Free;
  ticks := GetTickCount;
  while (csm.CopyNum > 0) and (GetTickCount - ticks < 500) do
   begin
    KillLibs;
    Sleep (50);
    end;
   //CloseShareMem;
   csm := nil;
   alltxt.free;
 except
  ods ('OnDestroy - has exception!');
 end;
 LogStrEx ('#NOTIFY: MainForm destroying passed.', 10);
end; // FormDestroy


procedure TMForm.btnFindClick(Sender: TObject);
var h : THandle;
    p : DWORD;
    s : WSTRZ256;
    fload : boolean;
begin
 StrPCopy (s, edLib.text);
 h := GetModuleHandle (s);
 fload := (h = 0);
 if fload then h := LoadLibrary (s);
 if h = 0 then
  begin
   ShowMessage ('Sorry, Не удается загрузить ' + edLib.text);
   exit;
  end;
 StrPCopy (s, edProc.Text);
 p := DWORD (GetProcAddress (h, s));
 if p = 0 then
  begin
   ShowMessage ('Функция не найдена');
   exit;
  end;
 edResultPtr.Text := '$' + dword2hex (p);
 AddMsg ('Library: ' + edLib.text +
         ' HINSTANCE = $' + dword2hex (h) +
         ' Func/proc: ' + edProc.text +
         ' Address = $' + dword2hex (p));
 if fload then FreeLibrary (h);
end;

procedure TMForm.miAlwaysOnTopClick(Sender: TObject);
begin
 with miAlwaysOnTop do Checked := not Checked;
 if miAlwaysOnTop.checked then formStyle := fsStayOnTop
                          else formStyle := fsNormal;
end;

procedure TMForm.btnSavRsltsClick(Sender: TObject);
begin
 SendMsg (CM_SAVERES);
end;

procedure TMForm.BtnLoadRsltsClick(Sender: TObject);
var timeOut : DWORD;
begin
 btnLoadRslts.Enabled := false;
 csm.fFileLoad := false;
 SendMsg (CM_LOADRES);
 timeOut := 50;
 while (not csm.fFileLoad) do
  begin
   Application.ProcessMessages;
   sleep (100);
   if timeout = 0 then break else dec (timeOut);
  end;
 ListFound (csm.CurrRqs);
 btnLoadRslts.Enabled := true;
end;



procedure TMForm.btnCodesClick(Sender: TObject);
begin
 if nil = fcodes then fcodes := TFCodes.Create (self);
 fcodes.show;
end;


var ccmd : String = '';

procedure TMForm.ListTable;
// Вывод таблицы указателей
var
   y: DWORD;
   s: string;
begin
 // Заполнение таблицы
 RelistAddrs;
 // with frmAddrs  do
 for y := 1 to sgt.RowCount - 1 do
 if (sgt.cells [2, y] <> '') then
  begin
   s := IntToStr (y) + '. ';
   s := s + sgt.Cells [1, y] + ' at [';

   s := s + sgt.Cells [2, y] + '] = ';
   s := s + sgt.Cells [3, y];
   con.WriteText (s);
  end;
end; // ListTable

procedure TMForm.ParseCmd;
{ Производится анализ строки }
var
   srv: TStrSrv;
   tt, rr, mn, mx: string; // type, request, min, max
   ss, us: string;
begin
 srv := TStrSrv.Create;
 csm.CurrRqs := 1;
 tt := btnType.Caption;
 rr := btnRule.Caption;
 mn := exmin;
 mx := exmax;
 fnone := (s = '') or (s = 'close');
 if fnone then exit; // нечего анализировать
 ss := s;
 if (not TestDigits (s)) then ss := exmin + ' ' + ss;
 // Модификация текущего запроса
 srv.Assign(ss);
 repeat
  ss := srv.ReadSub;
  us := lowerCase (ss);
  // Если кончилась строка
  if ss = '' then break;
  // Установка типа
  if IsType (ss, tt) then else // Изменился тип
  // Установка правила поиска
  if IsRule (ss, rr) then else // Изменилось условие
  if (ss <> '') then mn := ss; // Образец
 until ss = '';
 exmin := mn;
 exmax := mx;
 btnType.Caption := tt;
 btnRule.Caption := rr;
 SyncRqs;
 SaveRqs;
 rqsUpdated := TRUE;
 LoadRqs;
 Invalidate;
 Application.ProcessMessages;
{ btnType.Repaint;
 btnRule.Repaint;
 ed_min.Repaint;
 ed_max.Repaint; {}
end;


procedure TMForm.miHelpClick(Sender: TObject);
begin
 if (nil = HelpForm) then HelpForm := THelpForm.Create(self);
 HelpForm.Show;
end;

procedure TMForm.miPluginClick(Sender: TObject);
var
   plg, dlg : integer;
   mi : TMenuItem;
begin
 if (sender is TMenuItem) then
  begin
   mi := sender as TMenuItem;
   dlg := GetIndex (mi, plg);
   if (dlg >= 0) and (plg >= 0) then
    begin
     csm.plgNum := plg + 1;
     csm.dlgNum := dlg;
     SendMsg (CM_DISPPG);
     Deactivate;
    end
   else
   ShowMessage ('Wrong plugin Index ' + IntToStr (plg) + ', ' + IntToStr (dlg));
  end;
end;


procedure TMForm.SelectPrevTab(Sender: TObject);
begin
 if (pctrl.ActivePageIndex > 0) then pctrl.SelectNextPage(false);
end;    

procedure TMForm.SelectNextTab(Sender: TObject);
var num, cnt : integer;
begin
 num := pctrl.ActivePageIndex;
 cnt := pctrl.PageCount;
 if (num + 1 < cnt) then pctrl.SelectNextPage (true);
end;           

procedure TMForm.pctrlChanging(Sender: TObject; var AllowChange: Boolean);
begin
 AllowChange := (csm <> nil);
 if (csm <> nil) then
 if ((csm.prcs.pid = 0)) then
  begin
   AllowChange := false;
   if (pctrl.ActivePageIndex > 0) then pctrl.ActivePageIndex := 0;
  end;
end;

procedure TMForm.RqsListClick(Sender: TObject);
begin
 SaveRqs;
 rqsUpdated := TRUE; 
 RqsList.ItemIndex := csm.CurrRqs - 1;
end;

procedure TMForm.imGameViewDblClick(Sender: TObject);
begin
 fdblclick := true;
 ReleaseCapture;
 mwscroll := false;
 if (nil = gvform) then gvform := TGVform.Create (self);
 if (gvform.ShowModal = 1) then;
 CopySmall;
 mwscroll := false;
end; // On Game View Double Click

procedure TMForm.btnTypeClick(Sender: TObject);
var
   pnt, lp : TPoint;
begin
 pnt := mouse.CursorPos;
 lp := btnType.ScreenToClient (pnt);
 with btnType do
 if (BoundsRect.Left <= lp.X) and (lp.X <= BoundsRect.Right ) and
    (BoundsRect.Top <= lp.y) and (lp.y <= BoundsRect.Bottom) then else
  begin
   lp.X := btnType.Width shr 1;
   lp.Y := btnType.Height shr 1;
   pnt := btnType.ClientToScreen (lp);
  end;
 pmType.Popup(pnt.x, pnt.y);
end;

var mpold: TPoint;

procedure TMForm.imGameViewMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 if fdblclick then else
 if (Button = mbLeft) then
  begin
   SetCapture (Handle);
   mwscroll := true;
   mpold.x := mouse.CursorPos.x;
   mpold.y := mouse.CursorPos.y;
   //mpold := imGameView.ClientToScreen(mpold)
  end;
 fdblclick := false;
end;

procedure TMForm.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
    dx, dy: Integer;
    limx, limy : Integer;
begin
 if fdblclick then else
 if (ssht <> nil) then
 if (mwscroll) then
  begin
   dx := mpold.x - mouse.CursorPos.x;
   dy := mpold.y - mouse.CursorPos.y;
   inc (gvpnt.x, dx);
   inc (gvpnt.y, dy);
   limx := ssht.Width - imGameView.Width - 2;
   limy := ssht.Height - imGameView.Height - 2;
   if (gvpnt.x < 1) then gvpnt.x := 1;
   if (gvpnt.x > limx) then gvpnt.x := limx;
   if (gvpnt.y < 1) then gvpnt.y := 1;
   if (gvpnt.y > limy) then gvpnt.y := limy;
   mpold.x := mouse.CursorPos.x;
   mpold.y := mouse.CursorPos.y;
   //mpold := ClientToScreen (mpold);
   CopySmall ();
  end;
end;

procedure TMForm.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 if (mwscroll) then
  begin
   ReleaseCapture ();
   mwscroll := false;
  end;
end;

procedure TMForm.ListMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
   pnt: TPoint;
   indx: integer;
   list: TListBox;
begin
 pnt.x := x;
 pnt.y := y;
 if (sender is TListBox) then else exit;
 list := (sender as TListBox);
 indx := list.ItemAtPos(pnt, true);
 list.ShowHint := (indx >= 0) and (indx < list.Count);
 if list.ShowHint then list.Hint := list.Items [indx];
end;            

procedure TMForm.lvPSlistSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
 fClick := false;
 if (selected) then lvPSlistClick (sender);
end;

procedure TMForm.lvPSlistMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 if button = mbLeft then fClick := true;
end;

procedure SyncEdit (const ed: TEdit; var s: string; const fback: boolean = false);
begin
 if (fback) then // Обновление строки
  begin
   if (s <> ed.Text) then s := ed.text;
  end
 else // Обновления поля
 if (ed.text <> s) then ed.text := s;
end;

procedure TMForm.SyncRqs;
begin
 SyncEdit (ed_minex, exmin);
 SyncEdit (ed_maxex, exmax);
 SyncEdit (sform.edexmin, exmin);
end; // Синхронизация интерефейса

procedure TMForm.ed_minexChange(Sender: TObject);
begin
 if (sender is TEdit) then
     SyncEdit ((sender as TEdit), exmin, true); // Становление значения
end; // Синхронизация строки

procedure TMForm.ed_maxexChange(Sender: TObject);
begin
 SyncEdit (ed_maxex, exmax, true);
end;

procedure TMForm.ed_minexKeyPress(Sender: TObject; var Key: Char);
begin
 if (key = #13) then btnScan.SetFocus;
end;

procedure TMForm.miSimpleClick(Sender: TObject);
begin
 visible := false;
 if (pctrl.ActivePageIndex <> 0) then
  sform.pcMain.ActivePageIndex := 1;
 hide;
 sform.Show;
end;


procedure TMForm.sgCheatSetEditText(Sender: TObject; ACol, ARow: Integer;
  const Value: String);
begin
 with sform.sgtable do
 if (cells [acol, arow] <> value) then cells [acol, arow] := value;
end;

function TMForm.GetGrid;
begin
 if (pWgcSettings.bSimpleView) then result := sform.sgtable else
        result := frmAddrs.sgcheat;
 gAddrTable := result;
end;

procedure TMForm.ShowQueryList (bShow: Boolean);
begin
 //
 if bShow then
  begin
   addrPanel.Top := vpositions [2];
   addrPanel.Height := 142;
   panQueryList.visible := true;
  end
 else
  begin
   panQueryList.visible := false;
   addrPanel.Top := vpositions [1];
   addrPanel.Height := 142 + 132;
  end;
end;


procedure TMForm.btnGameClick(Sender: TObject);
begin
 ShowWindowAsync (csm.prcs.hwnd, SW_RESTORE); // перейти в игру
 SetForegroundWindow (csm.prcs.hwnd);
end;

procedure TMForm.btnOnlyOneClick(Sender: TObject);
var n: Integer;
begin
 // Adding one adress
 with csm do
 for n := 0 to lbxAddrs.Count - 1 do
 if (lbxAddrs.Selected [n]) and
    (n < svars.fnds [currRqs].addedCount) then
  begin
   AddAddr (svars.fnds [currRqs], n + 1);
  end;
 ReListAddrs;
 wtUpdated := TRUE;
end;

procedure TMForm.FormResize(Sender: TObject);
var h: Integer;
begin
 // sbar.Top := Height - sbar.Height - 1;
 h := Height - span.top - 72;
 if (h > 10) then
  span.Height := h else span.Height := 10;
 span.Realign;
 sbar.Invalidate;
end; // FormResize

procedure TMForm.OnUserMsg;
begin
 //
 if (msg.WParam = $FAB0) then
  case msg.LParam of
   $10: btnWinClick (self);
  end;
end;

procedure TMForm.btnTrainerClick(Sender: TObject);
begin
 //
 FormConstructor.Show;
end;

procedure TMForm.btnSiteClick(Sender: TObject);
begin
 ShellExecute (handle, 'open', 'http://www.alpet.hotmail.ru', nil, nil,
                SW_SHOWNORMAL);
end;

procedure TMForm.OnSysMsg(var msg: TMessage);
var
   prc: Procedure ();
begin
 // Testing
 case msg.wparam of
   SC_MINIMIZE: ShowWindow (Application.handle, SW_MINIMIZE);
      SC_CLOSE: miExitClick (self);
  else
    begin
     @prc := self.DefWndProc;
     // prc (msg);
     DefaultHandler (msg);
    end;
 end;
end;

function  GetScaler (const s: string): Int64; // using for memory
begin
 result := 1;
 if (pos ('K', s) > 0) then result := 1024;
 if (pos ('M', s) > 0) then result := 1024 * 1024;
 if (pos ('G', s) > 0) then result := 1024 * 1024 * 1024;  
end; // GetScaler

function s2int (const s: string): Int64; // уродует строку
var n: DWORD;
    ss: string;
begin
 ss := '';
 for n := 1 to Length (s) do
  if (s [n] in ['$', '0'..'9', 'A'..'F', 'a'..'f']) then
   ss := ss + s [n] else break;
 result := StrToInt (ss);
end;

procedure TMForm.lvRegionsCompare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
var
   d1, d2: Int64;
   s1, s2: string;

begin
 compare := 0;
 if (sortcol = 0) then
  begin
   s1 := item1.Caption;
   s2 := item2.Caption;
  end
 else
  begin
   s1 := item1.SubItems [sortcol - 1];
   s2 := item2.SubItems [sortcol - 1];
  end;
 s1 := UpperCase (s1);
 s2 := UpperCase (s2);
 if (sortcol <= 1) then
  repeat
   d1 := GetScaler (s1);
   d2 := GetScaler (s2);
   d1 := d1 * s2int  (s1);
   d2 := d2 * s2int (s2);
   if (d1 = d2) then
    begin
     // default sorting
     s1 := item1.Caption;
     s2 := item2.Caption;
     break;
    end;
   if (d1 > d2) then compare := sortdir else compare := -sortdir;
   exit;
  until true;
 if (s1 = s2) then exit;
 if (s1 > s2) then compare := sortdir else compare := -sortdir;
end;


procedure TMForm.cbNoCacheClick(Sender: TObject);
begin
 with csm.svars.params.scanpages do
 attrs := SetBit (attrs, PAGE_NOCACHE, cbNoCache.Checked);
 mmsUpdated := TRUE;
end;

procedure TMForm.cbReadOnlyClick(Sender: TObject);
begin
 with csm.svars.params.scanpages do
  attrs := SetBit (attrs, PAGE_READONLY, cbReadOnly.Checked);
 mmsUpdated := TRUE;
end;

procedure TMForm.cbExecutableClick(Sender: TObject);
begin
 with csm.svars.params.scanpages do
  attrs := SetBit (attrs, ExecutablePages, cbExecutable.Checked);
 mmsUpdated := TRUE;
end;

procedure TMForm.cbMem_MappedClick(Sender: TObject);
begin
 csm.svars.params.scanPages.fMemMapped := cbMem_Mapped.Checked;
 mmsUpdated := TRUE;
end;

procedure TMForm.cbMem_ImageClick(Sender: TObject);
begin
 csm.svars.params.scanPages.fMemImage := cbMem_Image.Checked;
 mmsUpdated := TRUE;
end;

procedure TMForm.cbMem_PrivateClick(Sender: TObject);
begin
 csm.svars.params.scanPages.fMemPrivate := cbMem_Private.Checked;
 mmsUpdated := TRUE;
end;

procedure TMForm.lvRegionsColumnClick(Sender: TObject;
  Column: TListColumn);
begin
 if (sortcol = column.Index) then sortdir := - sortdir
 else sortcol := column.Index;
 lvRegions.Items.BeginUpdate;
 lvRegions.SortType := stBoth;
 lvRegions.Items.EndUpdate;
end;

procedure TMForm.cbPSComboClick(Sender: TObject);
begin
 lvPSlist.Clear;
 with wplist do
 begin
  if cbWindowless = sender then SetAddFlags(PMF_WNDLESS, cbWindowless.checked);
  if cbChilds = sender then SetAddFlags (PMF_CHILDWND, cbChilds.Checked);
  if cbVoid = sender then SetAddFlags (PMF_VOIDCAP, cbVoid.Checked);
  if cbVis = sender then SetAddFlags (PMF_INVISIBLE, cbVis.Checked);
  if cbShowPID = sender then SetAddFlags (PMF_ADDPID, cbShowPID.Checked);
 end;
 UpdateProcessList;
end;

procedure TMForm.cb_alignedClick(Sender: TObject);
begin
 csm.svars.fAligned := cb_aligned.Checked;
end;

procedure TMForm.cbMMXClick(Sender: TObject);
begin
 pWgcSettings.bUseMMX := cbMMX.Checked;
end;

procedure TMForm.cbRWtestClick(Sender: TObject);
begin
 csm.svars.params.scanpages.fTestRW := cbRWtest.Checked;
 mmsUpdated := TRUE;
end;

procedure TMForm.btnHideQueryListClick(Sender: TObject);
begin
 with frmOptions do
  begin
   cbQueryList.Checked := false;
   cbQueryList.OnClick (Sender);
  end;
end;

procedure TMForm.btnHideRulePanClick(Sender: TObject);
begin
 with frmOptions do
  begin
   cbRuleBtns.Checked := false;
   cbRuleBtns.OnClick (Sender);
  end;
end;

procedure TMForm.cbPrefetchClick(Sender: TObject);
begin
 pWgcSettings.bPrefetch := cbPrefetch.Checked;
end;

procedure TMForm.edMaxRegsizeExit(Sender: TObject);
var e: integer;
begin
 val (edMaxRegsize.text,
      pscparams.scanPages.maxRegionSize, e);
 if (e <> 0) then exit;
 mmsUpdated := TRUE;
end;

procedure TMForm.FormShow(Sender: TObject);
begin
 DockForm (frmOptions, tsOptions);
 frmAddrs.Show;
 frmAddrs.ManualDock(pnTable);
 frmAddrs.Realign;
end;

procedure TMForm.BYTE1Click(Sender: TObject);
var s: string;
    p: Integer;
begin
 if (Sender is TMenuItem) then
   begin
    s := TMenuItem(Sender).Caption;
    p := Pos ('&', s);
    if (p > 0) then Delete (s, p, 1);
    mform.btnType.caption := s;
   end;
 SaveRqs;
 rqsUpdated := TRUE;   
end;

procedure TMForm.OnVMSMapCreated;
var s: String;
    bChanged: Boolean;
begin
 bChanged := csm.vmsize <> vmsize;
 csm.vmsize := vmsize;
 csm.fMap := vmsize > 0;
 if not csm.fMap then exit;
 if (not fmapx) then
  begin
   // обработка события
   fmapx := true;
   UpdLastMsg (LocStr ('%MapCreateComplete%'));
  end;
 s := LocStr ('%Process_Size%') + ' ';
 if not csm.fMap then s := s + ' > ';
 s := s + msdiv (csm.vmsize);
 if bChanged then LogStrEx (s, 15);
 if not csm.svars.aliased then s := LocStr ('%ProcessNotSelected%');
 if (s <> sbar.Panels [1].Text) then sbar.panels [1].text := s;
 if Ready then PaintReady;
end; // OnVMSMapCreate

procedure TMForm.SetConState (bConnect: Boolean);

begin
 if  bConnect then ilLamps.GetBitmap (1, imConnect.Picture.Bitmap)
 else ilLamps.GetBitmap (0, imConnect.Picture.Bitmap);
end;

procedure TMForm.UpdateProcessList;
begin
 SendMsgEx (CM_PSLIST, wplist.addmask, wplist.maskPID );
end;

procedure TMForm.cbShowPIDClick(Sender: TObject);
begin
 wplist.bShowPID := cbShowPID.Checked;
 wplist.Store (plvx_cache, TRUE);
 CopyPSListCache;
 SendMsgEx (CM_PSLIST, wplist.addmask, wplist.maskPID );
end;

end.

