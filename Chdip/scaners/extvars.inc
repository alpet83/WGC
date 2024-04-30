; Внешние переменные
extrn                   pascal cmpOP:WORD               ; операция сравнения
extrn                   pascal setOP:BYTE               ; setcc операция
extrn                   pascal jmpOP:BYTE               ; jcc операция
extrn                   pascal ExampleMin:QWORD         ; минимальное знач. образца
extrn                   pascal ExampleMax:QWORD         ; максимально знач. образца
extrn                   pascal ExampleText:DWORD        ; Указатель на текстовый образец 
extrn                   pascal szmask:QWORD             ; маскировка (для безразличия к типу)
extrn                   pascal _packalg:DWORD           ; алгоритм упаковки
extrn                   pascal _found:WORD             ; кол-во найденых значений
extrn                   pascal _vsize:BYTE              ; размер образца в байтах
extrn                   pascal _isize:BYTE              ; размер элемента архива
extrn                   pascal _lcount:DWORD            ; кол-во элементов архива
extrn                   pascal _oldBuff:DWORD           ; указатель на старый буффер
extrn                   pascal temp:QWORD               ; Для DWORD
extrn                   pascal savebp:DWORD             ; EBP Save
extrn                   pascal pwhole:DWORD             ; StoreHouse for unpacked functions
extrn                   pascal pprevd:DWORD             ; Source for unpacked functions
extrn                   pascal passed:DWORD             ; Для отладки
extrn                   pascal masksv:DWORD             ; Save Mask intermediate
extrn                   pascal old_op:DWORD             ; Old Operation
NPACKED = 0   ; Неупакованные смещения по 16 бит
SETPACK =  4; ; Простые множества по 32 бита
RLESET  = 16; ; Множества упакованные RLE
RLESETP = 32; ; RLESET, с сохранением смещений, но без нулевых множеств


