assume cs:code, ds:data


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

    ;Mesaje: Calcul C + Rotiri 
    cuvant_C    dw 0
    msg_C       db 13, 10, ' Student 2: Calcul C', 13, 10, 'Cuvantul C (Hex): $'
    msg_rez     db 13, 10, ' Student 2: Rotiri (N=bit0+bit1) $'
    msg_elem    db 13, 10, ' Elem: $'
    msg_bin     db ' Bin: $'
    msg_hex_lbl db ' Hex: $'
    temp_byte   db 0
    N_rotire    db 0
    saved_cx    dw 0

    ; Variabile auxiliare pentru Student 3
    tempByte        db ?
    tempPosition    db ?
    rotatedArray    db 16 dup(?)
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
    
    ; daca e valid, treci la procesare
    jmp start_processing

bad_count:
    mov dx, offset msg_err
    mov ah, 09h
    int 21h
    jmp program_end

start_processing:
    call PRINT_NEWLINE
    
    ; calculeaza si afisează C + rotiri 
    call PROCESS_STUDENT2
    
    ; sorteaza si afisează rezultate: sirul sortat, octetul cu cel mai mare nr de 1, pozitia octetului
    call DISPLAY_SORTED_ARRAY
    
    call PRINT_NEWLINE
    mov dx, offset msg_press_key
    mov ah, 09h
    int 21h
    
    mov ah, 07h
    int 21h



program_end:
    mov ax, 4C00h
    int 21h

;student2
; Operațiile pe biți, calculul cuvântului C și rotirile

PROCESS_STUDENT2 proc
    ; Salvam registrii
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    cmp countBytes, 0       ; Verificam daca avem date
    je final_student2_proc  ; (je = Jump if Equal), sărim direct la final

    ;CALCULUL CUVANTULUI C
    mov word ptr cuvant_C, 0

    ;PAS 1: Bitii 0-3 (XOR intre capete)
    mov si, offset hexArray 
    mov al, [si]            ; Primul octet
    and al, 0Fh             ; Bitii 0-3(pastram doar ultimii 4 biti)
    ;Luam ultimul octet din sir 
    mov di, offset hexArray ; DI arata spre inceput
    mov bl, countBytes      ; Punem lungimea sirului in BL 
    mov bh, 0               
    add di, bx              ; Adunam lungimea la adresa 
    dec di                  ; Scadem 1 ( DI e ultimul element)
    mov bl, [di]            
    shr bl, 4               ; Bitii 4-7 mutati jos
    ;Facem XOR intre ele 
    xor al, bl              
    and al, 0Fh             
    or byte ptr cuvant_C, al ; Lipim rezultatul in 'cuvant_C'

    ; PAS 2: Bitii 4-7 (OR bitii 2-5)
    mov cx, 0
    mov cl, countBytes        
    mov si, offset hexArray   
    mov bl, 0                ; Adaugam rezultatele   
loop_or_proc:
    mov al, [si]
    shr al, 2                
    and al, 0Fh              ; Pastram doar 4 biti (bitii care erau original 2-5)        
    or bl, al               
    inc si
    loop loop_or_proc

    shl bl, 4                ; Muta rezultatul adunat in partea staga a octetului        
    or byte ptr cuvant_C, bl

    ; PAS 3: Bitii 8-15 (Suma modulo 256)
    mov cx, 0                
    mov cl, countBytes       ; Resetam contorul
    mov si, offset hexArray  ; Resetam adresa la inceput
    mov ax, 0                ; Resetam suma la 0 

loop_suma_proc:              ; bucla de suma 
    mov bl, [si]
    mov bh, 0
    add ax, bx              
    inc si
    loop loop_suma_proc

    mov byte ptr [cuvant_C + 1], al 

    ;Afisare C 
    mov dx, offset msg_C
    mov ah, 09h
    int 21h

    mov ax, cuvant_C
    call print_hex_word_s2     

    ;ROTIRI

    mov dx, offset msg_rez
    mov ah, 09h
    int 21h

    mov cx, 0
    mov cl, countBytes
    mov si, offset hexArray

