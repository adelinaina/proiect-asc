assume cs:code, ds:data
include alexiaFunctions.asm

data segment

    msg_input db 'Introduceti octetii in hex(8-16 valori): $'
    msg_err db 13,10,'Numar invalid de octeti! $'


    ;buffer dos pentru citire(AH = 0Ah)
    inputBuf db 50
             db 0
             db 50 dup(?)

    hexArray db 16 dup(?) ;sirul de octeti convertiti
    countBytes db 0 ;numarul de octeti cititi

    ;mesaje pentru afisari necesare
    msg_sorted      db 'Sirul sortat: $'
    msg_position    db 'Pozitia octetului: $'
    msg_space  db '  $'
    msg_binary      db 'In binar: $'
    msg_hex         db 'In hex: $'
    msg_press_key   db 'Apasa orice tasta... $'

data ends

code segment
start:
    mov ax, data
    mov ds, ax

    ;afisare mesaj
    mov dx, offset msg_input
    mov ah, 09h
    int 21h

    ;citire sir cu buffer
    mov dx, offset inputBuf
    mov ah, 0Ah
    int 21h

    ;initializare pointeri
    mov si, offset inputBuf + 2 ;caracterele citite
    mov di, offset hexArray ;destinatie octeti
    xor cx, cx ;contor octeti
read_loop:

;sarim peste spatii

skip_spaces:

    mov al, [si]
    cmp al, ' '
    jne check_end
    inc si
    jmp skip_spaces

check_end:
    
    ;verificare sfarsit de linie(enter)
    cmp al, 0Dh
    je end_read

    ;conversia primei cifre hex(jumatatea superioara de byte)
    mov al, [si]
    cmp al, '0'
    jb invalid 
    cmp al, '9'
    jbe digit1
    cmp al, 'A'
    jb invalid
    cmp al, 'F'
    ja invalid
    sub al, 'A'
    add al, 10
    jmp got1

digit1:

    sub al, '0'

got1:

    shl al, 4
    mov bl, al
    inc si

    ;conversia celei de-a doua cifre hex(jumatatea inferioara de byte)
    mov al, [si]
    cmp al, '0'
    jb invalid
    cmp al, '9'
    jbe digit2
    cmp al, 'A'
    jb invalid
    cmp al, 'F'
    ja invalid
    sub al, 'A'
    add al, 10
    jmp got2

digit2:

    sub al, '0'

got2:

    or bl, al ;combinarea jumatatilor
    inc si

    cmp cx, 16 ;limitare la maxim 16 octeti
    jae end_read

    ;salvare octet
    mov [di], bl
    inc di
    inc cx
    jmp read_loop

invalid:

    xor al, al
    inc si
    jmp read_loop

end_read:

    mov countBytes, cl

    ;validare valori 8-16
    cmp cl, 8
    jb bad_count
    cmp cl, 16
    ja bad_count
    jmp exit

bad_count:

    mov dx, offset msg_err
    mov ah, 09h
    int 21h
    

exit:

    mov ax, 4C00h
    int 21h

code ends
end start











;code alexia