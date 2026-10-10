; rax — возвращаемое значение
; rcx — 4-й аргумент
; rdx — 3-й аргумент
; rsi — 2-й аргумент
; rdi — 1-й аргумент
; r8 — 5-й аргумент
; r9 — 6-й аргумент
; r10 — временный
; r11 — временный

section .data
newline_char: db 0xa
num_codes: db 0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39
out_str: dq 0,0 
        dd 0
        db 0 ; зарезервированая строка в 21 байт
; temp_data1: db 0
 temp_data2: db 0x30,0
temp_data3: db 0x31, 0x38, 0x34, 0x34, 0x36, 0x37, 0x34, 0x34, 0x30, 0x37, 0x33, 0x37, 0x30, 0x39, 0x35, 0x35, 0x31, 0x36, 0x31, 0x35,0
temp_data4: db 0x2d ,0x39, 0x32, 0x32, 0x33, 0x33, 0x37, 0x32, 0x30, 0x33, 0x36, 0x38, 0x35, 0x34, 0x37, 0x37, 0x35, 0x38, 0x30, 0x37, 0
in_str_buffer: times 65 dq 0 ; в буфере 260 байт
in_char_buffer: db 0 ; буфер для символа
section .text
global _start

_start:
;     ; mov rdi, 18446744073709551615 ; тест пройден 2^64 - 1 18_446_744_073_709_551_615
;     ; call print_uint
;     ; mov rdi, -9223372036854775808 ; тест пройден -2^63
;     ; mov rdi, -0 ; тест пройден
;     ; call print_int

;     ; mov rdi,temp_data1
;     ; mov rsi, temp_data2
;     ; call string_equals ; корректно
    ; mov rdi,temp_data2 ; парсит -0 как 0, 
    ; call parse_int
    ; mov rdi,rax
    ; push rdx
    ; call print_int
    ; pop rdi
    mov rdi, 0
    call print_int
    call exit

;     mov rdi,in_str_buffer
;     mov rsi, 5
;     call read_word
;     mov rdi, in_str_buffer
;     call print_string

;     mov rdi,in_str_buffer
;     mov rsi,out_str
;     mov rdx,10
;     call string_copy
;     mov rdi, out_str
;     call print_string

;     call exit


; Принимает код возврата и завершает текущий процесс
exit: 
    mov rax, 60
    xor rdi, rdi
    syscall    
    ret 

; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
    xor rax, rax ; очищаем rax

    .loop:
        cmp byte[rdi + rax],0 ; условие завершения
        je .end
        inc rax
        jmp .loop
    .end:
        ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
    call string_length
    mov rsi, rdi ; указываем на начало строки
    mov rdi, 1 ; stdout
    mov rdx, rax ; длина слова
    mov rax, 1 ; вывод
    syscall
    call print_newline
    ret

; Принимает код символа и выводит его в stdout
print_char:
    mov byte[out_str], dil ; записали символ в out_str
    mov rsi, out_str ; указываем на символ
    mov rdi, 1 ; stdout
    mov rdx, 1 ; длина 1 байт
    mov rax, 1
    syscall
    ret

; Переводит строку (выводит символ с кодом 0xA)
print_newline:
    mov rsi, newline_char ; записываем байт \n
    mov rdi, 1 ; stdout
    mov rdx, 1 ; длина 1 байт
    mov rax, 1
    syscall
    ret

; Выводит беззнаковое 8-байтовое число в десятичном формате 
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
    mov rax, rdi ; правая часть делимого
    push 0 ; счетчик делений, нужен для смещения
    mov r10, 10 ; для деления на 10
    .loop:
        xor rdx, rdx ; левая часть делимого, 0 тк не используется
        div r10 ; делим на 10
    
        mov rsi, [num_codes + rdx] ; записали ASCII код в rsi путем смещения        
        pop rdx ; сняли счетчик
        inc rdx
        push rsi ; положили ASCII символ
        push rdx ; вернули счетчик
        
        test rax, rax ; условие выхода, когда число стало \0
        je .end
        jmp .loop
    .end:
        pop rdx ; сняли счетчик
        test rdx, rdx ; если число - 0
        jne .end1
        .t1:
        mov rsi, [num_codes] ; записали ASCII 0 в rsi
        mov byte[out_str], sil ; записали символ 0 в память
        inc rdx ; чтобы корректно записалась нуль-строка
        jmp .end0
    .end1:
        mov r10, 0 ; теперь смещение
        mov rcx, rdx ; счетчик цикла
        .loop1:
            pop rsi ; сняли ASCII символ
            mov byte[out_str + r10], sil ; записали ASCII в память
            inc r10
            dec rcx
            test rcx,rcx
            jne .loop1
    .end0:
        mov rsi, 0 ; записали нуль строку
        mov byte[out_str + rdx], sil ; записали в память со смещением
        mov rdi, out_str
        call print_string
    ret

