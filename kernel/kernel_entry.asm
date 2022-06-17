[org 0x1000]
[bits 32]

main:
    call write_regs
    call disable_cursor
    mov bx, 0
    mov cl, 0
    clr_lp_1:
    mov ax, 0
    clr_lp_2:
    call draw_pixel
    inc ax
    cmp ax, DISPLAY_width
    jl clr_lp_2
    inc bx
    cmp bx, DISPLAY_height
    jl clr_lp_1

    mov bx, 0
    draw_lp_1:
    mov ax, bx
    add ax, 60
    mov cl, 1
    call draw_pixel
    mov ax, 260
    sub ax, bx
    mov cl, 2
    call draw_pixel
    inc bx
    cmp bx, DISPLAY_height
    jl draw_lp_1
    ; mov [0xA010], byte 0xff
    ; jmp $
    ; mov eax, end_addr
    ; mov ebx, 0x80400000
    ; call kinit1

    ; call draw_pixel
    ; mov [0xb8000], byte 'X'

jmp $

%include "kernel/kalloc.asm"
%include "kernel/malloc.asm"
%include "kernel/panic.asm"
%include "kernel/spinlock.asm"
%include "kernel/string.asm"
%include "kernel/graphics_drivers/vga_serial_driver.asm"

MEM_START equ $
MEM_LEN equ 20*512 ; bytes

initial_memory_header:
    dd MEM_LEN ; length (size of free memory)
    db 0 ; Unallocated
    dd 0 ; No previous block
    dd 0 ; No next block

times MEM_LEN-BLOCK_HEADER_LENGTH db 0x00

; End of memory
MEM_END equ $
