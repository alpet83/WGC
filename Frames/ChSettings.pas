unit ChSettings;

interface

uses Windows;

type
    TWGCSettings = record
     // INTERFACE PART
     nConsTransparent: WORD;  //  tbTransp.Position
     bShowCons: ByteBool; // cbConsole.Checked
     bShowIcons: ByteBool;
     bSimpleView: Boolean;  // ���������� �����

     bConsInputCapture: ByteBool; // mform.cbInputCapture.Checked
     bResRestore: ByteBool;  // cbResres.checked
     bIdleRead: ByteBool;
     bUpdateUI: ByteBool; // cbUIupdate.Checked
     bPrefetch: ByteBool;
       bUseMMX: ByteBool; // ������������ ��������� MMX
    maxRegSize: DWORD; // ������������ ������ �������
     nTimerInt: DWORD; // �������� ��������� �������
     nScanPriority: Integer; //
     buffSize: DWORD;
     bSuspend: Boolean; // ������������� ������� ���� ��� ������ �������
    end;


implementation

end.
