.model small
.stack 100h

.data
    msg1 db 'Enter a number: $'
    msg2 db 13,10,'You entered: $'
    msg3 db 13,10,'Invalid input!$'
    
    ; Buffer structure for DOS function 0Ah:
    ; First byte: maximum characters to read
    ; Second byte: number of characters actually read (filled by DOS)
    ; Third byte onward: actual characters
    buffer db 255        ; Max length (255 chars)
           db ?          ; Actual length (filled by DOS)
           db 255 dup(?) ; Actual input
    sign_flag db 0       ; 0=positive, 1=negative

.code
main proc
    ; Initialize data segment
    mov ax, @data
    mov ds, ax
    
    ; Display prompt
    mov ah, 09h
    lea dx, msg1
    int 21h
    
    ; Read string using DOS function 0Ah
    mov ah, 0Ah
    lea dx, buffer
    int 21h
    
    ; Validate input
    call validate_input
    
    ; Check if valid
    cmp al, 1
    je valid
    
    ; Invalid input - show error
    mov ah, 09h
    lea dx, msg3
    int 21h
    jmp exit
    
valid:
    ; Display output message
    mov ah, 09h
    lea dx, msg2
    int 21h
    
    ; Display the number
    call display_number
    
exit:
    ; Exit to DOS
    mov ah, 4Ch
    int 21h
main endp

;===========================================
; VALIDATE_INPUT - Validates the input string
; Input: buffer with string
; Output: AL = 1 if valid, AL = 0 if invalid
;===========================================
validate_input proc
    ; Reset sign flag
    mov sign_flag, 0
    
    ; Get actual length
    mov cl, buffer + 1
    mov ch, 0
    cmp cx, 0
    je invalid_input     ; Empty string is invalid
    
    ; Point to start of input
    lea si, buffer + 2
    
    ; Check first character
    mov al, [si]
    cmp al, '-'
    jne check_first_digit
    
    ; It's negative
    mov sign_flag, 1
    inc si
    dec cx
    jz invalid_input     ; Only '-' is invalid
    
check_first_digit:
    ; First character must be digit
    mov al, [si]
    call is_digit
    jnz invalid_input
    
    ; Check rest of characters
check_loop:
    dec cx
    jz valid_input       ; End of string
    
    inc si
    mov al, [si]
    call is_digit
    jz check_loop        ; Continue if digit
    
    ; Invalid character found
    jmp invalid_input
    
valid_input:
    mov al, 1
    ret
    
invalid_input:
    mov al, 0
    ret
validate_input endp

;===========================================
; IS_DIGIT - Checks if AL is a digit '0'-'9'
; Input: AL = character
; Output: ZF = 1 if digit, ZF = 0 if not
;===========================================
is_digit proc
    cmp al, '0'
    jb not_digit
    cmp al, '9'
    ja not_digit
    cmp al, al          ; Sets ZF=1
    ret
not_digit:
    test al, al         ; Sets ZF=0
    ret
is_digit endp

;===========================================
; DISPLAY_NUMBER - Displays the validated number
; Input: buffer with string, sign_flag
;===========================================
display_number proc
    ; Display sign if negative
    cmp sign_flag, 1
    jne display_positive
    
    ; Display minus sign
    mov ah, 02h
    mov dl, '-'
    int 21h
    
display_positive:
    ; Get string length
    mov cl, buffer + 1
    mov ch, 0
    
    ; Point to start of string
    lea si, buffer + 2
    
    ; Skip minus sign if negative
    cmp sign_flag, 1
    jne display_loop
    inc si
    dec cx
    
display_loop:
    ; Check if we've displayed all characters
    jcxz display_done
    
    ; Display character
    mov ah, 02h
    mov dl, [si]
    int 21h
    
    ; Next character
    inc si
    loop display_loop
    
display_done:
    ret
display_number endp

end main