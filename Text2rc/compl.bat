@echo off
path c:\delphi6\bin;
txt2rc help.txt help.rc
brcc32 help.rc > log.txt
copy *.res c:\doc\chtr\res /y