.586
.model flat, STDCALL

include                 extvars.inc
.CODE
;---------------------- ----------------------- ---------------------------
ScanUnknow              proc uses eax ebx ecx edx esi edi ebp,   buff:DWORD, rslt:DWORD, bsize:DWORD
;---------------------- ----------------------- ---------------------------
;; Инициализация SMC
                        mov                     ax, cmpOp
                        cmp                     word ptr [DynaCmp], ax
                        je                      nset1
                        mov                     word ptr [DynaCmp], ax
nset1:
                        mov                     al, jmpOp
                        cmp                     byte ptr [DynaJmp], al
                        je                      nset2
                        mov                     byte ptr [DynaJmp], al
nset2:
                        ; Обязательная установка предела буффера
                        mov                     ecx, bsize
                        mov                     dword ptr [CmpLimit][1], ecx
                        ; Поиск неизвестного значение по условию
                        mov                     esi, dword ptr [_oldBuff]; Адрес старого подбуффера
                        xor                     eax, eax                ; Обнуление индекса
                        mov                     edx, buff     ; Адрес текущего буффера
                        mov                     edi, pwhole    ; Адрес прокси буффера результов
Repeat:
                        mov           ebx, dword ptr [esi][eax] ; ebx := OldBuffer [eax]
DynaCmp:
                        cmp           word ptr [edx][eax], bx   ; cmp NewBuffer [eax], (e)bx
DynaJmp:
                        je            TRUE
                        mov           [edi], ax                 ; Сохранить index
                        add           edi, 2
TRUE:
                        inc           eax
cmpLimit:
                        cmp           eax, 12345678h    ; Сравнить c Limit
                        jb            Repeat
                        mov           _Isize, 2
                        sub           edi, pwhole          ; offset of pointer
                        mov           _packalg, NPACKED ; simple offset list
                        shr           edi, 1
                        mov           _found, di        ; found = count
                        mov           _Lcount, edi
                        ret
;---------------------- ----------------------- ---------------------------
ScanUnknow              endp
;---------------------- ----------------------- ---------------------------
SieveUnknow             PROC uses eax ebx ecx edx esi edi ebp, buff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
;;;;; Инициация SMC
                        mov                     ax, cmpOp
                        cmp                     word ptr [DynaCmp2], ax
                        je                      noset1
                        mov                     word ptr [DynaCmp2], ax
                        mov                     word ptr [DynaCmp2], ax
noset1:
                        mov                     al, jmpOp
                        cmp                     byte ptr [DynaJmp2], al
                        je                      noset2
                        mov                     byte ptr [DynaJmp2], al
noset2:
                        mov                     edx, buff
                        ; Адрес исходного списка
                        mov                     esi, pprevd
                        mov                     ecx, count
                        shl                     ecx, 1            ;; двух-байтные смещения
                        add                     ecx, esi
                        mov                     dword ptr [CmpLim2][2], ecx ; Лимит списка
                         ; Адрес предыдущего буффера
                        mov                     ecx, dword ptr [_oldBuff]
                        ; Список результатов отсева
                        mov                     edi, pwhole

Repeat2:
                        movzx                   eax, word ptr [esi]  ; Загрузить
                        add                     esi, 2
                        mov                     ebx, dword ptr [ecx][eax] ; ebx = OldBuffer [eax]
DynaCmp2:
                        ; cmp NewBuffer [eax], (e)bx
                        cmp                     word ptr [edx][eax], bx
DynaJmp2:
                        jne                     CmpLim2
                        ; Сохранить смещение
                        mov                     [edi], ax
                        add                     edi, 2
CmpLim2:                ;        Проверка на конец списка
                        cmp                     esi, 12345678h ;
                        jb                      Repeat2
                        mov                     _packalg, NPACKED
                        sub                     edi, pwhole
                        mov                     _isize, 2
                        shr                     edi, 1
                        mov                     _Lcount, edi
                        mov                     _Found, di
                        ret
                        endp
;---------------------- ----------------------- ---------------------------
public                  ScanUnknow
public                  SieveUnknow
END