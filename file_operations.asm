section .data
    filename db "accounts.csv", 0
    header db "Name,AccountID,PIN,Balance", 10, 0  ; Updated CSV header with Balance
    newline db 10, 0
    comma db ',', 0
    balanceMsg db "Your current balance is: $", 0
    invalidLoginMsg db "Invalid login credentials!", 10, 0
    invalidLen equ $ - invalidLoginMsg
    depositMsg db "Deposit successful!", 10, 0
    withdrawalMsg db "Withdrawal successful!", 10, 0
    insufficientFundsMsg db "Insufficient funds!", 10, 0
    transactions_filename db "transactions.csv", 0
    transactions_header db "AccountID,Amount,Type", 10, 0
    deposit_type db "deposit", 0
    withdraw_type db "withdraw", 0
    amountLabel db "Amount: $", 0
    typeLabel db ", Type: ", 0
    transactionHistoryMsg db "Transaction History:", 10, 0

section .bss
    file_descriptor resb 4
    buffer resb 257
    balance resb 10
    accountNumber resb 10
    pin resb 10
    amount resb 10

section .text
    global write_to_file, validate_login, display_balance, update_balance_deposit, update_balance_withdraw, display_transactions, is_valid_amount

; Improved strlen function that gets string pointer as parameter
strlen:
    push ebp
    mov ebp, esp        ; Set up stack frame
    push ebx
    push ecx
    
    mov ebx, [ebp+8]    ; Get string pointer from parameter
    xor ecx, ecx        ; Initialize counter to 0
strlen_loop:
    mov al, [ebx + ecx] ; Load byte from string
    cmp al, 0           ; Check for null terminator
    je strlen_done
    inc ecx             ; Increment counter
    jmp strlen_loop
strlen_done:
    mov eax, ecx        ; Return length in EAX
    pop ecx
    pop ebx
    mov esp, ebp
    pop ebp
    ret

write_to_file:
    ; Parameters:
    ; [esp+16] = name pointer
    ; [esp+12] = account ID pointer
    ; [esp+8] = PIN pointer
    ; [esp+4] = initial balance pointer
    ; Preserve registers
    push ebp
    mov ebp, esp        ; Set up stack frame
    push ebx
    push esi
    push edi
    
    ; Retrieve parameters
    mov esi, [ebp+8]    ; Name pointer
    mov edi, [ebp+12]   ; Account ID pointer
    mov ebx, [ebp+16]   ; PIN pointer
    mov edx, [ebp+20]   ; Initial balance pointer

    ; Open file (append mode)
    push edx            ; Save balance pointer
    mov eax, 5          ; sys_open
    mov ebx, filename
    mov ecx, 2 | 64 | 1024 ; O_RDWR | O_CREAT | O_APPEND
    mov edx, 0666o      ; File permissions
    int 0x80
    pop edx             ; Restore balance pointer
    cmp eax, -1         ; Check for error
    je write_to_file_error
    mov [file_descriptor], eax
    
    ; Check if file is empty
    push edx            ; Save balance pointer
    mov eax, 19         ; sys_lseek
    mov ebx, [file_descriptor]
    mov ecx, 0          ; Offset
    mov edx, 2          
    int 0x80
    pop edx             ; Restore balance pointer
    cmp eax, 0          ; If file is empty, write header
    jne skip_header
    
    ; Move back to beginning of file
    push edx            ; Save balance pointer
    mov eax, 19         ; sys_lseek
    mov ebx, [file_descriptor]
    mov ecx, 0          ; Offset
    mov edx, 0          
    int 0x80
    pop edx             ; Restore balance pointer
    
    ; Write header
    push edx            ; Save balance pointer
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, header
    mov edx, 27         ; Length of header (including newline)
    int 0x80
    pop edx             ; Restore balance pointer
    jmp write_data
    
skip_header:
    ; Move back to end of file
    push edx            ; Save balance pointer
    mov eax, 19         ; sys_lseek
    mov ebx, [file_descriptor]
    mov ecx, 0          ; Offset
    mov edx, 2          
    int 0x80
    pop edx             ; Restore balance pointer