loop_proc_rotiri:        ; Bucla principala de prelucrare 
    mov saved_cx, cx     ; Salvam contorul CX pentru ca functiile de afisare sa nu il strice 

    mov al, [si]            
    mov temp_byte, al    ; Salvam temporar octetul curent   

    ; Calcul N
    mov bl, al
    and bl, 1               ; bit 0 - luam ultimul bit
    mov bh, al
    shr bh, 1
    and bh, 1               ; bit 1 
    add bl, bh              ; N
    mov N_rotire, bl

    ; Rotire
    mov al, temp_byte 
    mov cl, N_rotire        
    cmp cl, 0               
    je afisare_rez_proc
    rol al, cl              

afisare_rez_proc:
    mov bl, al ; Punem rezultatul rotit in BL pentru afisare             
    
    ; Afisare interfata
    mov dx, offset msg_elem
    mov ah, 09h
    int 21h

    mov dx, offset msg_hex_lbl
    mov ah, 09h
    int 21h
    call print_hex_byte_s2    ; Afiseaza numarul in baza 16

    mov dx, offset msg_bin
    mov ah, 09h
    int 21h
    call print_binary_byte_s2 ; Afiseaza numarul in baza 2

    inc si                    ; Trecem la urmatorul numar din memorie 
    mov cx, saved_cx          ; Restauram contorul buclei pe care l-am salvat la inceput 
    loop loop_proc_rotiri

final_student2_proc:
    ; Scoatem de pe stiva in ordine inversa 
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PROCESS_STUDENT2 endp

;Afisare in binar 
print_binary_byte_s2 proc
    push ax
    push bx
    push cx
    push dx
    mov cx, 8    ; Un octet are 8 biti, deci repetam procesul de 8 ori            
    mov bh, bl   ; Lucram pe copie pentru a nu strica originalul          
print_bits_loop_s2:
    mov dl, '0'
    test bh, 10000000b  ; Testăm PRIMUL bit din stânga (bitul cel mai mare). 
                        ; 10000000b este o mască. Dacă bitul din BH e 0, rezultatul e 0.      
    jz bit_is_zero_s2
    mov dl, '1'         ; Dacă NU am sărit, înseamnă că bitul e 1. Schimbăm caracterul din DL în '1'
bit_is_zero_s2:
    mov ah, 02h
    int 21h
    shl bh, 1           ; Mutăm toți biții din BH la stânga cu o poziție.
                        ; Bitul 2 devine bitul 1. Așa aducem următorul bit in fata pentru testare.            
    loop print_bits_loop_s2
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_binary_byte_s2 endp

;Afisare in Hexazecimal
print_hex_byte_s2 proc
    push ax
    push bx
    push cx
    push dx
    mov dl, bl
    mov cl, 4  ; Mutam bitii cu 4 pozitii
    shr dl, cl ; Mutăm primii 4 biți la dreapta. 
               ; Practic, ștergem jumătatea de jos și aducem jumătatea de sus pe poziția cifrei.
    call print_digit_s2 
    mov dl, bl 
    and dl, 0Fh ; Păstrăm doar ultimii 4 biți. Primii 4 biți devin 0.
    call print_digit_s2 
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_hex_byte_s2 endp


print_digit_s2 proc
    cmp dl, 9 
    jbe is_digit_s2 ; (Jump if Below or Equal). Dacă e <= 9 (ex: 5), sărim direct la afișare.
    add dl, 7       ; Dacă am ajuns aici, numărul e > 9 (ex: 10, 11... 15).
                    ; În tabelul ASCII, între caracterul '9' și caracterul 'A' sunt 7 alte simboluri
                    ; Trebuie să adunăm 7 ca să sărim peste ele și să ajungem la alfabet.            
