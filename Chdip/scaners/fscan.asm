locals
.386
.model flat, STDCALL
;---------------------- ----------------------- ---------------------------
CODE                    SEGMENT PAGE "_TEXT"
;---------------------- ----------------------- ---------------------------
; Внешние переменные
include                 extvars.inc
ALIGN                   32
;---------------------- ----------------------- ---------------------------
PackRLE                 proc uses eax ebx ecx edx esi edi, src:DWORD, dst:DWORD, count:DWORD
; Упаковка простого списка множеств в RLE список множеств ;
;---------------------- ----------------------- ---------------------------
                        mov                     savebp, ebp
                        mov                     esi, src        ; источник
                        mov                     ecx, count      ; количество
                        mov                     edi, dst        ; приемник
                        shl                     ecx, 2          ; size = count * 4
                        add                     ecx, esi        ; предел
                        mov                     dword ptr [smc_cmp0][2], edx
                        xor                     ebp, ebp        ; количество найденых
                        mov                     _Found, bp
                        xor                     ecx, ecx
                        mov                     ebx, [esi]
                        mov                     [edi], ebx ; нолмалное значение множества
;---------------------- ----------------------- ---------------------------
packloop:       ; ЦИКЛ УПАКОВКИ МНОЖЕСТВ ==================================
                        add                     esi, 4     ; сместить указатель
                ; проверка на то что быть может, в месте назначения
                        cmp                     dword ptr [edi], ebx
                        je                      NoSave  ; значения эквиваленты
                        xor                     eax, eax       ; Очистка eax
                        test                    ebx, ebx       ; сравнить с 0
                        jz                      NoSave         ; 0 не сохранять
                        ; Сохранение характеристики предыдущего элемента
                        mov                     dword ptr [edi + 4], ecx ; сохранение смещения и количества
                        ; Сохранение МНОЖЕСТВА текущего элемента
                        mov                     dword ptr [edi + 8], ebx
                        add                     edi, 8         ; размер элемента упаковки
;---------------------- ----------------------- ---------------------------
;  РАСЧЕТ КОЛИЧЕСТВА СМЕЩЕНИЙ В СОХРАНЕНОМ МНОЖЕСТВЭ
                        REPT                    32
                        shr                     ebx, 1         ; выдвинуть бит
                        adc                     al, 0          ; Добавить бит
                        ENDM
