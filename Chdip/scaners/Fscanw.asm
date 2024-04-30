.386
PAGE 255, 255
.model flat, PASCAL
INCLUDE extvars.inc
INCLUDE fscan.inc			; General Macros File


CODE                    SEGMENT PAGE "_TEXT"
                        nn = 0
                        nc = 0

;---------------------- ----------------------- ---------------------------
; Инициация динамического кода и переменных
InitWS                  proc
                        mov                     al, setOP
                        nm = 0;
                        cmp                     byte ptr [scc0 + 1], al
                        je                      noset
                        ; МОДИФИКАЦИЯ 96-х SETCC КОММАНД
                        REPT                    60h
                        setscc                  %nm
                        nm = nm + 1
                        ENDM
noset:                        
                        ret
InitWS                  endp
ALIGN 32                ; Выравнивание
;db                      8  dup (90h)
;---------------------- ----------------------- ---------------------------
ScanWORDS               PROC STDCALL uses eax ebx ecx edx esi edi ebp, buff:DWORD, rslt:DWORD, bsize:DWORD
                        ; Loading buffer info
			mov                     esi, buff  ; ebp + 08
                        mov                     edi, rslt  ; ebp + 0C
                        mov                     ecx, bsize ; ebp + 10
                        add                     ecx, esi        ; послед. адрес
                        mov                     savebp, ebp     ; Сохранение ebp
                        xor                     eax, eax
                        cmp                     dword ptr [dcode010][2], ecx
                        je                      nsave0
 	                ;  три самые тяжелыe комманды
			mov                     dword ptr [dcode010][2], ecx ; Модификация кода
nsave0:                        
                    	; очистка
			mov                     dword ptr [edi + 00h], eax
			mov                     dword ptr [edi + 04h], eax
                        mov                     ebp, dword ptr [ExampleMin]
;---------------------- ----------------------- ---------------------------

                        nn = 0
; ОСНОВНОЙ ЦИКЛ СКАНИРОВАНИЯ
scan:
                        xor                     ecx, [esi + 40h] ; Чижелая инструкця
                        ; Начало сравнений
                        INDEX = 0
                        REPT                    0Fh
                        compsetw                 a, 0
                        compsetw                 c, 10h
                        compsetw                 d, 20h
                        compsetw                 b, 30h
                        INDEX = INDEX + 1
                        ENDM
;---------------------- ----------------------- ---------------------------
                        INDEX = 0;
                        ; Чтение последних слов и смещение
                        compsetw                 a, 0Fh, 17        ; 16 middle bits - set
                        compsetw                 c, 1Fh            ; 16 high bits - set
                        compsetw                 d, 2Fh, 17
                        compsetw                 b, 3Fh,           ; Bank conflict !!
;=============== ДОУПАКОВКА МНОЖЕСТВ --------------------------------------------------
                        mov                      cx, ax    ; Терепь eax свободен, а ecx забит
                        mov                      bx, dx    ; тоже самое с ebx и edx
;---------------------- ----------------------- --------------------------
                        ; загрузка счетчика множеств
                        mov                     eax, [edi + 4] ; counter
                        xor                     ecx, -1
                        xor                     ebx, -1
                        xor                     edx, edx
                        add                     esi, 40h   ; Наращивание указателя src 1
;---------------------- ----------------------- ---------------------------
                        ; RLE PACKING
                        ; Проверка множеств
                        cmp                     [edi], ecx
                        je                      $+0Dh
;---------------------- ----------------------- ---------------------------
                        ; сохранение текущего счетчика (1)
                        mov                     [edi + 4], eax
                        ; cохранение множества
                        mov                     [edi + 8], ecx
                        ; сброс счетчика в 0
                        xor                     eax, eax
                        ; увеличение указателя dst
                        add                     edi, 8
nsave1:
                        ; инкремент счетчика (1)
                        inc                     eax
;---------------------- ----------------------- ---------------------------
                        ; проверка с след. множества
                        cmp                     ecx, ebx
                        je                      $+0DH
                        ; сохранение счетчика (2)
                        mov                     [edi + 4], eax
                        ; сохранение множества (2)
                        mov                     [edi + 8], ebx
                        ; сброс счетчика в 0
                        xor                     eax, eax
                        add                     edi, 8
nsave2:
                        inc                     eax
                        ; сохранение счетчика (2)
                        mov                     dword ptr [edi + 4], eax
                        ALIGN 2
