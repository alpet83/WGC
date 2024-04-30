unit ChAbout;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, jpeg;

type
  TAboutBox = class(TForm)
    btnOK: TSpeedButton;
    lbAppName: TLabel;
    Descript: TMemo;
    lVersion: TLabel;
    logo: TImage;
    procedure btnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;
  wgcver: string;

implementation
uses misk;

{$R *.DFM}
                                                                      
procedure TAboutBox.btnOKClick(Sender: TObject);
begin
 close;
end;

procedure TAboutBox.FormCreate(Sender: TObject);

begin                       
 lVersion.caption := 'ver: ' + wgcver;
end;

type
    TransList = array [0..95, 0..1] of dword;
initialization
 wgcver := GetVersionStr; 
end.

