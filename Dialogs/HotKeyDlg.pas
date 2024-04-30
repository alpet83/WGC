unit HotKeyDlg;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  StdCtrls, ExtCtrls, Forms, KbdAPI, KbdDefs;

type

     THotKeyData = packed class (TPersistent)
     // класс данных горячей клавыши
     private
      function    FGet: dword;
      procedure   FSet (x: dword);
      function    GetString: string; // Получить в виде строки
     public
      key, flags: word;     // data of Hot Key
      Action: String;       // Действие

      property str: string read GetString;
      property pack: dword read FGet write FSet;

      procedure Assign (source: TPersistent); override;
      constructor           Create (act: string; vkey: word; flgs: byte);
     end;

     THKeyDlg = class(TForm)
    btnOK: TButton;
     procedure edRecieverKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
     private
      hkresult: THotKeyData;
     public
      constructor Create (AOwner: TComponent); override;
     published
    edReciever: TEdit;
     end;


procedure    RecieveHotKey (AOwner: TComponent; hk: THotKeyData);

implementation
uses ChCodes, ChConst, ChTypes;
{$R *.DFM}
var
  HKeyDlg: THKeyDlg = nil;

{ HotKeyDlg }

procedure RecieveHotKey;
begin
 if HKeyDlg = nil then HKeyDlg := THKeyDlg.Create(AOwner);
 HKeyDlg.hkresult := hk;
 HKeyDlg.ShowModal;
end; // RecieveHotKey

{ THotKeyData }

procedure THotKeyData.Assign(source: TPersistent);
begin
 if source is THotKeyData then
  begin
   key := THotKeyData(source).key;
   flags := THotKeyData(source).flags;
  end else
 inherited Assign (source);
end;

constructor     THotKeyData.Create;
begin
 key := vkey;
 action := act;
 flags := flgs;
end;


function THotKeyData.FGet: dword;
begin
 result := PHotKeyRec (@key).pack;
end;

procedure THotKeyData.FSet(x: dword);
begin
 PHotKeyRec (@key).pack := x;
end;

function        THotKeyData.GetString;
begin
 result := StrKey (key, flags);
end; // GetString


{ THKeyDlg }
constructor THKeyDlg.Create;
begin
 hkresult := nil;
 inherited Create (AOwner);
end;


procedure THKeyDlg.edRecieverKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var flags: word;
begin
 // проверка назначенного результата
 if not Assigned (hkresult) then exit;
 flags := byte (shift) and $7F; // Перевести в флажки
 if IsPressed (VK_LWIN) then flags := flags or KF_WIN;
 StoreHotKey (hkresult, key, flags);
 edReciever.Text := hkresult.str;
end;

procedure THKeyDlg.btnOKClick(Sender: TObject);
begin
 ModalResult := idOk;
end;

procedure THKeyDlg.FormShow(Sender: TObject);
begin
 if Assigned (hkresult) then
    edReciever.Text := hkresult.str;
 edReciever.SetFocus;
end;

end.
