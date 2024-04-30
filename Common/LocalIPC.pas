unit LocalIPC;

{ ������ ��������� ���������� �������������� ����������.
  ������� �����������:
   ������ ������� ��������� �������� ������� �������� ������������
  � ����� ������ ������������ � ����������� ������. ��� ����������
  ������ ������������ ����������� �������� ��� ������������ (�� ��
  ���� ������������� ����� �������� ������� ��������).

 + ������ ������ ������ �� ��������� 16�, ��� �������� �����������
 + ���������� ������ ����� ��������� ������ ������������������ ����������
 + ������ ������ ������ ����������� � ������� ���������� ������.

}

interface
uses ShareData;

var  incoming: TShareData = nil;
    outcoming: TShareData = nil;


procedure    InitShare (const iname, oname: AnsiString);
function     ClientGlobalName: String;
function     ServerGlobalName: String;

implementation
uses Windows, Misk;

var winver: DWORD = 4;

procedure    InitShare;
begin
 incoming := TShareData.Create (PAnsiChar (iname), 'IN');
 outcoming := TShareData.Create (PAnsiChar (oname), 'OUT');
end;

function     NormStr (const s: String): String;
var n: Integer;
begin
 result := '';
 for n := 1 to Length (s) do
  case s [n] of
   //'.': result := result + '_';
   'A'..'Z','a'..'z': result := result + Upcase (s [n]);
   '0'..'9': result := result + s [n];
  end;
end;

function     ClientGlobalName: String;
begin
 if winver and $FF > 4 then
      result := 'Global\WGC_CLIENT'
 else result := 'WCL';
 result := result + sVersion; // add wgc version
 result := NormStr (result);
 if not bDirectMode then
    result := result + Dword2hex (GetCurrentProcessId);
end;

function     ServerGlobalName: String;
begin
 if winver and $FF > 4 then
      result := 'Global\WGC_SERVER'
 else result := 'WSR';
 result := result + sVersion; // add wgc version
 result := NormStr (result);
 if not bDirectMode then
    result := result + Dword2hex (GetCurrentProcessId); // set unique
end;


initialization
 // cob-cobe
 Randomize;
 winver := GetVersion;
finalization
 if incoming <> nil then incoming.Free;
 if outcoming <> nil then outcoming.Free;
end.