is_digit_s2:
    add dl, 30h     ; Adăugăm 30h (48 decimal). 
                        ; Codul ASCII pentru '0' este 30h.
                        ; 0 + 30h = Caracterul '0'.

    mov ah, 02h
    int 21h
    ret
print_digit_s2 endp

;Afisarea unui word 
print_hex_word_s2 proc
    push ax
    push bx
    mov bl, ah                ; Mutăm partea de sus în BL.
    call print_hex_byte_s2
    mov bl, al                ; Mutăm partea de jos în AL.
    call print_hex_byte_s2
    pop bx                    ; Restaurăm registrele
    pop ax
    ret
print_hex_word_s2 endp



;student3
; contains: sorting, bit counting, and display functions
; called from main program in citire.asm!!!
; sorts hexArray in descending order using bubble sort algorithm
; Input: hexArray contains bytes, countBytes has number of bytes
; Output: hexArray is sorted from largest to smallest value

SORT_DESCENDING_HEXARRAY proc
    ; save all registers we will modify
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; get number of bytes to sort
    mov cx, 0
    mov cl, countBytes
    
    ; check if we have at least 2 bytes to sort
    cmp cl, 2
    jb SORTING_COMPLETE  ; if 0 or 1 byte, nothing to sort
    
    dec cx  ; we need count-1 for comparisons (n-1 passes)
    
OUTER_SORT_LOOP:
    mov bx, 0     ; bx acts as a swap flag
    ; 0 = no swaps in this pass, 1 = at least one swap
    
    mov si, 0     ; si is the current index in the array
    
INNER_SORT_LOOP:
    ; load two consecutive bytes from hexArray
    mov al, hexArray[si]
    mov dl, hexArray[si+1]
    
    ; compare for descending order => larger first
    cmp al, dl
    jae NO_SWAP_NEEDED  ; if al >= dl => they are already in correct order
    
    ; swap the bytes (al < dl)
    mov hexArray[si], dl
    mov hexArray[si+1], al
    
    ; mark that a swap occurred
    mov bx, 1
    
NO_SWAP_NEEDED:
    ; move to next position in array
    inc si
    
    ; check if we reached the end of this pass
    cmp si, cx
    jb INNER_SORT_LOOP
    
    ; if no swaps occurred in this pass, array is sorted
    cmp bx, 0
    je SORTING_COMPLETE
    
    ; continue with next pass
    loop OUTER_SORT_LOOP
    
SORTING_COMPLETE:
    ; restore all saved registers
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
SORT_DESCENDING_HEXARRAY endp



; counts how many bits are set to 1 in a single byte
; used later to find which byte has the most 1 bits
; Input: al is the byte to analyze
; Output: cl is the number of bits set to 1 (max 8, min 0)

COUNT_BITS_IN_BYTE proc
    ; save registers we will modify
    push ax
    push bx
    
    ; start counter at 0
    xor cl, cl
    
    ; we need to check 8 bits
    mov bl, 8
    
COUNT_BITS_LOOP:
    ; shift right, moving least significant bit to carry flag
    shr al, 1
    
    ; check if the bit was 0 or 1
    jnc BIT_WAS_ZERO
    
    ; bit was 1, increment our counter
    inc cl
    
BIT_WAS_ZERO:
    ; decrement our bit counter
    dec bl
    
    ; if we still have bits to check, continue
    jnz COUNT_BITS_LOOP
    
    ; restore saved registers
    pop bx
    pop ax
    ret
COUNT_BITS_IN_BYTE endp



; finds the byte in hexArray with the highest number of 1 bits
; only considers bytes with more than 3 bits set to 1 (project rule!!!)
; Input: hexArray contains bytes, countBytes has count
; Output: si = position of byte (0-based index)
;         al = the byte value itself
;         cl = number of 1 bits in that byte

