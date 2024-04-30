unit wconapi;

interface
uses conapi, windows;

function MakeConsole: TAbsConsole;
function SetConsoleEventHook (ConEventProc: TFNWndProc): THandle; stdcall;

implementation
function MakeConsole: TAbsConsole; external 'wconapi.dll';
function SetConsoleEventHook (ConEventProc: TFNWndProc): THandle; external 'wconapi.dll';

end.
 