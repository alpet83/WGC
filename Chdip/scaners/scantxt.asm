 .386
locals
.model flat, STDCALL
;---------------------- ----------------------- ---------------------------
CODE                    SEGMENT PAGE "_TEXT"
;---------------------- ----------------------- ---------------------------
; Внешние переменные
include                 extvars.inc
ALIGN 32
;---------------------- ----------------------- ---------------------------
CmpChar                 MACRO                   ord, reg, ofst, islast
                        cmp                     [esi + ofst], reg ;; buff [0] ? extext [0]
IFB <islast>
                        jne                     @@NextComp&ord&ofst  ; на проверку след байта
                        mov                     al, ofst
                        jmp                     CompStr&ord          ; проверять по порядку
@@NextComp&ord&ofst:
ELSE
                        mov                     al, ofst
                        jne                     @@BreakNFound      ; ничего не найдено
ENDIF
                        ENDM
ScanText                PROC STDCALL uses eax ebx ecx edx esi edi ebp, buff:DWORD, rslt:DWORD, bsize:DWORD
; Имеем: образец в глобальной переменной
                        mov                     esi, buff
                        mov                     edi, pwhole   ; Использовать прокси буффер
                        mov                     edx, esi     ; Используется как начало буффера
                        mov                     ecx, bsize
                        add                     ecx, esi           ; Получить предел
                        mov                     ebp, ExampleText ; указатель
@@ScanRepeat:
                        xor                     eax, eax ; Index
@@repeat:
                        ;; Сначало несколько сравнений первого симовола
                        mov                     bl, byte ptr [ebp]  ; Образец [0]..[3]
                        CmpChar                 1, bl, 0
                        CmpChar                 1, bl, 1
                        CmpChar                 1, bl, 2
                        CmpChar                 1, bl, 3, 1
CompStr1:
                        add                     esi, eax   ; buff += ofs
                        mov                     al, 1      ; символ обраца [esi + eax] = [2]
LCompStr1:
                        ; Взять один из байтов строки образца
                        mov                     bl, byte ptr [ebp + eax]
                        cmp                     bl, 0                           ; Конец образца
                        je                      @@BreakFound ; Найдено НЕ-ЧТО, т.к. достигнут конец образца
                        cmp                     byte ptr [esi + eax], bl         ; байт из буффера
                        jne                     @@BreakNFound ; таки не равно
                        add                     al, 1
                        cmp                     al, 64        ; Предосторожность
                        jb                      LCompStr1     ; Заклить поиск внутри образца
                        jmp                     @@BreakNFound ; Беда с образцом
@@BreakFound:
                        mov                     ebx, esi ; Текущий адрес в буффере
                        sub                     ebx, edx ; Смещение в буффере
                        mov                     [edi], bx
                        add                     edi, 2
@@BreakNFound:
                        add                     eax, 1      ; 0-символ = 1-символ
                        add                     esi, eax ; Сместиться в буффере на n
                        cmp                     esi, ecx ; Сравнить с концом буффера
                        jb                      @@ScanRepeat
@@ScanComplete:
                        mov                    _packalg, 0
                        sub                     edi, pwhole
                        shr                     edi, 1
                        mov                    _found, di
                        mov                    _Lcount ,edi
                        mov                    _Isize, 2
                        ret
ScanText                ENDP
ALIGN 32
;---------------------- ----------------------- ---------------------------
ScanWide                PROC  STDCALL uses eax ebx ecx edx esi edi ebp,  _buff:DWORD, _rslt:DWORD, _bsize:DWORD
; Имеем: образец в глобальной переменной
                        mov                     esi, _buff
                        mov                     edi, pwhole
                        mov                     ecx, _bsize
                        mov                     edx, esi
                        add                     ecx, esi ; Получить предел
                        mov                     ebp, dword ptr [ExampleText]
@@ScanRepeat:
                        xor                     eax, eax ; Index
@@repeat:
                        mov                     bx, [eax + ebp]  ; Образец
                        ver = 2 
                        CmpChar                 2, bx, 0
                        CmpChar                 2, bx, 1
                        CmpChar                 2, bx, 2
                        CmpChar                 2, bx, 3, 1
CompStr2:
                        add                     esi, eax
                        mov                     al, 1
LCompStr2:
                        mov                     bx, [ebp][eax] ; символ из образца
                        cmp                     bx, 0                           ; Конец образца
                        je                      @@BreakFound ; Найден указатель т.к. достигнут конец образца
                        cmp                     word ptr [esi][eax], bx         ; байт из буффера
                        jne                     @@BreakNFound
                        add                     eax, 2   ; Символ WideChar = 2 байта
                        cmp                     ax, 64  ; Предосторожность
                        jb                      LCompStr2 
                        jmp                     @@BreakNFound ; Беда с образцом
