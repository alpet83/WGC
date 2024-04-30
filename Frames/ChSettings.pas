unit ChSettings;

interface

uses Windows;

type
    TWGCSettings = record
     // INTERFACE PART
     nConsTransparent: WORD;  //  tbTransp.Position
     bShowCons: ByteBool; // cbConsole.Checked
     bShowIcons: ByteBool;
     bSimpleView: Boolean;  // упрощенный режим

     bConsInputCapture: ByteBool; // mform.cbInputCapture.Checked
     bResRestore: ByteBool;  // cbResres.checked
     bIdleRead: ByteBool;
     bUpdateUI: ByteBool; // cbUIupdate.Checked
     bPrefetch: ByteBool;
       bUseMMX: ByteBool; // Использовать алгоритмы MMX
    maxRegSize: DWORD; // максимальный размер региона
     nTimerInt: DWORD; // интервал основного таймера
     nScanPriority: Integer; //
     buffSize: DWORD;
     bSuspend: Boolean; // останавливать процесс игры при выводе консоли
    end;


implementation

end.
