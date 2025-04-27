section .data
    ; Menu messages
    menuTitle db "===== Banking System Menu =====", 10, 0
    menuTitleLen equ $ - menuTitle
    menuOption1 db "1. Check Balance", 10, 0
    menuOption1Len equ $ - menuOption1
    menuOption2 db "2. Deposit Funds", 10, 0
    menuOption2Len equ $ - menuOption2
    menuOption3 db "3. Withdraw Funds", 10, 0
    menuOption3Len equ $ - menuOption3
    menuOption4 db "4. Transfer Funds", 10, 0
    menuOption4Len equ $ - menuOption4
    menuOption5 db "5. View Transaction History", 10, 0
    menuOption5Len equ $ - menuOption5
    menuOption6 db "6. Logout", 10, 0
    menuOption6Len equ $ - menuOption6
    menuPrompt db "Enter your choice (1-6): ", 0
    menuPromptLen equ $ - menuPrompt
    
    ; Operation prompts
    promptAmount db "Enter amount: $", 0
    promptAmountLen equ $ - promptAmount
    promptTransferAcct db "Enter recipient account number: ", 0
    promptTransferAcctLen equ $ - promptTransferAcct
    promptConfirm db "Confirm transaction (y/n): ", 0
    promptConfirmLen equ $ - promptConfirm
    
    ; Messages
    invalidOptionMsg db "Invalid option. Please try again.", 10, 0
    invalidOptionMsgLen equ $ - invalidOptionMsg
    logoutMsg db "Logging out. Thank you for using our banking system!", 10, 0
    logoutMsgLen equ $ - logoutMsg
    invalidAmountMsg db "Invalid amount. Please enter a valid number.", 10, 0
    invalidAmountMsgLen equ $ - invalidAmountMsg
    cancelledMsg db "Transaction cancelled.", 10, 0
    cancelledMsgLen equ $ - cancelledMsg
    insufficientFundsMsg db "Insufficient funds!", 10, 0
    insufficientFundsMsgLen equ $ - insufficientFundsMsg
    transferNotImplementedMsg db "Function not implemented yet. May be implemented in the future. Thank you!", 10, 0
    transferNotImplementedMsgLen equ $ - transferNotImplementedMsg
    newline db 10, 0
    newlineLen equ $ - newline

section .bss
    userChoice resb 2       ; Buffer for menu choice
    amountBuffer resb 16    ; Buffer for amount input
    confirmBuffer resb 2    ; Buffer for confirmation (y/n)
    
section .text
    global display_menu, handle_menu_choice, process_deposit, process_withdrawal, process_transfer
    extern write_to_file, validate_login, display_balance, update_balance_deposit, update_balance_withdraw, display_transactions, is_valid_amount

; Function to display the main menu
display_menu:
    ; Save registers
    push ebp
    mov ebp, esp
    
    ; Display menu title and options
    mov eax, 4
    mov ebx, 1         
    mov ecx, menuTitle
    mov edx, menuTitleLen
    int 0x80
    
    mov eax, 4
    mov ebx, 1          
    mov ecx, menuOption1
    mov edx, menuOption1Len
    int 0x80
    
    mov eax, 4
    mov ebx, 1          
    mov ecx, menuOption2
    mov edx, menuOption2Len
    int 0x80
    
    mov eax, 4
    mov ebx, 1          
    mov ecx, menuOption3
    mov edx, menuOption3Len
    int 0x80
    
    mov eax, 4
    mov ebx, 1          
    mov ecx, menuOption4
    mov edx, menuOption4Len
    int 0x80
    
    mov eax, 4
    mov ebx, 1          
    mov ecx, menuOption5
    mov edx, menuOption5Len
    int 0x80
    
    mov eax, 4
    mov ebx, 1          
    mov ecx, menuOption6
    mov edx, menuOption6Len
    int 0x80
    
    ; Prompt for user choice
    mov eax, 4
    mov ebx, 1          
    mov ecx, menuPrompt
    mov edx, menuPromptLen
    int 0x80
    
    ; Get user input
    mov eax, 3          ; sys_read
    mov ebx, 0          
    mov ecx, userChoice
    mov edx, 2          ; Read 2 bytes (digit + newline)
    int 0x80
    
    ; Convert ASCII to integer
    movzx eax, byte [userChoice]
    sub eax, '0'  ; Convert ASCII to integer
    
    ; Restore registers and return
    mov esp, ebp
    pop ebp
    ret