write_data:
    ; Write name to file
    push edx            ; Save balance pointer to stack
    push esi            ; Push string pointer as parameter
    call strlen
    add esp, 4          ; Clean up parameter
    mov edx, eax        ; Length of string
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, esi        ; Name pointer
    int 0x80
    
    ; Write comma separator
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, comma
    mov edx, 1
    int 0x80
    
    ; Write account ID
    push edi            ; Push account ID pointer as parameter
    call strlen
    add esp, 4          ; Clean up parameter
    mov edx, eax        ; Length of string
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, edi        ; Account ID pointer
    int 0x80
    
    ; Write comma separator
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, comma
    mov edx, 1
    int 0x80
    
    ; Write PIN
    mov edi, [ebp+16]   ; PIN pointer
    push edi            ; Push PIN pointer as parameter
    call strlen
    add esp, 4          ; Clean up parameter
    mov edx, eax        ; Length of string
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, edi        ; PIN pointer
    int 0x80
    
    ; Write comma separator
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, comma
    mov edx, 1
    int 0x80
    
    ; Get balance pointer back
    pop edx             ; Restore balance pointer from stack
    
    ; Write initial balance
    push edx            ; Push balance pointer as parameter
    call strlen
    add esp, 4          ; Clean up parameter
    mov ecx, edx        ; Balance pointer
    mov edx, eax        ; Length of string
    mov eax, 4
    mov ebx, [file_descriptor]
    int 0x80
    
    ; Write newline
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    ; Close file
    mov eax, 6          ; sys_close
    mov ebx, [file_descriptor]
    int 0x80
    
    ; Restore registers and return success
    mov eax, 1          ; Return success
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

write_to_file_error:
    ; Restore registers and return error
    mov eax, 0          ; Return error
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

validate_login:
    ; Parameters expected:
    ; [esp+4] = account ID pointer
    ; [esp+8] = PIN pointer
    push ebp
    mov ebp, esp        ; Set up stack frame
    push ebx
    push esi
    push edi
    
    ; Open file
    mov eax, 5
    mov ebx, filename
    mov ecx, 0          ; O_RDONLY
    int 0x80
    cmp eax, -1         ; Check for error
    je validate_login_error
    mov [file_descriptor], eax

    ; Read file contents
    mov eax, 3
    mov ebx, [file_descriptor]
    mov ecx, buffer
    mov edx, 256
    int 0x80

    ; Save read bytes count
    push eax
    ; Close file
    mov eax, 6
    mov ebx, [file_descriptor]
    int 0x80
    ; Restore read bytes count
    pop edx

    ; Null-terminate the buffer
    mov byte [buffer + edx], 0

    ; Get parameters
    mov esi, [ebp+8]    ; Account ID
    mov edi, [ebp+12]   ; PIN

    ; Parse buffer line by line to find matching account
    mov ebx, buffer
parse_line:
    ; Skip the name field (until comma)
    call find_next_comma
    cmp byte [ebx], 0   ; Check if end of buffer
    je login_failed
    inc ebx             ; Move past comma

    ; Compare account ID
    push esi            ; Save account ID pointer
    push edi            ; Save PIN pointer
    mov edi, esi        ; Account ID to compare
    call compare_field
    pop edi             ; Restore PIN pointer
    pop esi             ; Restore account ID pointer
    cmp eax, 0          ; Check if match
    jne next_line

    ; Account ID matched, now check PIN
    call find_next_comma
    cmp byte [ebx], 0   ; Check if end of buffer
    je login_failed
    inc ebx             ; Move past comma

    ; Compare PIN
    push edi            ; Save PIN pointer
    call compare_field
    pop edi             ; Restore PIN pointer
    cmp eax, 0          ; Check if match
    jne next_line

    ; Both account ID and PIN match
    mov eax, 1          ; Return success
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

next_line:
    ; Find next line
    call find_next_line
    cmp byte [ebx], 0   ; Check if end of buffer
    je login_failed
    jmp parse_line

