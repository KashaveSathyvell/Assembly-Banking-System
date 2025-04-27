section .data
    welcomeMsg db "Welcome to the Banking System", 0xA, 0
    mainMenu db "1. Login", 0xA, "2. Create Account", 0xA, "3. Exit", 0xA, "Enter Option: ", 0
    mainMenuLen equ $ - mainMenu
    loginPrompt db "Enter Account Number: ", 0
    pinPrompt db "Enter PIN: ", 0
    loginSuccessMsg db "Login successful!", 0xA, 0
    loginFailMsg db "Login failed. Try again.", 0xA, 0
    loginFailLen equ $ - loginFailMsg
    newline db 0xA, 0
    accountsFile db "accounts.csv", 0

section .bss
    accountNumber resb 16     ; Buffer for account number
    pin resb 8               ; Buffer for PIN
    choice resb 2            ; Buffer for menu choice (digit + newline)
    temp resb 2              ; Temporary buffer for flushing input

section .text
    global _start
    extern validate_login, create_account
    ; Import functions from account_operations.asm
    extern display_menu, handle_menu_choice

_start:
    ; Display welcome message
    mov eax, 4
    mov ebx, 1
    mov ecx, welcomeMsg
    mov edx, 30          
    int 0x80

main_loop:
    ; Display main menu
    mov eax, 4
    mov ebx, 1
    mov ecx, mainMenu
    mov edx, mainMenuLen
    int 0x80
    
    ; Read user input
    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 2           ; Read digit + newline
    int 0x80
    
    ; Process user choice
    mov al, byte [choice]
    cmp al, '1'
    je login
    cmp al, '2'
    je createAcc
    cmp al, '3'
    je exit_program
    jmp main_loop

createAcc:
    call create_account
    jmp main_loop

login:
    ; Prompt for account number
    mov eax, 4
    mov ebx, 1
    mov ecx, loginPrompt
    mov edx, 22          
    int 0x80
    
    ; Read account number
    mov eax, 3
    mov ebx, 0
    mov ecx, accountNumber
    mov edx, 15         
    int 0x80
    
    ; Replace newline with null terminator
    mov edx, eax        
    dec edx             
    mov byte [accountNumber + edx], 0
    
    ; Prompt for PIN
    mov eax, 4
    mov ebx, 1
    mov ecx, pinPrompt
    mov edx, 11
    int 0x80
    
    ; Read PIN
    mov eax, 3
    mov ebx, 0
    mov ecx, pin
    mov edx, 7          ; Allow for 6-digit PIN + newline
    int 0x80
    
    ; Replace newline with null terminator
    mov edx, eax        
    dec edx             
    mov byte [pin + edx], 0
    
    ; Validate login
    push pin            ; Push PIN pointer
    push accountNumber  ; Push AccountID pointer
    call validate_login
    add esp, 8          ; Clean up the stack
    
    ; Check login result
    cmp eax, 0
    je login_fail
    
    ; Login successful
    mov eax, 4
    mov ebx, 1
    mov ecx, loginSuccessMsg
    mov edx, 19
    int 0x80
    
    ; Enter the main banking menu loop
    jmp banking_menu_loop

login_fail:
    mov eax, 4
    mov ebx, 1
    mov ecx, loginFailMsg
    mov edx, loginFailLen
    int 0x80
    jmp main_loop

banking_menu_loop:
    ; Display the main banking menu
    call display_menu
    
    push accountNumber   ; Pass account number as parameter
    push eax            ; Pass choice as parameter
    call handle_menu_choice
    add esp, 8          ; Clean stack
    
    ; Check the return value - if 6, logout
    cmp eax, 6
    je main_loop
    
    ; Otherwise, continue the banking menu loop
    jmp banking_menu_loop

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80
