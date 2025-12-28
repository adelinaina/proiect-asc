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