@@BreakFound:
                        mov                     ebx, esi
                        sub                     ebx, edx ; Смещение в буффере
                        mov                     [edi], bx
                        add                     edi, 2

@@BreakNFound:
                        inc                     eax      ; 0-символ = 1-символ
                        add                     esi, eax ; Сместиться в буффере на n
                        cmp                     esi, ecx ; Сравнить с концом буффера
                        jb                      @@ScanRepeat
@@ScanComplete:
                        sub                     edi, pwhole
                        mov                    _packalg, 0
                        shr                     edi, 1
                        mov                    _found, di
                        mov                    _Lcount, edi
                        mov                    _Isize, 2
                        ret
ScanWide                ENDP
;---------------------- ----------------------- ---------------------------
SieveText               PROC STDCALL uses eax ebx ecx edx esi edi ebp,  buff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
                        mov                     esi, pprevd
                        mov                     edi, pwhole
                        mov                     ecx, count
                        mov                     edx, buff
                        add                     ecx, esi        ; в предел списка смещений
                        mov                     ebp, exampleText
                        mov                     dword ptr @@SMC_CMP [3], edx ; Адрес подбуффера
                        xor                     eax, eax    ; Смещение
@@ScanRepeat:
                        movzx                   eax, word ptr [esi] ; Загрузить смещение
                        add                     esi, 2
                        xor                     edx, edx    ; Индекс
@@repeat:
                        mov                     bl, byte ptr [ebp + edx]  ; Образец
                        cmp                     bl, 0                           ; Конец образца
                        je                      @@BreakFound ; Найдено НЕ-ЧТО, т.к. достигнут конец образца
                        ;  Динамический код  ;
@@SMC_CMP:
                        cmp                     byte ptr [12345678h + edx][eax], bl  ; байт из буффера
                        jne                     @@BreakNFound
                        inc                     edx
                        cmp                     dx, 64  ; Предосторожность
                        jb                      @@repeat
                        jmp                     @@BreakNFound
@@BreakFound:
                        mov                     [edi], ax
                        add                     edi, 2
@@BreakNFound:
                        cmp                     esi, ecx ; Сравнить с концом списка
                        jb                      @@ScanRepeat
@@ScanComplete:
                        sub                     edi, pwhole
                        mov                    _packalg, 0
                        shr                     edi, 1
                        mov                    _found, di
                        mov                    _Lcount, edi
                        mov                    _Isize, 2
                        ret
SieveText               ENDP

;---------------------- ----------------------- ---------------------------
SieveWide               PROC STDCALL uses eax ebx ecx edx esi edi ebp, buff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
                        mov                     edx, buff
                        mov                     ecx, count
                        mov                     esi, pprevd
                        mov                     edi, pwhole
                        add                     ecx, esi
                        mov                     dword ptr @@SMC_CMP [4], edx ; Адрес подбуффера
                        mov                     ebp, ExampleText
                        xor                     eax, eax    ; Смещение
@@ScanRepeat:
                        movzx                   eax, word ptr [esi] ; Загрузить смещение
                        add                     esi, 2
                        xor                     edx, edx    ; Индекс
@@repeat:               ; Загрузить символ из строки образца (глобальный доступ)
                        mov                     bx, word ptr [ebp + edx]  ; Образец
                        cmp                     bx, 0                           ; Конец образца
                        je                      @@BreakFound ; Найдено НЕ-ЧТО, т.к. достигнут конец образца
 ;  Динамический код  ;
@@SMC_CMP:              ; Сравнить с символом из буффера
                        cmp                     word ptr [12345678h + edx][eax], bx
                        jne                     @@BreakNFound
                        inc                     edx ; WideChar is 2byte size
                        inc                     edx
                        cmp                     dx, 64  ; Предосторожность
                        jb                      @@repeat
                        jmp                     @@BreakNFound
@@BreakFound:
                        mov                     [edi], ax  ; Сохранить смещение eax
                        add                     edi, 2
@@BreakNFound:
                        cmp                     esi, ecx ; Сравнить с концом списка
                        jb                      @@ScanRepeat
canComplete:
                        sub                     edi, pwhole
                        mov                    _packalg, 0
                        shr                     edi, 1
                        mov                    _Found, di   ;; сколько найдено    
                        mov                    _Lcount, edi ;; размер списка
                        mov                    _packalg, 0
                        mov                    _Isize, 2
                        ret
SieveWide               ENDP
;---------------------- ----------------------- ---------------------------
CODE                    ENDS
public                  ScanText
public                  ScanWide
public                  SieveText
public                  SieveWide
END