FIND_BYTE_WITH_MOST_BITS proc
    ; save registers we will modify
    push bx
    push dx
    push di
    
    ; start from first byte
    mov si, 0
    ; di will store the position of the best byte found
    mov di, 0
    ; cl will store the maximum bit count found
    mov cl, 0
    ; ch is temporary storage for current byte's bit count
    mov ch, 0
    
    ; get total number of bytes to check
    mov bx, 0
    mov bl, countBytes
    
    ; if no bytes, exit early
    cmp bl, 0
    je SEARCH_FINISHED
    
CHECK_EACH_BYTE:
    ; load current byte from hexArray
    mov al, hexArray[si]
    
    ; count how many 1 bits it has
    call COUNT_BITS_IN_BYTE
    ; save the result in ch
    mov ch, cl
    
    ; we only care about bytes with more than 3 bits set
    cmp ch, 3
    jbe SKIP_THIS_BYTE
    
    ; compare with current maximum
    cmp ch, cl
    jbe SKIP_THIS_BYTE  ; if not better, skip
    
    ; we found a new best byte
    ; update maximum bit count
    mov cl, ch
    ; update position of best byte
    mov di, si
    
SKIP_THIS_BYTE:
    ; move to next byte in array
    inc si
    
    ; check if we ve verified all bytes
    cmp si, bx
    jb CHECK_EACH_BYTE
    
SEARCH_FINISHED:
    ; prepare results
    mov si, di            ; position of byte with most bits
    mov al, hexArray[si]  ; the byte value itself
    ; cl already contains the bit count
    
    ; restore saved registers
    pop di
    pop dx
    pop bx
    ret
FIND_BYTE_WITH_MOST_BITS endp



; displays a single byte as two hexadecimal characters
; exp: if al = 3F, displays "3F" on screen
; uses DOS interrupt 21h, function 02h for character output

PRINT_HEX_BYTE proc
    ; save all registers we will modify
    push ax
    push bx
    push cx
    push dx
    
    ; keep a copy of the byte in bl
    mov bl, al
    
    ; print first hex character (first 4 bits)
    mov dl, bl
    shr dl, 4          ; shift right 4 bits to get high nibble
    call CONVERT_TO_HEX_CHAR  ; convert 0-15 to '0'-'9' or 'A'-'F'
    mov ah, 02h        ; DOS function: display character
    int 21h
    
    ; print second hex character (low = last 4 bits)
    mov dl, bl
    and dl, 0Fh        ; mask to keep only low 4 bits
    call CONVERT_TO_HEX_CHAR
    mov ah, 02h
    int 21h
    
    ; restore all saved registers
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT_HEX_BYTE endp



; converts a value 0-15 to its ASCII hex character
; 0-9 become '0'-'9', 10-15 become 'A'-'F'
; Input: dl = value to convert (0-15)
; Output: dl = ASCII character

CONVERT_TO_HEX_CHAR proc
    ; check if value is 0-9 or 10-15
    cmp dl, 9
    jbe IS_DIGIT_0_TO_9
    
    ; value is 10-15, convert to 'A'-'F'
    ; ASCII 'A' is 65, '0' is 48, so we need to add 7
    add dl, 7
    
IS_DIGIT_0_TO_9:
    ; add ASCII '0' (48) to get final character
    add dl, '0'
    ret
CONVERT_TO_HEX_CHAR endp




; moves cursor to the beginning of next line
; prints carriage return (0Dh) and line feed (0Ah)
; useful for formatting output pretty

PRINT_NEWLINE proc
    ; save registers we will modify
    push dx
    push ax
    
    ; carriage return - move cursor to start of line
    mov dl, 0Dh
    mov ah, 02h
    int 21h
    
    ; line feed - move cursor to next line
    mov dl, 0Ah
    mov ah, 02h
    int 21h
    
    ; restore saved registers
    pop ax
    pop dx
    ret
PRINT_NEWLINE endp



; displays a null-terminated string (terminated with '$')
; uses DOS interrupt 21h, function 09h
; Input: dx = address of string to display