; Выводит знаковое 8-байтовое число в десятичном формате 
print_int:
    mov rax, rdi ; берем значение
    cmp rax, 0 ; проверка на отрицательность
    jge .after_sign
    mov rdi, 0x2d ; знак "-"
    push rax ; сохраняем данные
    call print_char ; пишем "-"
    pop rax

    mov rdx, rax ; копируем значение для сопоставления на -2^63
    neg rax 
    cmp rax,rdx ; сопоставляем на -2^63
    jne .after_sign
    jmp .end ; не изменяем rax, чтобы корректно напечаталось

    .after_sign:
        shl rax, 1 ; убираем значащий бит
        shr rax, 1 ; восстанавливаем число
    .end:
        mov rdi, rax 
        call print_uint ; тк число теперь положительное, то его можно печатать
    ret

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
    push rdi ; запоминаем 1й адрес 
    push rsi ; запоминаем 2й адрес 
    call string_length
    pop rsi ; сняли 2й адрес
    push rax ; длина 1й строки
    mov rdi, rsi ; перекладываем 2й адрес
    push rdi ; запоминаем 2й адрес
    call string_length
    
    mov rdi, rax ; длина 2й строки
    pop rsi ; сняли адрес 2го
    pop rdx ; сняли длину 1го
    pop rcx ; сняли адрес 1го
    
    cmp rdx,rdi ; проверка на длину
    je .same_len
    .zero:
        mov rdi, [num_codes] ; пишем 0, если число не совпадает по длине/по символу
        call print_char
        jmp .end
    
    .same_len:
        xor r8b,r8b ; смещение
        cmp rdx, 0 ; проверка ну пустую строку
        jne .loop
        .one:
            mov rdi,[num_codes + 1] ; выводим 1. строка считается равной при нулевой длине
            call print_char
            jmp .end
        .loop:
            mov r9b, [rcx + r8] ; в r9b хранится символ слова 1
            mov al, [rsi + r8] ; в al хранится символ слова 2
            cmp r9b,al ; проверка на равенство символов
            jne .zero 
            inc r8b ; добавляем смещение
            dec rdx ; здесь просто выбрал rdx как счетчик цикла
            test rdx,rdx ; проверка на конец цикла
            je .one ; переход сюда будет, если проблем не обнаружилось
            jmp .loop
    .end:
    call print_newline ; для корректного отображения, не вижу смысла записывать 0/1 в out_str и вызывать функцию на чтение строки
    ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
    mov rdi,0 ; stdin
    mov rsi, in_char_buffer ; указатель на буфер
    mov rdx, 1 ; длина строки
    mov rax, 0 ; sys_read
    syscall
    test rax,rax ; проверяем на EOF
    je .end
    mov al, byte[in_char_buffer] ; записываем символ, если не EOF
    .end:
    ret 

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале.
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор
read_word:
    xor rdx,rdx ; будет длиной слова 
    dec rsi ; уменьшаем размер буфера для \0
    ; lea rcx, [in_char_buffer - in_str_buffer] ; в rcx хранится максимальная длина буфера, тк in_char_buffer идет сразу за in_str_buffer  
    push rdi ; сохраняем адрес буфера
    .loop:
        push rsi ; сохраняем данные
        push rdx
        call read_char
        pop rdx ; снимаем данные
        pop rsi
        cmp al, 0x20 ; сравнение с " "
        je .check_if_start
        cmp al, 0x9 ; сравнение с "\t"
        je .check_if_start
        cmp al, 0xA ; сравнение с "\n"
        je .check_if_start
        .not_start:
            dec rsi ; уменьшаем счетчик цикла
            test rsi,rsi ; проверка на конец буфера
            je .zero
            pop rdi ; сняли адрес
            mov byte[rdi + rdx], al ; записываем в in_str_buffer символ из al
            push rdi ; сохраняем адрес
            inc rdx ; увеличиваем длину слова
            cmp al, 0xA ; сравнение с "\n" уже в конце
            je .correct_end
            test al,al ; проверка на EOF
            je .correct_end
            jmp .loop
        .check_if_start: ; здесь проверяется идут ли пробельные символы в начале строки или уже нет
            test rdx, rdx
            jne .not_start
            jmp .loop
        .zero:
            pop rax ; убираем уже мусор из стека
            xor rax,rax
            jmp .end
    .correct_end:
        pop rdi ; сняли адрес
        mov byte[rdi + rdx], 0 ; дописываем \0
        mov rax, rdi
    .end:
    ret
 