;---------------------- ----------------------- ---------------------------
                        xor                     cx, cx         ; очистить count`er
NoSave:
                        add                     ebp, eax       ; Счетчик значений += set.founds
                        add                     ecx, 200001h   ; увеличить кол-во & смещение
;---------------------- ----------------------- ---------------------------
smc_cmp0:
                        cmp                     esi, 12345678h
                        mov                     ebx, [esi]    ; загрузить след. множество                        
                        jb                      packloop
                        mov                     _Found, bp      ; кол-во значений
                        mov                     ebp, savebp
                        mov                     [edi + 4], cx   ; сохранить еще раз количество
                        sub                     edi, dst        ; смещение указателя приемника
                        mov                     _packalg, RLESETP  ; алгоритм упаковки
                        shr                     edi, 3             ; делить на 8!
                        mov                     _Isize, 8          ; размер элемента
                        mov                     _Lcount, edi       ; запомнить кол-во элементов
                        ret
;---------------------- ----------------------- ---------------------------
PackRLE                 endp
ALIGN                   32
;---------------------- ----------------------- ---------------------------
; подсчет количества еденичных бит и доупаковка архива
OverPack                proc  uses eax ebx ecx edx esi edi, src:DWORD, count:DWORD
                        mov                     savebp, ebp
                        mov                     esi, src
                        mov                     edx, count
                        shl                     edx, 3         ; в размер = count * 8
                        add                     edx, esi
                        mov           dword ptr [smc_cmp][2], edx       ; Предел данных
                        xor                     ebp, ebp       ; Счетчик значений
                        xor                     ecx, ecx       ; Смещение в внутри буффера
                        mov                     edi, esi       ; указатель dst = src
cmplp:
                        mov                     ebx, [esi + 0] ; загрузка множества
                        ; Загрузка количества
                        mov                     cx, word ptr [esi + 4]
                        test                    ecx, ecx
                        jz                      skipall        ; пропуск по нулю
;---------------------- ----------------------- ---------------------------
                        test                    ebx, ebx       ; проверка на нулевое множество
                        jz                      skipcalc       ; не считать биты
                        mov                     [edi + 0], ebx
                        ; сохранение счетчика и смещения
                        mov                     [edi + 4], ecx
                        add                     edi, 8         ; инкремент @dst
;---------------------- ----------------------- ---------------------------
                        xor                     eax, eax       ; Очистка eax
                        ; подсчет 32 бит значений
                        REPT                    32
                        shr                     ebx, 1    ; выдвинуть бит
                        adc                     al, 0     ; Добавить бит
                        ENDM
                        ; Сейчас в аl количество еденичных бит
;---------------------- ----------------------- ---------------------------
                        ; умножение на количество множеств (масштабирование)
                        mul                     cx
                        add                     ebp, eax   ; Счетчик значений
skipcalc:
                        ; edx = count
                        movzx                   edx, cx     ; размер смещение
                        mov                     eax, ecx    ; запомнить количество
                        ; rep count * 32 to hi word
                        shl                     edx, 21
                        add                     ecx, edx     ; смешение
skipall:
                        ; Инкремент 8 байт
                        add                     esi, 8     ; след. элемент
smc_cmp:                        
                        cmp                     esi, 12345678h
                        jb                      cmplp
;---------------------- ----------------------- ---------------------------
; Цикл подсчета завершен
                        mov                     cx, ax     ; количество
                        mov                     _found, bp ; сохранить значение
                        xor                     eax, eax
                        mov                     [edi + 00h], ebx ; множество
                        mov                     [edi + 04h], ecx ; counter + offset
                        ; Исключительно для визуальной отладки
                        mov                     [edi + 08h], eax
                        mov                     [edi + 0Ch], eax
                        mov                     ebp, savebp
                        sub                     edi, src          ; вычесть начало
                        mov                     _packalg, RLESETP
                        shr                     edi, 3            ; размер в элементах (/8)
                        mov                     _Isize, 8         ; размер элемента
                        mov                     _lcount, edi      ; реальное количество
                        ret
                        endp
;---------------------- ----------------------- ---------------------------
; распаковщик архива на множества, по сути заполнитель памяти однородными значениями
; эффективно работать будет лишь, когда количество распакованных данных не превышает
; размер кэшей обоих уровней. При размере обрабатываемого блока 64К - размер данных 8К.
ALIGN                   32
UnpackRLE               proc                    src:DWORD, dst:DWORD, count:DWORD
                        pushad
                        mov                     esi, src
                        mov                     edi, dst
                        mov                     ecx, count
                        shl                     ecx, 3
                        add                     ecx, esi    ; получение предела
                        mov                     dword ptr [dcode012 + 2], ecx
                        xor                     ebp, ebp
                        xor                     edx, edx
unpack:
                        mov                     eax, dword ptr [esi]
                        ; Количество повторений
                        movzx                   ecx,  word ptr [esi + 4]
                        or                      ecx, ecx
                        jz                      skipit                     
                        ; Предварительное смещение в буффере
                        movzx                   ebx,  word ptr [esi + 6]
                        ; 1 index = 32 bytes (if set decoded)
                        shr                     ebx, 5
                        cmp                     ebx, edx
                        je                      fill
fill0:
                        mov                     [edi + edx * 4], ebp
                        add                     edx, 1
                        cmp                     edx, ebx
                        jb                      fill0
                        ;Выборка 32 - битного множества
fill:
                        ; Заполнение памяти значениями
                        mov                     [edi + edx * 4], eax
                        add                     edx, 1
                        sub                     ecx, 1
                        jnz                     fill
skipit:
                        add                     esi, 8
dcode012:
                        cmp                     esi, 12345678h 
                        jb                      unpack
                        xor                     eax, eax
                        mov                     _Lcount, edx  ; запомнить размер распакованных данных
                        mov                     [edi + edx * 4 +  4], eax
                        mov                     _packAlg, SETPACK
                        popad
                        ret                     ; выход из функцы
UnpackRLE               endp
CODE                    ENDS
;---------------------- ----------------------- ---------------------------
public                  OverPack
public                  PackRLE
public                  UnpackRLE

END
