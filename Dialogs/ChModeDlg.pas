unit ChModeDlg;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TModeSelDlg = class(TForm)
    btnSimple: TButton;
    btnClassic: TButton;
    AFrame: TBevel;
    ldesc: TLabel;
    procedure btnSimpleClick(Sender: TObject);
    procedure btnClassicClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;



procedure RunModeSelDialog (var result: Boolean);
implementation
uses ChForm;
{$R *.dfm}
var
  ModeSelDlg: TModeSelDlg = nil;

procedure RunModeSelDialog (var result: Boolean);
begin
 if ModeSelDlg = nil then ModeSelDlg := TModeSelDlg.Create (mform);
 result := ModeSelDlg.ShowModal <> idNo; // True = simple mode
end;

procedure TModeSelDlg.btnSimpleClick(Sender: TObject);
begin
 ModalResult := idYes;
end;

procedure TModeSelDlg.btnClassicClick(Sender: TObject);
begin
 ModalResult := idNo;
end;

procedure TModeSelDlg.FormCreate(Sender: TObject);
begin
 ldesc.Caption :=
  'Выберите с каким интерфейсом вы хотите начать работу:'#13#10 +
  '     1. Упрощенный интерфейс предназначен для обучения, и рекомендуется' +
  ' для знакомства с программой.'#13#10 +
  '     2. Классический интерфейс открывает доступ к дополнительным возможностям' +
  ' программы, но для начинающих пользователей может быть сложен.' +
  ' Рекомендуется использовать после усвоения основных навыков работы с WGC.'#13#10#10 +
  ' P.S. Интерфейс от англицкого Interface (Междумордие) - здесь означает вид программы';
end;

end.
