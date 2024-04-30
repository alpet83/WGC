@echo off
path c:\tasm\bin;
break on
:loop
cls
tasm /m3 *,*,* /t /zi
echo.
echo Assembling complete.
pause > nul
goto loop 