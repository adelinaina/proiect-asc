; contains: sorting, bit counting, and display functions
; called from main program in citire.asm!!!


include student2.asm


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