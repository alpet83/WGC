.386
locals
.model flat, STDCALL
;---------------------- ----------------------- ---------------------------
data                    segment public ".DATA"
savesp                  dd              ?
saveofs                 dd              ?
data                    ends
;---------------------- ----------------------- ---------------------------
CODE                    SEGMENT PAGE "_TEXT"
; Алгоритм поиска чисел начинающихся с чисел образца.
; Внешние переменные
include                 extvars.inc
;---------------------- ----------------------- ---------------------------
ScanFirstDig            PROC uses eax ebx ecx edx esi edi, buff:DWORD, rslt:DWORD, bsize:DWORD
;---------------------- ----------------------- ---------------------------
                        mov                     edi, pwhole ; proxy destination
                        mov                     esi, buff
                        mov                     ecx, bsize
                        ; Настройка SMC
                        mov                     eax, dword ptr [szmask]
                        mov                     dword ptr [masking][1], eax ; Запись маски
                        mov                     ebx, dword ptr [ExampleMin] ; Образец
                        and                     ebx, eax ; маскировать образец
                        mov                     dword ptr [CmpLimit][2], ecx   ; Запись лимита
                        mov                     passed, 0
                        mov                     ecx, 10
                        push                    ebp
;---------------------- ----------------------- ---------------------------
; Поиск числового значения начинающегося на цифры образца
                        xor                     ebp, ebp ; Обнуление индекса
Repeat:
Loadval:   ;  Загрузка сравниваемоего значения из подбуффера
                        mov                     eax, [esi + ebp]
masking:   ;  Маскировка значения (приведение к размеру)
                        and                     eax, 1FFFFFFFh ; Это значение должно измениться
;---------------------- ----------------------- ---------------------------
; Прямая проверка и т. д.
div_cycle:
                        cmp                     eax, ebx         ; сравнение с образцом
                        je                      @SaveOffs
                        jb                      @EndTest         ; число меньше образца
                        xor                     edx, edx         ; делится пара чисел (:)
                        div                     ecx              ; делить на 10
                        jmp                     div_cycle
@SaveOffs:
                        mov                     [edi], bp         ; Save offset
                        add                     edi, 2
@EndTest:
                        add                     ebp, 1
CmpLimit: ;  Сравнение с лимитом подбуффера
                        cmp                     ebp, 12345678h ;  Это динамический код  ;
                        jb                      Repeat
                        pop                     ebp
                        sub                     edi, pwhole
                        mov                     _packalg, NPACKED
                        mov                     _Isize, 2
                        shr                     edi, 1
                        mov                     _found, di
                        mov                     _Lcount, edi
                        mov                     passed, 1
                        ret
ScanFirstDig            ENDP
;---------------------- ----------------------- ---------------------------
SieveFirstDig           PROC uses eax ebx ecx edx esi edi, buff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
                        mov                     savebp, ebp
                        mov                     esi, pprevd ; список смещений для отсева
                        mov                     edi, pwhole ; список для результатов
                        mov                     ecx, count
                        mov                     eax, dword ptr [szmask]      ; masking
                        shl                     ecx, 1          ; count * 2
                        add                     ecx, esi
; Настройка SMC
                        mov                     dword ptr [@svmask][1], eax ; Задание размера маскировкой (2)
                        mov                     dword ptr [@EndTest2][2], ecx ; Лимит списка смещений (4)
                        mov                     edx, buff   ; указатель на новые данные
                        mov                     ebx, dword ptr [ExampleMin]  ; ecx = Example
                        mov                     ecx, 10     ; делитель = 10
                        mov                     passed, 0   ; debug
                        mov                     ebp, edx    ; @buff



@SieveLoop:
; Загрузка смещения отсеиваемого значения
                        movzx                   eax, word ptr [esi]
                        add                     esi, 2
                        mov                     eax, dword ptr [ebp][eax] ; считать значение
@svmask: ; SMC, masking loaded value
                        and                     eax, 12345678h ; chto szmask
@TestIt:
                        cmp                     eax, ebx     ; сравнить с образцом
                        je                      @SaveIt      ; сохранить поскольку равно
                        jb                      @EndTest2    ;  Уже меньше - не подходит
; ===================== Деление на образец с получением частного/остатка
@Div10:
                        xor                     edx, edx     ; Подготовка к делению edx:eax / example
                        div                     ecx          ; divide for example
                        jmp                     @TestIt
@SaveIt:
                        movzx                   eax, word ptr [esi - 2]
                        mov                     [edi], ax
                        add                     edi, 2    ; Сохранить индекс (ax)
@EndTest2: ; SMC: immediate changed to limit
                        cmp                     esi, 12345678h  ; 12345678h chto ListLimit
                        jb                      @SieveLoop
                        mov                     ebp, savebp
                        sub                     edi, pwhole
                        mov                     _Isize, 2
                        mov                     _packalg, 0
                        shr                     edi, 1
                        mov                     _found, di
                        mov                     _Lcount, edi
                        mov                     passed, 2
                        ret
                        ENDP
;---------------------- ----------------------- ---------------------------
CODE                    ENDS
public                  ScanFirstDig
public                  SieveFirstDig
END