login_failed:
    ; Display invalid login message
    mov eax, 4
    mov ebx, 1          
    mov ecx, invalidLoginMsg
    mov edx, invalidLen         ; Length of message
    int 0x80
    mov eax, 0          ; Return failure
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

find_next_comma:
    push eax
    mov al, ','
find_comma_loop:
    cmp byte [ebx], 0   ; Check for end of buffer
    je find_comma_done
    cmp byte [ebx], al  ; Check for comma
    je find_comma_done
    inc ebx
    jmp find_comma_loop
find_comma_done:
    pop eax
    ret

find_next_line:
    push eax
    mov al, 10          ; Newline character
find_line_loop:
    cmp byte [ebx], 0   ; Check for end of buffer
    je find_line_done
    cmp byte [ebx], al  ; Check for newline
    je find_line_found
    inc ebx
    jmp find_line_loop
find_line_found:
    inc ebx             ; Move past newline
find_line_done:
    pop eax
    ret

compare_field:
    push ecx
    push edx
    push esi            ; Save ESI so we can use it
    mov edx, ebx        ; Save start of field
    mov esi, edi        ; Move comparison string to ESI
compare_loop:
    mov cl, byte [ebx]
    cmp cl, 0           ; End of buffer
    je compare_end_field
    cmp cl, ','         ; Field separator
    je compare_end_field
    cmp cl, 10          ; Newline
    je compare_end_field
    cmp cl, byte [esi]  ; Compare characters using ESI
    jne compare_mismatch
    inc ebx
    inc esi             ; Increment ESI instead of EDI
    jmp compare_loop
compare_end_field:
    ; Check if we've reached end of comparison string
    cmp byte [esi], 0   ; Check ESI instead of EDI
    jne compare_mismatch
    mov eax, 0          ; Match
    jmp compare_done
compare_mismatch:
    mov eax, 1          ; No match
compare_done:
    pop esi             ; Restore ESI
    pop edx
    pop ecx
    ret

validate_login_error:
    ; Handle error (e.g., print error message and exit)
    mov eax, 0          ; Return failure
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

display_balance:
    ; Parameter:
    ; [esp+4] = account ID pointer
    push ebp
    mov ebp, esp        ; Set up stack frame
    push ebx
    push esi
    push edi
    
    ; Open file
    mov eax, 5
    mov ebx, filename
    mov ecx, 0          ; O_RDONLY
    int 0x80
    cmp eax, -1         ; Check for error
    je display_balance_error
    mov [file_descriptor], eax

    ; Read file contents
    mov eax, 3
    mov ebx, [file_descriptor]
    mov ecx, buffer
    mov edx, 256
    int 0x80

    ; Save read bytes count
    push eax
    ; Close file
    mov eax, 6
    mov ebx, [file_descriptor]
    int 0x80
    ; Restore read bytes count
    pop edx

    ; Null-terminate the buffer
    mov byte [buffer + edx], 0

    ; Get account ID parameter
    mov esi, [ebp+8]      ; Account ID pointer

    ; Parse buffer line by line to find matching account
    mov ebx, buffer
parse_balance_line:
    ; Skip the name field (until comma)
    call find_next_comma
    cmp byte [ebx], 0     ; Check if end of buffer
    je balance_not_found
    inc ebx               ; Move past comma

    ; Compare account ID
    push esi              ; Save account ID pointer
    mov edi, esi          ; Account ID to compare
    call compare_field
    pop esi               ; Restore account ID pointer
    cmp eax, 0            ; Check if match
    jne next_balance_line

    ; Account ID matched, extract balance (after PIN)
    call find_next_comma
    cmp byte [ebx], 0     ; Check if end of buffer
    je balance_not_found
    inc ebx               ; Move past comma
    call find_next_comma
    cmp byte [ebx], 0     ; Check if end of buffer
    je balance_not_found
    inc ebx               ; Move past comma

    ; Copy balance into buffer
    mov edi, balance
copy_balance_loop:
    mov al, [ebx]
    cmp al, 0
    je copy_balance_done
    cmp al, 10
    je copy_balance_done
    mov [edi], al
    inc edi
    inc ebx
    jmp copy_balance_loop
