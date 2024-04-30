;---------------------- ----------------------- ---------------------------
regst                   MACRO   num, rg, shift
scc&num:
                        sete                    rg&l
ifb <shift>
                        ror                     e&rg&x, 1
else
                        ror                     e&rg&x, shift
endif
                        nn = nn + 1
                        ENDM                    ; reg store
;---------------------- ----------------------- ---------------------------
regstl                  MACRO   num, rg
scc&num:
                        sete                    rg&l
                        nn = nn + 1
                        ENDM                    ; reg store
;---------------------- ----------------------- ---------------------------
regsth                  MACRO   num, rg
scc&num:
                        sete                    rg&h
                        nn = nn + 1
                        ENDM                    ; reg store                        
;---------------------- ----------------------- ---------------------------
compsetb                macro                   rg, offst, shift
                        ; самый продолжительный поиск ??
                        movzx                   ebp, byte ptr [esi + INDEX + offst]
                        cmp                     dword ptr [ExampleMin], ebp
                        regst                   %nn, rg, shift
                        endm
;---------------------- ----------------------- ---------------------------
compsetw                macro                   rg, offst, shift
                        cmp                     word ptr [esi + INDEX + offst], bp
                        regst                   %nn, rg, shift
                        endm
;---------------------- ----------------------- ---------------------------
compsetd                macro rg, offst, shift
                        cmp                     dword ptr [esi + INDEX + offst], ebp
                        regst                   %nn, rg, shift
                        endm
;---------------------- ----------------------- ---------------------------
compsetdl               macro rg, offst
                        cmp                     dword ptr [esi + INDEX + offst], ebp
                        regstl                  %nn, rg
                        endm
;---------------------- ----------------------- ---------------------------
compsetdh               macro rg, offst
                        cmp                     dword ptr [esi + INDEX + offst], ebp
                        regsth                  %nn, rg
                        endm
;---------------------- ----------------------- ---------------------------
cmprset                 macro                   rg, n, value
                        ;  сравнение с нижней границей
                        cmp                     dword ptr [value + OFS], ebx
                        jb                      @nor&n ; не меньше
                        ; сравнение с верхней границей
                        cmp                     dword ptr [value + OFS], ecx
                        ja                      @nor&n ; не больше
                        or                      rg&l, 1      ; установить 0-ой бит
@nor&n:
                        ror                     e&rg&x, 1     ; переместить в старший бит
                        endm
;---------------------- ----------------------- ---------------------------
; подмена SMC байта
setscc                  macro num
                        mov                     byte ptr [scc&num + 1], al
                        endm
;---------------------- ----------------------- ---------------------------
optcache = 1
