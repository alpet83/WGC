.586
locals
.model flat, STDCALL
;---------------------- ----------------------- ---------------------------
include                 extvars.inc
include                 fscanw.inc
include                 scanrng.inc
optcache = 0
;---------------------- ----------------------- ---------------------------
CODE                    SEGMENT                 PAGE "_TEXT"
                        DEFALGS                 ScanRangeW, SieveRangeW
CODE                    ENDS
;---------------------- ----------------------- ---------------------------
END
