%ifndef BOOT_SECTION
%define BOOT_SECTION

%include "boot_section/sector_sizes.asm"

[org 0x7c00]
[bits 16]
jmp short boot_section
nop

%include "fat/fat32_bpb.asm"

boot_section:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ax, 0x07e0 ;sets up stack
    cli
    mov ss, ax
    mov sp, 0x1200
    sti

    mov [boot_disk], dl
    mov bx, 0x1000
    mov dh, required_sectors

    call disk_load

    mov si, ss1_boot_msg
    call rm_print

    in al, 0x92 ;enable A20 line
    or al, 0x2
    out 0x92, al

    cli

    jmp 0x1000  ; Jump to kernel

jmp $

%include "common/rm_print.asm"
%include "boot_section/disk_load.asm"

ss1_boot_msg db 'Booted into ss1', 0x0D, 0x0A, 0
boot_disk db 0

times 510-($-$$) db 0
dw 0xaa55

%include "fat/fat32_fsinfo.asm"

kernel_start equ $

%endif
