.586
locals
.model flat, STDCALL
;---------------------- ----------------------- ---------------------------
include                 extvars.inc
include                 fscan.inc
include                 scanrng.inc
;---------------------- ----------------------- ---------------------------
CODE                    SEGMENT                 PAGE "_TEXT"
                        DEFALGS                 ScanRangeD, SieveRangeD
CODE                    ENDS
;---------------------- ----------------------- ---------------------------
END