; Function to handle menu choice
; Parameters:
; [esp+8] = account number pointer
; [esp+4] = choice (integer)
handle_menu_choice:
    push ebp
    mov ebp, esp
    
    ; Get parameters
    mov eax, [ebp+8]    ; Choice
    mov ebx, [ebp+12]   ; Account number pointer
    
    ; Compare choice with valid options
    cmp eax, 1
    je check_balance_option
    cmp eax, 2
    je deposit_option
    cmp eax, 3
    je withdraw_option
    cmp eax, 4
    je transfer_option
    cmp eax, 5
    je view_history_option
    cmp eax, 6
    je logout_option
    
    ; Invalid option
    mov eax, 4
    mov ebx, 1          
    mov ecx, invalidOptionMsg
    mov edx, invalidOptionMsgLen
    int 0x80
    
    mov eax, 0          ; Return 0 for invalid option
    jmp handle_menu_exit
    
check_balance_option:
    ; Call display_balance with account number
    ; FIX: Use ebx which already contains the account number pointer
    push ebx
    call display_balance
    add esp, 4
    mov eax, 1          ; Return 1 for valid option
    jmp handle_menu_exit
    
deposit_option:
    ; Call process_deposit with account number
    ; FIX: Use ebx which already contains the account number pointer
    push ebx
    call process_deposit
    add esp, 4
    mov eax, 1          ; Return 1 for valid option
    jmp handle_menu_exit
    
withdraw_option:
    ; Call process_withdrawal with account number
    ; FIX: Use ebx which already contains the account number pointer
    push ebx
    call process_withdrawal
    add esp, 4
    mov eax, 1          ; Return 1 for valid option
    jmp handle_menu_exit
    
transfer_option:
    mov eax, 4
    mov ebx, 1
    mov ecx, transferNotImplementedMsg
    mov edx, transferNotImplementedMsgLen
    int 0x80

    mov eax, 1
    jmp handle_menu_exit
    
view_history_option:
    push ebx            ; Push account number pointer onto stack
    call display_transactions  ; Call the display_transactions function
    add esp, 4          
    mov eax, 1          
    jmp handle_menu_exit
    
logout_option:
    ; Display logout message
    mov eax, 4
    mov ebx, 1          
    mov ecx, logoutMsg
    mov edx, logoutMsgLen
    int 0x80
    mov eax, 6          ; Return 6 to indicate logout
    
handle_menu_exit:
    mov esp, ebp
    pop ebp
    ret

; Simple string compare function
; Parameters:
; [esp+8] = string1 pointer
; [esp+4] = string2 pointer

compare_loop:
    mov al, [esi]
    mov bl, [edi]
    
    ; If both characters are null, strings are equal
    cmp al, 0
    jne not_end_yet
    cmp bl, 0
    jne not_equal
    mov eax, 0          ; Return 0 for equal strings
    jmp compare_done
    
not_end_yet:
    ; If characters don't match, strings are not equal
    cmp al, bl
    jne not_equal
    
    ; Move to next character
    inc esi
    inc edi
    jmp compare_loop
    
not_equal:
    mov eax, 1          ; Return 1 for unequal strings
    
compare_done:
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret

check_digits_loop:
    mov bl, [esi]
    cmp bl, 0           ; End of string
    je valid_number
    
    ; Check if character is a digit (0-9)
    cmp bl, '0'
    jl not_valid_number
    cmp bl, '9'
    jg not_valid_number
    
    ; Calculate value
    imul eax, 10        ; Multiply by 10
    sub bl, '0'         ; Convert ASCII to number
    movzx ecx, bl       ; Zero-extend bl to ecx
    add eax, ecx        ; Add digit to result
    
    inc esi             ; Move to next character
    jmp check_digits_loop
    
valid_number:
    ; Result is already in eax
    jmp is_valid_amount_done
    
not_valid_number:
    mov eax, 0          ; Return 0 for invalid
    
is_valid_amount_done:
    pop esi
    mov esp, ebp
    pop ebp
    ret

