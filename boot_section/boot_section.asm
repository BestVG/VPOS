[org 0x7c00]
[bits 16]

xor  ax, ax
mov  ds, ax
mov  es, ax


mov  ax, 0x07e0 ;sets up stack
cli
mov  ss, ax
mov  sp, 0x1200
sti

mov [boot_disk], dl
mov bx, 0x1000
mov dh, 0
mov ch, 0
mov cl, 0x02
mov dl, [boot_disk]

call disk_load

mov si, ss1_boot_msg
call rm_print

in al, 0x92 ;enable A20 line
or al, 0x2
out 0x92, al

cli

jmp 0x1000  ; Jump to kernel

jmp $

%include "rm_print.asm"
%include "disk_load.asm"

ss1_boot_msg db 'Booted into ss1', 0x0D, 0x0A, 0
boot_disk db 0

times 510-($-$$) db 0
dw 0xaa55
