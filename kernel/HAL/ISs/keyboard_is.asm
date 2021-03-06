keyboard_install_is:
    pushad
    
    mov cl, 33
    mov ebx, keyboard_isr
    mov si, 0x8
    mov ch, I86_IDT_DESC_PRESENT
    or ch, I86_IDT_DESC_BIT32
    call idt_set_ISR

    popad
    ret


keyboard_isr:
    add esp, 12
    pushad
    cli

    mov dx, keyboard_CTRL_command_reg
    in al, dx
    cmp al, 0
    je .return

    cmp keyboard_CTRL_STATS_mask_out_buffer, 0
    je .return

    

    .return:

    mov cl, 0
    call pic_interupt_done

    sti
    popad
    iretd

keyboard_enc_input_buffer equ 0x60
keyboard_CTRL_command_reg equ 0x64
keyboard_CTRL_STATS_mask_out_buffer equ 1
