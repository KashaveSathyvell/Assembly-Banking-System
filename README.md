# Banking System Project
This is a simple Banking system that is designed in assembly code. function that can be performed is the create new account, where users will input a account ID, PIN and an initial balance to be deposited. 
Users with a valid account are then able to login to their account and can deposit and withdraw money from their accounts. Users are also able to check their past transactions of deposits/withdrawals and the amount. 

To run this project, users will first need to pull the code into their local machines, and 'cd' into "TP075164_BankingSystem" using the WSL(Windows Subsystem for Linux) and run the following code first:

nasm -f elf32 main.asm -o main.o
nasm -f elf32 account_creation.asm -o account_creation.o
nasm -f elf32 account_operations.asm -o account_operations.o
nasm -f elf32 file_operations.asm -o file_operations.o

Then run this command:
ld -m elf_i386 -o banking_system main.o account_creation.o file_operations.o account_operations.o

Once done, users can run the code using this command:
./banking_system
