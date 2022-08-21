bits 64
default rel

global _start


section .rodata
    msg db "Hello World!", 0x0d, 0x0a
    msg_len equ $ - msg


section .bss
    ;; See https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/ns-wdm-_io_status_block
    ;; Required parameter that stores the result of the NtWriteFile syscall
    ;; The 2nd quadword will contain the number of written bytes.
    iostatus resq 2


section .text

_start:
    ;; See https://sites.google.com/site/x64lab/home/notes-on-x64-windows-gui-programming/exploring-peb-process-environment-block
    mov r10, [gs:60h]   ;; The pointer to the PEB for 64 bit applications is found at gs:60h
    mov r10, [r10 + 32] ;; Within the PEB struct, the pointer to process parameters sits at offset 32
    mov r10, [r10 + 40] ;; Within the RTL_USER_PROCESS_PARAMETERS struct, the output handle sits at offset 40

    ;; See https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/ntifs/nf-ntifs-ntwritefile
    ;;
    ;; Handle to stdout already resides in r10
    ;; Set the following 3 unused parameters to null
    xor rdx, rdx
    xor r8, r8
    xor r9, r9
    ;; Push the remaining 5 parameters in reverse order, as per calling convention
    push 0
    push 0
    push msg_len
    lea rax, [msg]
    push rax
    lea rax, [iostatus]
    push rax
    ;; The following setup is the typical prelude for syscalls as they are performed by ntdll.dll
    ;; Syscall numbers can be found here https://github.com/j00ru/windows-syscalls
    mov rax, 0x08 ;; rax holds the syscall number (windows version and sometimes even build specific!)
    ;; Need to adjust the stack pointer because syscalls expect stack parameters at the "usual" locations
    ;; based on the x64 windows calling convention including shadowspace and an assumed ret address.
    ;; (arg5 at rsp+40, arg6 at rsp+48 etc...)
    sub rsp, 40
    syscall
    add rsp, 32 ;; Shrink stack - note that we still have 48 bytes left (32 shadow space, 8 fake ret address, 8 align)

    ;; See https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/ntddk/nf-ntddk-zwterminateprocess
    ;;
    ;; This is the syscall performed by kernel32!ExitProcess
    mov r10, -1   ;; First parameter, -1 to terminate calling process
    mov rdx, 0    ;; 2nd parameter, return value
    mov rax, 0x2C ;; rax holds the syscall number
    syscall