; Function to process deposit operation
; Parameters:
; [esp+4] = account number pointer
process_deposit:
    push ebp
    mov ebp, esp
    
    ; Get account number
    mov ebx, [ebp+8]
    
    ; Prompt for amount
    mov eax, 4
    mov ebx, 1          
    mov ecx, promptAmount
    mov edx, promptAmountLen
    int 0x80
    
    ; Get amount input
    mov eax, 3          ; sys_read
    mov ebx, 0          
    mov ecx, amountBuffer
    mov edx, 15         
    int 0x80
    
    ; Replace newline with null terminator
    mov edx, eax        ; Number of bytes read
    dec edx             ; Adjust for newline character
    mov byte [amountBuffer + edx], 0
    
    ; Validate amount
    push amountBuffer
    call is_valid_amount
    add esp, 4
    
    ; Check if amount is positve n !=0 
    cmp eax, 0
    jle invalid_deposit_amount
    
    ; Prompt for confirmation
    mov eax, 4
    mov ebx, 1          
    mov ecx, promptConfirm
    mov edx, promptConfirmLen
    int 0x80
    
    ; Get confirmation input
    mov eax, 3          ; sys_read
    mov ebx, 0          
    mov ecx, confirmBuffer
    mov edx, 2          ; Read 2 bytes (character + newline)
    int 0x80
    
    ; Check if user confirmed (y or Y)
    mov al, [confirmBuffer]
    cmp al, 'y'
    je confirm_deposit
    cmp al, 'Y'
    je confirm_deposit
    
    ; Transaction cancelled
    mov eax, 4
    mov ebx, 1          
    mov ecx, cancelledMsg
    mov edx, cancelledMsgLen
    int 0x80
    jmp deposit_exit
    
confirm_deposit:
    ; Call update_balance_deposit with account number and amount
    push amountBuffer
    push dword [ebp+8]
    call update_balance_deposit
    add esp, 8
    
    jmp deposit_exit
    
invalid_deposit_amount:
    ; Display invalid amount message
    mov eax, 4
    mov ebx, 1          
    mov ecx, invalidAmountMsg
    mov edx, invalidAmountMsgLen
    int 0x80
    
deposit_exit:
    mov esp, ebp
    pop ebp
    ret

; Function to process withdrawal operation
; Parameters:
; [esp+4] = account number pointer
process_withdrawal:
    push ebp
    mov ebp, esp
    
    ; Get account number
    mov ebx, [ebp+8]
    
    ; Prompt for amount
    mov eax, 4
    mov ebx, 1          
    mov ecx, promptAmount
    mov edx, promptAmountLen
    int 0x80
    
    ; Get amount input
    mov eax, 3          ; sys_read
    mov ebx, 0          
    mov ecx, amountBuffer
    mov edx, 15         ; Max 15 characters including newline
    int 0x80
    
    ; Replace newline with null terminator
    mov edx, eax        ; Number of bytes read
    dec edx             ; Adjust for newline character
    mov byte [amountBuffer + edx], 0
    
    ; Validate amount
    push amountBuffer
    call is_valid_amount
    add esp, 4
    
    ; Check if amount is valid (greater than 0)
    cmp eax, 0
    jle invalid_withdrawal_amount
    
    ; Prompt for confirmation
    mov eax, 4
    mov ebx, 1          
    mov ecx, promptConfirm
    mov edx, promptConfirmLen
    int 0x80
    
    ; Get confirmation input
    mov eax, 3          ; sys_read
    mov ebx, 0          
    mov ecx, confirmBuffer
    mov edx, 2          ; Read 2 bytes (character + newline)
    int 0x80
    
    ; Check if user confirmed (y or Y)
    mov al, [confirmBuffer]
    cmp al, 'y'
    je confirm_withdrawal
    cmp al, 'Y'
    je confirm_withdrawal
    
    ; Transaction cancelled
    mov eax, 4
    mov ebx, 1          
    mov ecx, cancelledMsg
    mov edx, cancelledMsgLen
    int 0x80
    jmp withdrawal_exit
    
confirm_withdrawal:
    ; Call update_balance_withdraw with account number and amount
    push amountBuffer
    push dword [ebp+8]
    call update_balance_withdraw
    add esp, 8
    
    ; Check if withdrawal was successful
    cmp eax, 0
    je insufficient_funds
    
    jmp withdrawal_exit
    
insufficient_funds:
    ; Display insufficient funds message
    mov eax, 4
    mov ebx, 1          
    mov ecx, insufficientFundsMsg
    mov edx, insufficientFundsMsgLen
    int 0x80
    jmp withdrawal_exit
    
invalid_withdrawal_amount:
    ; Display invalid amount message
    mov eax, 4
    mov ebx, 1          
    mov ecx, invalidAmountMsg
    mov edx, invalidAmountMsgLen
    int 0x80
    
withdrawal_exit:
    mov esp, ebp
    pop ebp
    ret