; Принимает указатель на \0 строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint: 
    push r10 ; сохраняем callee
    xor rdx, rdx ; rdx - смещение
    xor r8,r8 ; это длина числа
    xor rax, rax
    mov r10,10 ; для умножения на 10
    jmp .loop_first
    .loop:
        inc rdx ; увеличиваем смещение
    .loop_first:
        mov sil,[rdi+rdx] ; читаем символ в sil
        test sil,sil ; проверка на \0
        je .end0 ; выходим если \0
        cmp sil,0x30 ; сравниваем с символом "0"
        jb .not_num ; выходим, если меньше
        cmp sil,0x39 ; сравниваем с "9"
        ja .not_num ; выходим, если больше

        .digit_search: ; использует b-tree для поиска цифры
            .five:
                cmp sil,0x35
                jb .two 
                mov rcx, 5 ; rcx используем для получения цифры 
                je .after_btree
                ja .eight  
            .two:
                cmp sil,0x32
                jb .one
                mov rcx, 2
                je .after_btree
                ja .three
            .eight:
                cmp sil,0x38
                jb .seven
                mov rcx, 8
                je .after_btree
                mov rcx,9
                jmp .after_btree
            .one:
                cmp sil,0x31
                mov rcx,1
                je .after_btree
                mov rcx,0
                jmp .after_btree
            .three:
                cmp sil,0x33
                mov rcx,3
                je .after_btree
                mov rcx,4
                jmp .after_btree
            .seven:
                cmp sil,0x37
                mov rcx,7
                je .after_btree
                mov rcx,6
                jmp .after_btree
        .after_btree:
            cmp rcx,0 
            jne .not_start_zeros ; продолжаем, если символ не "0"
            test r8,r8 ; длина = 0
            je .loop ; повторяем, если символ это "0" и других символов не было

            .not_start_zeros:
            test rdx,rdx ; проверка на старшую цифру, чтобы записать ее для дальнейшей проверки
            jne .not_high_digit
            mov r9, rcx ; сохраняем старшую цифру

            .not_high_digit: 
            push rdx ; сохраняем длину 
            xor rdx,rdx ; обнуляем для умножения
            mul r10 ; умножаем все число на 10
            pop rdx ; снимаем длину
            add rax, rcx ; добавляем младшую цифру
            inc r8
            

            cmp rdx,20
            ja .not_num ; если количество цифр > 20, то число не поместится в 8 байт
            jb .loop
            cmp r9,1 ; убеждаемся, что старшая цифра 1 иначе число > 2^64-1
            jne .not_num ; выходим, если не равна 1
            ; здесь проверяется, что число например больше 0x1000 
            ; этого достаточно для проверки на корректность 
            cmp rax, 0x1000 
            jae .loop
            jmp .not_num

        .not_num:
            xor rdx,rdx
    .end:
    pop r10 ; снимаем callee
    mov rdx,r8
    ret

    .end0: ; здесь проверяется является ли число нулем
        test r8,r8 ; тк, длина не прибавляется, если не встречается отличная от 0 цифра, 
                   ; то надо проверить, что она = 0
        jne .end
        mov r8,1 ; в этом случае получается, что число = 0
        jmp .end




; Принимает указатель на \0 строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось
parse_int:
    push 0 ; флаг наличия "-"
    mov cl, [rdi] ; читаем первый символ из строки
    cmp cl, 0x2d ; сравниваем с "-"
    jne .call_uint
    inc rdi ; смещаем указатель с минуса
    pop rsi
    inc rsi ; ставим флаг в 1
    push rsi

    .call_uint:
        call parse_uint
        pop rsi 
        test rdx,rdx ; проверяем выдало ли ошибку
        je .end
        cmp rdx,19 ; если длина числа < 19, то все ок
        jb .correct_end ; ОК
        mov rcx,0x8000_0000_0000_0000 ; загружаем 2^63
        cmp rax,rcx ; сравниваем с 2^63
        jb .correct_end ; если меньше, то поставить "-" при необходимости
        ja .num_not_fits
        test rsi,rsi ; проверка на "-"
        jne .correct_end ; если число = 2^63 и есть "-", то ошибка
        .num_not_fits:
            xor rax,rax ; очищаем rax,rdx,rsi при ошибке
            xor rdx,rdx
            xor rsi,rsi
            jmp .end
        ; push rax
        ; .test:
        ; shl rax,1 ; сдвигаем и получаем 0x0, если это было 2^63
        ; test rax,rax
        ; pop rax
        ; je .correct_end

        .correct_end:
            add rdx, rsi
            test rsi,rsi
            je .end
            neg rax ; делаем отрицательным при необходимости
    .end:
    ret 

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
    xor rcx,rcx ; смещение/длина строки
    .loop:
        cmp rdx, rcx ; проверка на свободность буфера
        je .end
        mov r8b, [rdi + rcx] ; читаем символ
        mov [rsi + rcx], r8b ; пишем символ в буфер
        inc rcx
        test r8b,r8b
        je .end ; встретился \0
        jmp .loop
        .end: 
            mov rax,rcx
    ret
