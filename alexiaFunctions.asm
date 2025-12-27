
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







;print
; moves cursor to the beginning of next line
; prints carriage return (0Dh) and line feed (0Ah)
; useful for formatting output neatly

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