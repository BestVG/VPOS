[org 0x1000]
[bits 32]

main:
    mov eax, end_addr
    mov ebx, 0x80400000
    call kinit1
    mov [0xb8000], byte 'X'

jmp $

times 15*256 dw 0xDADA

; Must be last line of kernel
end_addr equ $