copy_balance_done:
    mov byte [edi], 0

    ; Display balance message
    mov eax, 4
    mov ebx, 1         
    mov ecx, balanceMsg
    mov edx, 25           ; Length of message
    int 0x80

    ; Display balance value
    push balance          ; Push balance string as parameter
    call strlen
    add esp, 4            ; Clean up parameter
    mov edx, eax          ; Length of balance string
    mov eax, 4
    mov ebx, 1           
    mov ecx, balance
    int 0x80

    ; Write newline
    mov eax, 4
    mov ebx, 1      
    mov ecx, newline
    mov edx, 1
    int 0x80

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

balance_not_found:
    ; Display error message
    mov eax, 4
    mov ebx, 1        
    mov ecx, invalidLoginMsg
    mov edx, invalidLen           ; Length of message
    int 0x80
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

next_balance_line:
    ; Find next line
    call find_next_line
    cmp byte [ebx], 0     ; Check if end of buffer
    je balance_not_found
    jmp parse_balance_line

display_balance_error:
    ; Handle error (e.g., print error message and exit)
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret


is_valid_amount:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    
    mov esi, [ebp+8]    ; Get string pointer
    xor eax, eax        ; Clear result
    
is_valid_loop:
    movzx ebx, byte [esi]  ; Get current character
    test ebx, ebx          ; Check for null terminator
    jz is_valid_done
    
    cmp ebx, '0'           ; Check if character is a digit
    jl is_valid_error
    cmp ebx, '9'
    jg is_valid_error
    
    ; Convert to number and add to result
    imul eax, 10           ; Multiply result by 10
    sub ebx, '0'           ; Convert ASCII to number
    add eax, ebx           ; Add to result
    
    inc esi                ; Move to next character
    jmp is_valid_loop
    
is_valid_error:
    ; Handle non-digit character (could return error, but for now just stop processing)
    ; Alternatively, you could skip non-digits or return an error code
    