dcode010:
                        cmp                     esi, 12345678h
                        ; общее сохранение счетчика
                        jb                      scan
                        ;// Context restoring
;---------------------- ----------------------- ---------------------------
; SCANING LOOP COMPLETE  - Цикл сканирования завершен
                        xor                     eax, eax
                        ; восстановление ebp
                        mov                     ebp, savebp
                        xor                     eax, eax        ; очистка eax
                        ; Последние множества - не нулевые
                        cmp                     ebx, 0
                        setne                   al
                        ; добавление к пределу = размер
                        lea                     edi, [edi + eax * 8]
                        sub                     edi, rslt        ; -= @rslt
                        ; преобразование размера в количество
                        shr                     edi, 3
                        ; Кол-во элементов (по 8 байт) архива
                        mov                     _isize, 8
                        mov                     _lcount, edi
                        mov                     _packalg, RLESET
                        ret
ScanWORDS               ENDP                   ; ScanDWORDS

ALIGN 16                
;---------------------- ----------------------- ---------------------------
SieveWORDS              PROC  STDCALL uses eax ebx ecx edx esi edi ebp,   buff:DWORD, setlst:DWORD, dst:DWORD, count:DWORD
; На входе только 32-битные множества (+ кол-во) 
; индексация осуществляется: esi@buff, ebx@setlst (src), edi@setlst(dst)
; данные в setlst - не сжаты, поэтому после пользования затираются
                        pushad
                        mov                     ebx, setlst       ; исходный архив
                        mov                     esi, buff
                        mov                     edi, dst          ; назначение (2-ная упаковка)
                        ; кол-во элементов списка множеств
                        mov                     ecx, count
                        shl                     ecx, 2          ; * 4, кол-во в размер
                        add                     ecx, ebx          ; предел
                        mov                     dword ptr [dcode011+2], ecx
                        xor                     eax, eax
                        mov                     savebp, ebp
                        mov                     dword ptr [edi + 4], eax
                        mov                     dword ptr [edi + 12], eax      ;; инициация
                        mov                     ebp, dword ptr [exampleMin]   ;; загрузка образца

;---------------------- ----------------------- ---------------------------
sieve:
                        mov                     dl, byte ptr [esi + 40h]
                        ; получение множества методами поиска
                        ; за итерацию проверяется 32 значения
                        n = 1
                        compsetw                 a, 00h
                        compsetw                 c, 10h   
                        REPT                    14
                        ; не оптимизированный код
                        compsetw                 a, n
                        o = n + 10h
                        compsetw                 c, o
                        n = n + 1
                        ENDM
                        compsetw                 a, 0Fh, 17
                        compsetw                 c, 1Fh, 1
                        ; совмещение множеств в ecx
                        mov                     cx, ax ; теперь в ecx - 32 битное множество
                        xor                     ecx, -1       
                        ; отсев результатов
                        and                     ecx, dword ptr [ebx]
                        xor                     eax, eax
                        add                     esi, 20h        ; cмещ. указателя данных
                        add                     ebx, 4          ; смещ. указателя источника
                        cmp                     dword ptr [edi], ecx
                        setne                   al
                        ; определение указателя
                        lea                     edi, [edi + eax * 8]
                        ; сохранение множества
                        mov                     dword ptr [edi], ecx
                        ; инкремент счетчика
                        add                     word ptr [edi + 4], 1
                        ; предварительная инициация счетчика
                        mov                     word ptr [edi + 12], 0
;---------------------- ----------------------- ---------------------------
dcode011:
                        cmp                     ebx, 12345678h
                        jb                      sieve
                        xor                     eax, eax
                        cmp                     ecx, 0
                        setne                   al
                        shl                     eax, 3          ; * 8
                        add                     edi, eax
                        ; восстановление стековых указателей
                        mov                     ebp, savebp
                        mov                     esi, setlst
                        sub                     edi, dst
                        shr                     edi, 3          ; div 8
                        ; размер элемента архива
                        mov                     _isize, 8
                        ; кол-во элементов архива
                        mov                     _lcount, edi
                        mov                     _packalg, RLESET 
                        popad
                        ret             
SieveWORDS              ENDP                    ; SieveDWORDS
;---------------------- ----------------------- ---------------------------
CODE                    ENDS
public          InitWS
public          ScanWORDS
public          SieveWORDS

END
