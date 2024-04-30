unit timerts;

interface
uses Windows, SysUtils, ChShare, ChLog;



procedure  StartTimer (n : byte);
procedure  GetTimerElapsed (n : byte; var st : TSystemTime);
function   GetSeconds: dword;
procedure  GetDelay (var old, cur, rslt : TSystemTime);
function   St2int (var t : TSystemTime) : DWORD;
procedure  Int2st (wt : dword; var st : TSystemTime);
function   SysTime2str (var st : TSystemTime) : string;
function   StartCounter (const n : byte): Int64;
function   GetElapsed (const n: byte) : int64;
function   Tacts2sec (const c : int64) : extended;     


implementation
uses misk;
var freq : int64;

function   Tacts2sec (const c : int64) : extended;
 begin
  if freq = 0 then freq := 1000000;
  result := c / freq;
 end;

function  StartCounter (const n : byte): Int64;

 begin
  if QueryPerformanceCounter (result) then // using only for aligned access
  else ods ('Performance counters is not workable ' + GetLastErrorStr);
  if (smobj = nil) or not (n in [1..10]) then exit;
  smobj.counters [n] := result
 end;

function   GetElapsed (const n : byte) : int64;
 var c : Int64;
 begin
  result := -1;
  QueryPerformanceCounter (c);
  if (smobj <> nil) and (n in [1..10]) then
  with smobj do
   result := c - counters [n];
 end;
 
function   SysTime2str;
 function  LZerro (w : word) : string;
 var s : string;
 begin
  s := IntToStr (w);
  while Length (s) < 2 do s := '0' + s;  
  result := s;
 end; // LZerro

 function  MZerro (w : word) : string;
 { 0.20 = 0.20 0.6 = 0.06 }
 var s : string;
 begin
  s := IntToStr (w);
  while Length (s) < 3 do s := '0' + s;
  delete (s, 3, 1);
  result := s;
 end; // MZerro

begin
 result := IntToStr (st.wHour) + ':' +
             LZerro (st.wMinute) + ':' +
             LZerro (st.wSecond) + ',' +
             MZerro (st.wMilliseconds);  
end;

function St2int;
begin
 with t do
 result :=   wHour * 3600000 +
           wMinute * 60000 +
           wSecond * 1000 + wMilliseconds
end; // St2int

procedure Int2St;
begin
 GetLocalTime (st);
   st.wHour := (wt div 3600000) mod 24;
 st.wMinute := (wt div 60000) mod 60;
 st.wSecond := (wt div 1000) mod 60;
 st.wMilliseconds :=  wt mod 1000;
end; // int2st

procedure  GetDelay;

var o, c, d : LongInt;
begin
 if (old.wHour = 23) and (cur.wHour = 0) then old.wHour := 24;
 o := st2int (old);
 c := st2int (cur);
 d := c - o;
 Int2St (d, rslt);
end; //

procedure  StartTimer (n : byte);
begin
 if smobj <> nil then
 with smobj do
 if (n >= 1) and (n <= 10) then GetLocalTime (timers [n]);
end; // StartTimer

procedure  StopTimer (n : byte);
begin
end; // StopTimer

procedure   GetTimerElapsed;
begin
 GetLocalTime (st);
 if (n >= 1) and (n <= 10) then else exit;
 if smobj <> nil then
 with smobj do
 GetDelay (timers [n], st, st);
end; // GetTimerSeconds

function GetSeconds;
 var hour, min, sec, msec : word;
begin
 DecodeTime (time, hour, min, sec, msec);
 result := sec * 100 + msec;
end; // GetSeconds;

begin
 QueryPerformanceFrequency (freq);
end.
