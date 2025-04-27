section .data
    promptName db "Enter Name (letters only): ", 0
    promptNameLen equ $ - promptName
    promptID db "Enter Account ID (numbers only): ", 0
    promptIDLen equ $ - promptID
    promptPIN db "Enter PIN (numbers only): ", 0
    promptPINLen equ $ - promptPIN
    promptBalance db "Enter Initial Balance: ", 0
    promptBalanceLen equ $ - promptBalance
    successMsg db "Account created successfully!", 10, 0
    successMsgLen equ $ - successMsg
    newline db 10, 0

section .bss
    name resb 51       ; Buffer for Name input 
    accountID resb 10  ; Buffer for Account ID input 
    pin resb 10        ; Buffer for PIN input 
    initialBalance resb 10 ; Buffer for Initial Balance input

section .text
    global create_account
    extern write_to_file

create_account:
    ; Preserve registers
    push ebp
    mov ebp, esp
    ; Prompt for Name
    mov eax, 4
    mov ebx, 1
    mov ecx, promptName
    mov edx, promptNameLen
    int 0x80
    ; Read Name
    mov eax, 3
    mov ebx, 0
    mov ecx, name
    mov edx, 50
    int 0x80
    ; Replace newline with null terminator
    mov ebx, eax        ; Number of bytes read
    dec ebx             ; Adjust for newline character
    mov byte [name + ebx], 0
    ; Prompt for Account ID
    mov eax, 4
    mov ebx, 1
    mov ecx, promptID
    mov edx, promptIDLen
    int 0x80
    ; Read Account ID
    mov eax, 3
    mov ebx, 0
    mov ecx, accountID
    mov edx, 9
    int 0x80
    ; Replace newline with null terminator
    mov ebx, eax        ; Number of bytes read
    dec ebx             ; Adjust for newline character
    mov byte [accountID + ebx], 0
    ; Prompt for PIN
    mov eax, 4
    mov ebx, 1
    mov ecx, promptPIN
    mov edx, promptPINLen
    int 0x80
    ; Read PIN
    mov eax, 3
    mov ebx, 0
    mov ecx, pin
    mov edx, 9
    int 0x80
    ; Replace newline with null terminator
    mov ebx, eax        ; Number of bytes read
    dec ebx             ; Adjust for newline character
    mov byte [pin + ebx], 0
    ; Prompt for Initial Balance
    mov eax, 4
    mov ebx, 1
    mov ecx, promptBalance
    mov edx, promptBalanceLen
    int 0x80
    ; Read Initial Balance
    mov eax, 3
    mov ebx, 0
    mov ecx, initialBalance
    mov edx, 9
    int 0x80
    ; Replace newline with null terminator
    mov ebx, eax        ; Number of bytes read
    dec ebx             ; Adjust for newline character
    mov byte [initialBalance + ebx], 0
    ; Push parameters in reverse order (initialBalance, pin, accountID, name)
    push initialBalance ; Initial Balance pointer
    push pin            ; PIN pointer
    push accountID      ; Account ID pointer
    push name           ; Name pointer
    call write_to_file  ; Call the function
    add esp, 16         ; Clean up stack
    ; Display success message
    mov eax, 4
    mov ebx, 1
    mov ecx, successMsg
    mov edx, successMsgLen
    int 0x80
    ; Restore stack frame
    mov esp, ebp
    pop ebp
    ret