is_valid_done:
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; Shared function for updating account balance (for both deposit and withdraw)
update_balance:
    ; Parameters:
    ; [esp+4] = account ID pointer
    ; [esp+8] = amount pointer
    ; [esp+12] = operation type (0 for deposit, 1 for withdraw)
    push ebp
    mov ebp, esp        ; Set up stack frame
    push ebx
    push esi
    push edi
    
    ; Open file for reading
    mov eax, 5
    mov ebx, filename
    mov ecx, 0          ; O_RDONLY
    int 0x80
    cmp eax, -1         ; Check for error
    je update_error
    mov [file_descriptor], eax
    
    ; Read file contents
    mov eax, 3
    mov ebx, [file_descriptor]
    mov ecx, buffer
    mov edx, 256
    int 0x80
    
    ; Save read bytes count
    mov esi, eax        ; Save bytes read
    
    ; Close file
    mov eax, 6
    mov ebx, [file_descriptor]
    int 0x80
    
    ; Null-terminate buffer
    mov byte [buffer + esi], 0
    
    ; Open temporary file for writing
    mov eax, 5
    mov ebx, filename   ; Overwrite directly
    mov ecx, 2 | 64 | 512  ; O_RDWR | O_CREAT | O_TRUNC
    mov edx, 0666o        ; File permissions
    int 0x80
    
    cmp eax, -1         ; Check for error
    je update_error
    mov [file_descriptor], eax
    
    ; Get parameters
    mov esi, [ebp+8]    ; Account ID
    mov edi, [ebp+12]   ; Amount to deposit/withdraw
    
    ; Write header (since we're creating a new file)
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, header
    mov edx, 27         ; Length of header
    int 0x80
    
    ; Parse buffer line by line starting after header
    mov ebx, buffer
    call find_next_line ; Skip header
    
process_balance_line:
    ; Check if end of buffer
    cmp byte [ebx], 0
    je update_done
    
    mov edx, ebx        ; Save line start
    
    ; Find account ID field (skip name field)
    call find_next_comma
    cmp byte [ebx], 0
    je update_done
    inc ebx             ; Move past comma
    
    ; Check if this is the account to update
    push edx            ; Save line start
    push ebx            ; Save position
    push edi            ; Save amount pointer
    mov edi, esi        ; Account ID to compare
    call compare_field
    pop edi             ; Restore amount pointer
    pop ebx             ; Restore position
    pop edx             ; Restore line start
    
    cmp eax, 0          ; Check if match
    je update_account_balance
    
    ; Not the account to update, write line as is
    push edx            ; Save line start
    call find_next_line ; Find next line
    mov ecx, ebx        ; Next line or end
    pop edx             ; Restore line start
    
    ; Calculate length of line
    push ebx            ; Save next line position
    mov eax, ecx
    sub eax, edx        ; Calculate length
    
    ; Write the entire line
    mov ecx, edx        ; Line start
    mov edx, eax        ; Length
    mov eax, 4
    mov ebx, [file_descriptor]
    int 0x80
    
    pop ebx             ; Restore next line position
    jmp process_balance_line
    
update_account_balance:
    ; Found the account to update
    ; Write everything up to the balance field
    
    ; Find balance field (skip past 2 more commas for PIN)
    mov ecx, ebx        ; Save account ID position
    call find_next_comma ; Skip account ID
    cmp byte [ebx], 0
    je update_done
    inc ebx             ; Move past comma
    call find_next_comma ; Skip PIN
    cmp byte [ebx], 0
    je update_done
    inc ebx             ; Move past comma
    
    ; Calculate length to write from line start to before balance
    push ebx            ; Save balance position
    
    mov eax, ebx
    sub eax, edx        ; Calculate length
    mov ecx, edx        ; Line start
    mov edx, eax        ; Length
    mov eax, 4
    mov ebx, [file_descriptor]
    int 0x80
    
    pop ebx             ; Restore balance position
    
    ; Now parse existing balance value
    push ebx            ; Save balance position
    
    ; Convert balance string to number
    push ebx            ; Pass pointer to balance string in file
    call is_valid_amount
    mov ecx, eax        ; Save current balance
    add esp, 4          ; Clean up stack
    
    ; Convert deposit/withdraw amount to number
    push ecx            ; Save current balance
    push dword [ebp+12] ; Pass amount pointer
    call is_valid_amount
    mov edx, eax        ; Save amount
    add esp, 4          ; Clean up stack
    pop ecx             ; Restore current balance
    
    ; Check operation type and calculate new balance
    cmp dword [ebp+16], 0  ; 0 = deposit, 1 = withdraw
    je do_deposit
    
    ; Withdraw operation
    ; Check if sufficient funds
    cmp ecx, edx
    jl insufficient_funds
    
    ; Calculate new balance for withdraw
    sub ecx, edx        ; new_balance = current_balance - withdrawal_amount
    jmp convert_balance
    
do_deposit:
    ; Calculate new balance for deposit
    add ecx, edx        ; new_balance = current_balance + deposit_amount
    
convert_balance:
    ; Convert new balance to string
    mov eax, ecx        ; Move new balance to EAX
    mov esi, balance
    add esi, 9          ; End of balance buffer
    mov byte [esi+1], 0 ; Null-terminate
    
    mov ecx, 10         ; Divisor
    
    ; Handle zero case specially
    test eax, eax
    jnz convert_balance_digits
    
    mov byte [balance], '0'
    mov byte [balance+1], 0
    mov esi, balance
    jmp write_balance
    
convert_balance_digits:
    xor edx, edx        ; Clear EDX before division to prevent errors
    div ecx             ; Divide by 10, remainder in EDX
    add dl, '0'         ; Convert remainder to ASCII
    mov [esi], dl       ; Store digit
    dec esi             ; Move to next position (building backward)
    test eax, eax       ; Check if more digits
    jnz convert_balance_digits
    
    ; esi now points to the character before first digit
    inc esi             ; Point to first digit
    
write_balance:
    ; Write the new balance
    push esi            ; Save balance string start
    call strlen
    add esp, 4          ; Clean up parameter
    
    mov edx, eax        ; Length of balance string
    mov ecx, esi        ; Balance string
    mov eax, 4
    mov ebx, [file_descriptor]
    int 0x80
    
    ; Find end of current line to skip to next line
    pop ebx             ; Restore balance position
    call find_next_line
    
    ; Write newline
    push ebx            ; Save next line position
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    ; Display appropriate success message
    mov eax, 4
    mov ebx, 1          
    cmp dword [ebp+16], 0  ; Check operation type
    je print_deposit_msg
    
    ; Print withdraw message
    mov ecx, withdrawalMsg
    mov edx, 23         ; Length of message
    jmp print_msg
    
print_deposit_msg:
    mov ecx, depositMsg
    mov edx, 22         ; Length of message
    
print_msg:
    int 0x80
    
    pop ebx             ; Restore next line position
    jmp process_balance_line
    
insufficient_funds:
    ; Display insufficient funds message
    mov eax, 4
    mov ebx, 1      
    mov ecx, insufficientFundsMsg
    mov edx, 21         ; Length of message
    int 0x80
    
    ; Skip this account, continue processing
    pop ebx             ; Restore balance position
    call find_next_line
    jmp process_balance_line
    
update_done:
    ; Close file
    mov eax, 6
    mov ebx, [file_descriptor]
    int 0x80
    
    mov eax, 1          ; Return success
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret
    
update_error:
    mov eax, 0          ; Return error
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; Wrapper function for deposits
update_balance_deposit:
    ; Parameters:
    ; [esp+4] = account ID pointer
    ; [esp+8] = amount pointer
    push ebp
    mov ebp, esp
    
    ; Call shared function with operation type = 0 (deposit)
    push 0              ; operation type (0 = deposit)
    push dword [ebp+12] ; amount
    push dword [ebp+8]  ; account ID
    call update_balance
    add esp, 12         ; Clean up parameters
    
    ; If deposit was successful (eax = 1), log the transaction
    cmp eax, 1
    jne deposit_done    ; Skip logging if not successful
    
    ; Log the transaction only if successful
    push 0              ; transaction type (0 = deposit)
    push dword [ebp+12] ; amount
    push dword [ebp+8]  ; account ID
    call log_transaction
    add esp, 12         ; Clean up parameters

deposit_done:
    mov esp, ebp
    pop ebp
    ret

update_balance_withdraw:
    ; Parameters:
    ; [esp+4] = account ID pointer
    ; [esp+8] = amount pointer
    push ebp
    mov ebp, esp
    
    ; Convert balance string to number
    push balance        ; Pass balance string
    call is_valid_amount
    mov ecx, eax        ; Save current balance
    add esp, 4          ; Clean up parameter
    
    ; Convert withdraw amount to number
    push dword [ebp+12] ; Pass amount pointer
    call is_valid_amount
    mov edx, eax        ; Save amount
    add esp, 4          ; Clean up parameter
    
    ; Check if sufficient funds
    cmp ecx, edx
    jl withdraw_insufficient_funds
    
    ; Call shared function with operation type = 1 (withdraw)
    push 1              ; operation type (1 = withdraw)
    push dword [ebp+12] ; amount
    push dword [ebp+8]  ; account ID
    call update_balance
    add esp, 12         ; Clean up parameters
    
    ; If withdrawal was successful (eax = 1), log the transaction
    cmp eax, 1
    jne withdraw_done
    
    ; Log the transaction
    push 1              ; transaction type (1 = withdraw)
    push dword [ebp+12] ; amount
    push dword [ebp+8]  ; account ID
    call log_transaction
    add esp, 12         ; Clean up parameters
    jmp withdraw_done
    
withdraw_insufficient_funds:
    ; Display insufficient funds message
    mov eax, 4
    mov ebx, 1      
    mov ecx, insufficientFundsMsg
    mov edx, 21         ; Length of message
    int 0x80
    
withdraw_done:
    mov esp, ebp
    pop ebp
    ret

; Helper function to compare strings (returns 0 if equal)
strcmp:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    
    mov esi, [ebp+8]    ; First string
    mov edi, [ebp+12]   ; Second string
    
strcmp_loop:
    mov al, [esi]
    mov bl, [edi]
    
    ; Compare characters
    cmp al, bl
    jne strcmp_not_equal
    
    ; Check for end of string
    test al, al
    jz strcmp_equal
    
    ; Move to next character
    inc esi
    inc edi
    jmp strcmp_loop
    
strcmp_equal:
    xor eax, eax        ; Return 0 (equal)
    jmp strcmp_done
    
strcmp_not_equal:
    mov eax, 1          ; Return 1 (not equal)
    
strcmp_done:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret
    
copy_original_line:
    ; Find end of line
    mov ecx, edx        ; Current line start
    mov edx, ebx        ; Current position

; Function to log a transaction to the transactions.csv file
; Parameters:
; [esp+4] = account ID pointer
; [esp+8] = amount pointer
; [esp+12] = transaction type (0 for deposit, 1 for withdraw)
log_transaction:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    
    ; Open transactions file (append mode)
    mov eax, 5
    mov ebx, transactions_filename
    mov ecx, 2 | 64 | 1024 ; O_RDWR | O_CREAT | O_APPEND
    mov edx, 0666o      ; File permissions
    int 0x80
    cmp eax, -1
    je log_transaction_error
    mov [file_descriptor], eax
    
    ; Check if file is empty using lseek
    mov eax, 19         ; sys_lseek
    mov ebx, [file_descriptor]
    mov ecx, 0          ; Offset
    mov edx, 2          
    int 0x80
    cmp eax, 0          ; If file is empty, write header
    jne skip_transaction_header
    
    ; Move back to beginning of file
    mov eax, 19         ; sys_lseek
    mov ebx, [file_descriptor]
    mov ecx, 0          ; Offset
    mov edx, 0          
    int 0x80
    
    ; Write header
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, transactions_header
    mov edx, 22         ; Length of header with newline
    int 0x80
    jmp write_transaction_data
    
skip_transaction_header:
    ; Move back to end of file
    mov eax, 19         ; sys_lseek
    mov ebx, [file_descriptor]
    mov ecx, 0          ; Offset
    mov edx, 2          
    int 0x80
    
write_transaction_data:
    ; Write account ID
    mov esi, [ebp+8]    ; Account ID pointer
    push esi
    call strlen
    add esp, 4
    mov edx, eax        ; Length of string
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, esi        ; Account ID pointer
    int 0x80
    
    ; Write comma separator
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, comma
    mov edx, 1
    int 0x80
    
    ; Write amount
    mov esi, [ebp+12]   ; Amount pointer
    push esi
    call strlen
    add esp, 4
    mov edx, eax        ; Length of string
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, esi        ; Amount pointer
    int 0x80
    
    ; Write comma separator
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, comma
    mov edx, 1
    int 0x80
    
    ; Write transaction type
    cmp dword [ebp+16], 0
    je write_deposit_type
    
    ; Write "withdraw"
    mov esi, withdraw_type
    push esi
    call strlen
    add esp, 4
    mov edx, eax        ; Length of string
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, withdraw_type
    int 0x80
    jmp finish_transaction
    
write_deposit_type:
    ; Write "deposit"
    mov esi, deposit_type
    push esi
    call strlen
    add esp, 4
    mov edx, eax        ; Length of string
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, deposit_type
    int 0x80
    
finish_transaction:
    ; Write newline
    mov eax, 4
    mov ebx, [file_descriptor]
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    ; Close file
    mov eax, 6
    mov ebx, [file_descriptor]
    int 0x80
    
    mov eax, 1          ; Return success
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret
    
log_transaction_error:
    mov eax, 0          ; Return error
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

display_transactions:
    ; Parameter:
    ; [esp+4] = account ID pointer
    push ebp
    mov ebp, esp        ; Set up stack frame
    push ebx
    push esi
    push edi
    
    ; Display transaction history header
    mov eax, 4
    mov ebx, 1         
    mov ecx, transactionHistoryMsg
    mov edx, 20         ; Length of transaction history message
    int 0x80
    
    ; Open transactions file
    mov eax, 5
    mov ebx, transactions_filename
    mov ecx, 0          ; O_RDONLY
    int 0x80
    cmp eax, -1         ; Check for error
    je display_transactions_error
    mov [file_descriptor], eax
    
    ; Read file contents
    mov eax, 3
    mov ebx, [file_descriptor]
    mov ecx, buffer
    mov edx, 256        ; Increased buffer size slightly
    int 0x80
    
    ; Save read bytes count
    push eax            ; Save bytes read
    
    ; Close file
    mov eax, 6
    mov ebx, [file_descriptor]
    int 0x80
    
    ; Restore read bytes count and null-terminate the buffer
    pop esi
    mov byte [buffer + esi], 0
    
    ; Get account ID parameter
    mov esi, [ebp+8]    ; Account ID pointer
    
    ; Parse buffer line by line starting after header
    mov ebx, buffer
    call find_next_line ; Skip header
    
transaction_line_loop:
    ; Check if end of buffer
    cmp byte [ebx], 0
    je display_transactions_done
    
    ; Save start of line for account ID comparison
    mov edi, ebx
    
    ; Check if this transaction belongs to the current account
    push esi            ; Save account ID pointer
    mov edi, esi        ; Account ID to compare
    call compare_field
    pop esi             ; Restore account ID pointer
    
    cmp eax, 0          ; Check if match (0 means match)
    jne next_transaction_line
    
    ; Found matching transaction, now parse and display it
    ; Find amount field (after first comma)
    call find_next_comma
    cmp byte [ebx], 0   ; Check if end of buffer
    je next_transaction_line
    inc ebx             ; Move past comma
    
    ; Save start of amount field
    mov edi, ebx
    
    ; Find transaction type field (after second comma)
    call find_next_comma
    cmp byte [ebx], 0   ; Check if end of buffer
    je next_transaction_line
    
    ; Store position of comma before type
    push ebx            ; Save position before type
    
    ; Calculate length of amount field
    mov eax, ebx        ; Current position (at comma)
    sub eax, edi        ; Calculate length of amount
    
    ; Output "Amount: $"
    push eax            ; Save amount length
    mov eax, 4
    mov ebx, 1          
    mov ecx, amountLabel
    mov edx, 9          ; Length of "Amount: $"
    int 0x80
    
    ; Output amount value
    pop edx             ; Restore amount length
    mov eax, 4
    mov ebx, 1         
    mov ecx, edi        ; Start of amount field
    int 0x80
    
    ; Restore position before type and move past comma
    pop ebx
    inc ebx
    
    ; Save start of type field
    mov edi, ebx
    
    ; Find end of line or end of buffer
    mov al, 10          ; Look for newline
find_end_of_line:
    cmp byte [ebx], 0   ; Check for end of buffer
    je found_end_of_line
    cmp byte [ebx], al  ; Check for newline
    je found_end_of_line
    inc ebx
    jmp find_end_of_line
    
found_end_of_line:
    ; Calculate and save length of type field
    push ebx            ; Save position at end of line
    sub ebx, edi        ; Calculate length of type field
    mov edx, ebx        ; Save length in edx
    
    ; Output ", Type: "
    mov eax, 4
    mov ebx, 1          
    mov ecx, typeLabel
    push edx            ; Save type length
    mov edx, 8          ; Length of ", Type: "
    int 0x80
    
    ; Output type value
    pop edx             ; Restore type length
    mov eax, 4
    mov ebx, 1         
    mov ecx, edi        ; Start of type field
    int 0x80
    
    ; Output newline
    mov eax, 4
    mov ebx, 1          
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    ; Restore position and move to next line
    pop ebx             ; Restore position at end of line
    call find_next_line
    jmp transaction_line_loop
    
next_transaction_line:
    ; Find next line
    call find_next_line
    jmp transaction_line_loop
    
display_transactions_done:
    mov eax, 1          ; Return success
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret
    
display_transactions_error:
    mov eax, 0          ; Return error
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret