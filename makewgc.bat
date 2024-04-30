@echo off

SET %PD%=W:

cD \DOC\CHTR
path %PD%\Delphi6\Bin;%PD%\Delphi6\Lib;%path%
if exist wgc.exe del wgc.exe 
set srcdir=%PD%\DOC\chtr
@echo on
dcc32 wgc.dpr chdip\chdip.dpr -$D- -$L- -$C- -b -q -U%PD%\DOC\Build -I%srcdir%  >build.log
@echo off	
type build.log
if exist wgc.exe dir wgc.exe 
del *.~*
rem if exist wgc.exe upx wgc.exe --compress-icons=0 
pause