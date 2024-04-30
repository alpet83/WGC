DEFALGS                 MACRO  ScanFunc, SieveFunc
;---------------------- ----------------------- ---------------------------
ALIGN                   32
ScanFunc                PROC STDCALL uses eax ebx ecx edx esi edi,  buff:DWORD, rslt:DWORD, bsize:DWORD
;---------------------- ----------------------- ---------------------------
; Поиск диапазона значений
; функция требует выравнивание esi по границе как минимум 32, а лучше 64 или 128
                        ; Настройка динамического кода
                        mov                     esi, buff     ; нормальный источник
                        mov                     ecx, bsize    ; размер буффера в байтах
                        mov                     edi, rslt     ; нормальный приемник
                        add                     ecx, esi      ; преобразовать в предел
                        mov                     dword ptr [CmpLimit][2], ecx ; Запись лимита
                        xor                     eax, eax              ; Index of Buffer = 0
                        mov                     ebx, dword ptr [exampleMin]
                        mov                     ecx, dword ptr [exampleMax]
                        mov                     savebp, ebp
                        xor                     ebp, ebp
                        mov                     [edi], ebp
                        mov                     [edi + 4], ebp
;---------------------- ----------------------- ---------------------------
CmpLoop:                ; ЦИКЛ СКАНИРОВАНИЯ
                        OFS = 0
;---------------------- ----------------------- ---------------------------
IF optcache eq 1
                        mov                     edx, [esi + 1Ch]
                        mov                     dword ptr temp [0], edx
                        mov                     eax, [esi + 20h]
                        mov                     dword ptr temp [4], eax
ENDIF
                        xor                     edx, edx
                        xor                     eax, eax
                        n = 0
                        ; Развернутый цикл для 61 значений
                        ; заполнение регистра edx
                        REPT                    32
                        cmprset                d, %n, esi
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
                        ; заполнение регистра eax
                        REPT                    29
                        cmprset                a, %n, esi
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
;---------------------- ----------------------- ---------------------------
IF optcache eq 1
                        ; Работа с остатками
                        OFS = 1
                        REPT                    3
                        cmprset                a, %n, temp
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
ELSE  ; продолжить сравнение в том же духе
                        REPT                    3
                        cmprset                a, %n, esi
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
ENDIF
;---------------------- ----------------------- ---------------------------
                        add                     esi, 40h   ; следующее 32 смещений
                        cmp                     [edi], edx
                        je                      NotSave
;---------------------- ----------------------- ---------------------------
                        mov                     [edi + 4], ebp  ; сохранить количество
                        mov                     [edi + 8], edx  ; сохранить множество
                        xor                     ebp, ebp
                        mov                     dword ptr [edi + 12], ebp ; сохранить нуль
                        add                     edi, 8     ; увеличить указатель
;---------------------- ----------------------- ---------------------------
NotSave:
                        add                     ebp, 1
                        cmp                     [edi], eax
                        je                      NotSave2
                        mov                     [edi + 4], ebp ; сохранить количество
                        mov                     [edi + 8], eax ; сохранить множество
                        xor                     ebp, ebp
                        mov                     dword ptr [edi + 12], ebp ; save 0
                        add                     edi, 8
NotSave2:
                        add                     ebp, 1
CmpLimit:     ;  Это динамический код
                        cmp                     esi, 12345678h
                        jb                      CmpLoop  ; If below
;---------------------- ----------------------- ---------------------------
                        mov                     [edi + 0], edx ; пересохранить множество
                        mov                     [edi + 4], ebp ; пересохранить количество
                        mov                     ebp, savebp
                        mov                     _packalg, RLESET  ; упаковка множеством + RLE
                        mov                     _Found, 1         ; условно найдено ...
                        sub                     edi, rslt         ; вычесть начало
                        mov                     _isize, 8
                        shr                     edi, 3            ; делить на 8
                        mov                     _Lcount, edi      ; count of offsets
                        add                     _Lcount, 1
                        ret
ScanFunc                ENDP
;---------------------- ----------------------- ---------------------------
SieveFunc               PROC STDCALL uses eax ebx ecx edx esi edi, lbuff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
; Настройка динамического кода
                        mov                     esi, lbuff
                        mov                     edi, dst     ; место нганачения
                        mov                     edx, setlst  ; исходные множества
                        mov                     ecx, count
                        shl                     ecx, 2       ; умножить на 4 (32бита в мн)
                        add                     ecx, edx     ; преобразовать в предел
                        mov                     dword ptr [@CmpLimit][2], ecx ; DynaCode (3)
                        mov                     ebx, dword ptr [ExampleMin]
                        mov                     ecx, dword ptr [ExampleMax]
                        xor  eax, eax           ; Очистка eax
                        mov                     savebp, ebp
                        mov                     ebp, edx
                        mov                     [edi + 0], eax ; мнжство
                        mov                     [edi + 4], eax ; счетчик
;---------------------- ----------------------- ---------------------------
                        ; Отсев значения - диапазона
@Repeat:                ; перемещение значений у границы линейки
                        xor                     edx, edx ; очистить новое множество
                        cmp                     dword ptr [ebp], edx
                        je                      nocomp ; если ноль - не проверять значения
IF optcache eq 1
                        mov                     eax, [esi + 1Ch]
                        mov                     dword ptr temp [0], eax
                        mov                     eax, [esi + 20h]
                        mov                     dword ptr temp [4], eax
ENDIF                        
;---------------------- ----------------------- ---------------------------
                        OFS = 0                 ; сброс смещения в линейке
                        ; заполнение регистра edx
                        REPT                    29
                        cmprset                d, %n, esi
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
;---------------------- ----------------------- ---------------------------
IF optcache eq 1
                        ; Работа с остатками
                        OFS = 1
                        REPT                    3
                        cmprset                d, %n, temp
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
ELSE  ; не заботится о переходе границы
                        REPT                    3
                        cmprset                d, %n, esi
                        OFS = OFS + 1
                        n = n + 1
                        ENDM
ENDIF                        
;---------------------- ----------------------- ---------------------------
                        and                     edx, [ebp]     ; маскировать множество
nocomp:                        
                        add                     esi, 20h       ; следующие 32 значения
                        add                     ebp, 4         ; следующее множествo
                        cmp                     [edi], edx      ; сравнить множества
                        je                      NotSave1        ; не схоронять заново
                        mov                     [edi + 8], edx  ; новое множество
                        mov                     dword ptr [edi + 12], 0 ; кол-во = 0
                        add                     edi, 8
NotSave1:
                        add                     dword ptr [edi + 4], 1
@CmpLimit:      ;  SMC3
                        cmp                     ebp, 12345678h ; chto ListLimit
                        jb                      @Repeat  ; If below
                        xor                     eax, eax
                        mov                     ebp, savebp
                        test                    edx, edx  ; flag on Zerro
                        setnz                   al
                        mov                     _packalg, RLESET ; неполная RLE упаковка
                        lea                     edi, [edi + eax * 8] ; дополнить предел
                        sub                     edi, dst
                        mov                     _Isize, 8
                        shr                      edi, 3         ; делить на 8
                        mov                     _Found, 1
                        mov                     _Lcount, edi    ; количество элементов
                        ret
                        ENDP
;---------------------- ----------------------- ---------------------------                        
public                  ScanFunc
public                  SieveFunc
;---------------------- ----------------------- ---------------------------
                        ENDM




