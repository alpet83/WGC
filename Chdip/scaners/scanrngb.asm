.586
locals
.model flat, STDCALL
;---------------------- ----------------------- ---------------------------
include                 extvars.inc
include                 fscanb.inc
include                 scanrng.inc
;---------------------- ----------------------- ---------------------------
CODE                    SEGMENT                 PAGE "_TEXT"
                        DEFALGS                 ScanRangeB, SieveRangeB
CODE                    ENDS
;---------------------- ----------------------- ---------------------------
END
