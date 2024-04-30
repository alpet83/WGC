.386
locals

.model flat, STDCALL

data                    segment public ".DATA"
savesp                  dd              ?
savebp                  dd              ?
example                 dd              0
ptrexit                 dd              0
ptrcont                 dd              0
include                 extvars.inc
data                    ends
.code
; end

ASSUME DS:_TEXT,CS:_TEXT,ES:_TEXT

extrn                   stdcall  ScanDWORDS
ScanSimple              proc                    buff:DWORD, rslt:DWORD, bsize:DWORD
;---------------------- ----------------------- ---------------------------
                        pushad
                        popad
                        ret
ScanSimple              endp



end                     ; конец файла и проч.