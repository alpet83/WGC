program stand;

uses
  Windows, SysUtils,
  Forms,
  FStand in 'FStand.pas' {mform};

{$R *.res}

begin
  MemoryUnlock;
  Application.Initialize;
  Application.CreateForm(Tmform, mform);
 if (ParamStr (1) = 'DISPLAY') then Application.Run;
end.