PRINT_STRING proc
    ; save register we will modify
    push ax
    
    ; DOS function to display string (requires '$' terminator)
    mov ah, 09h
    int 21h
    
    ; restore saved register
    pop ax
    ret
PRINT_STRING endp



; displays all bytes in hexArray in hexadecimal format
; shows bytes separated by spaces for readability
; Input: hexArray contains bytes, countBytes has count

PRINT_HEX_ARRAY proc
    ; save registers we will modify
    push ax
    push cx
    push si
    
    ; get number of bytes to display
    mov cx, 0
    mov cl, countBytes
    ; start from first byte
    mov si, 0
    
    ; check if there are any bytes to display
    cmp cl, 0
    je HEX_DISPLAY_COMPLETE
    
DISPLAY_HEX_LOOP:
    ; load current byte
    mov al, hexArray[si]
    ; display it in hex
    call PRINT_HEX_BYTE
    
    ; check if this is the last byte
    ; if not, print a space separator
    mov ax, si
    inc ax  ; ax = current position + 1
    cmp al, countBytes
    je NO_SPACE_NEEDED
    
    ; print space between hex values
    mov dl, ' '
    mov ah, 02h
    int 21h
    
NO_SPACE_NEEDED:
    ; move to next byte
    inc si
    ; continue until all bytes displayed
    loop DISPLAY_HEX_LOOP
    
HEX_DISPLAY_COMPLETE:
    ; restore saved registers
    pop si
    pop cx
    pop ax
    ret
PRINT_HEX_ARRAY endp





; displays position as decimal number (0-15)
; Input: si = position (0-based index)
; Output: displays decimal number on screen

PRINT_POSITION_DECIMAL proc
    ; save registers we will modify
    push ax
    push bx
    push cx
    push dx
    
    ; if position is less than 10, just print digit
    cmp si, 10
    jb SINGLE_DIGIT
    
    ; for positions 10-15, print two digits
    ; first digit is always '1'
    mov dl, '1'
    mov ah, 02h
    int 21h
    
    ; calculate second digit
    mov ax, si
    sub al, 10
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    
    jmp POSITION_PRINTED
    
SINGLE_DIGIT:
    ; position is 0-9
    mov dl, si
    add dl, '0'
    mov ah, 02h
    int 21h
    
POSITION_PRINTED:
    ; restore saved registers
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT_POSITION_DECIMAL endp



; main function for Student 3: sorts array and displays results
; calls all necessary functions in correct order

DISPLAY_SORTED_ARRAY proc
    ; save registers
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; print message for sorted array
    mov dx, offset msg_sorted
    call PRINT_STRING
    
    ; sort the array in descending order
    call SORT_DESCENDING_HEXARRAY
    
    ; display sorted array in hexadecimal format
    call PRINT_HEX_ARRAY
    
    ; print newline for better formatting
    call PRINT_NEWLINE
    
    ; find byte with most bits set (more than 3 bits set)
    call FIND_BYTE_WITH_MOST_BITS
    ; now we have: si = position, al = byte value, cl = bit count
    
    ; save byte value for possible later use
    mov byte ptr [tempByte], al
    mov byte ptr [tempPosition], si
    
    ; print position message
    mov dx, offset msg_position
    call PRINT_STRING
    
    ; print the position as decimal number (0-15)
    call PRINT_POSITION_DECIMAL
    
    ; optional: print byte value in hex (daca vrei sa afisezi si valoarea)
    ; print newline first
    call PRINT_NEWLINE
    
    ; print hex message
    mov dx, offset msg_hex
    call PRINT_STRING
    
    ; print the byte value in hex
    mov al, byte ptr [tempByte]
    call PRINT_HEX_BYTE
    
    ; print final newline
    call PRINT_NEWLINE
    
    ; restore all saved registers
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DISPLAY_SORTED_ARRAY endp 



code ends
end start