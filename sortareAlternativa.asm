; SHELL SORT – sortare descrescatoare pentru hexArray
; Input:  hexArray – vectorul de octeti
;         countBytes – numarul de elemente
; Output: hexArray sortat descrescator

SHELL_SORT_HEXARRAY proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov cx, countBytes
    cmp cx, 2
    jb SHELL_DONE        ; daca avem 0 sau 1 element, nu sortam

    ; gap initial = countBytes / 2
    mov ax, cx
    shr ax, 1
    mov bx, ax           ; BX = gap

SHELL_GAP_LOOP:
    cmp bx, 0
    je SHELL_DONE

    mov si, bx           ; incepem de la indexul = gap

SHELL_INSERT_LOOP:
    mov al, hexArray[si] ; elementul curent
    mov di, si

SHELL_SHIFT_LOOP:
    sub di, bx           ; di = di - gap
    cmp di, 0
    jb SHELL_INSERT_DONE ; daca am iesit din vector, ne oprim

    mov dl, hexArray[di] ; elementul cu gap in urma

    ; sortare DESCRESCATOARE → daca dl < al, mutam dl in fata
    cmp dl, al
    jae SHELL_INSERT_DONE

    ; mutam elementul mai mic in pozitia curenta
    add di, bx
    mov hexArray[di], dl
    sub di, bx
    jmp SHELL_SHIFT_LOOP

SHELL_INSERT_DONE:
    add di, bx
    mov hexArray[di], al ; inseram elementul la pozitia corecta

    inc si
    cmp si, countBytes
    jb SHELL_INSERT_LOOP

    ; gap = gap / 2
    shr bx, 1
    jmp SHELL_GAP_LOOP

SHELL_DONE:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
SHELL_SORT_HEXARRAY endp
