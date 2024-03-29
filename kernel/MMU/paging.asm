%ifndef KERNEL_MMU_PAGING
%define KERNEL_MMU_PAGING

[bits 64]

%include "kernel/MMU/kalloc.asm"

map_region: ; rax: start address, rbx: virtual address, rcx: flags, rdx: length, EFLAGS.C: set on error
    test rax, 4*4096-1
    jnz .error
    test rbx, 4*4096-1
    jnz .error
    test rdx, 4*4096-1
    jnz .error

    push rax
    push rbx
    push rdx
    push r8
    push r9

    lea rdx, [rax+rdx]

    test rax, 2*1024*1024-1
    jnz .small_pages
    test rbx, 2*1024*1024-1
    jnz .small_pages
    test rdx, 2*1024*1024-1
    jnz .small_pages

    .large_pages:
    mov r8, 2*1024*1024
    mov r9, 1
    jmp .map

    .small_pages:
    mov r8, 4*4096
    xor r9, r9

    .map:
    xchg rdx, r9

    .loop:
        call map_page
        add rax, r8
        add rbx, r8
        cmp rax, r9
        jb .loop

    pop r9
    pop r8
    pop rdx
    pop rbx
    pop rax
    clc
    ret

    .error:
        stc
        ret


map_page: ; rax: linear address, rbx: virtual address, rcx: flags, rdx: 1 for 2 MiB page, 0 for 4 KiB page (other values result in undefined behavior)
    push rcx
    push rdx
    shl rdx, 7 ; Set the page size bit if needed
    or rcx, rdx
    or rcx, 1 ; Set the present bit
    pop rdx

    push r8
    push rsi

    push rax

    mov r8, cr3

    %define PML4E 39
    %define PDPTE 30
    %define PDE 21
    %define PTE 12

    %macro allocate 1 ; param: offset
        mov rax, rbx
        shr rax, %1
        and rax, 511
        lea rsi, [r8+rax*8]
        %if %1 = PML4E
            test rdx, rdx
            jnz .map_page
        %endif

        %if %1 != PTE
            mov r8, [rsi]
            btr r8, 63 ; Clear the execute disable bit
            test r8, 1
            jz %%allocate

            and r8, ~4095 ; Clear flags
            jmp %%allocated

            %%allocate:
            call kalloc
            mov [rsi], rax
            mov r8, rax
            or [rsi], byte 7 ; Set present, read/write, and user bits

            %%allocated:
        %endif
    %endmacro

    allocate {PML4E} ; Allocate PML4E (PDPT)
    allocate {PDPTE} ; Allocate PDPTE (PD)
    allocate {PDE} ; Allocate PDE (PT)
    allocate {PTE} ; Get PTE Address

    %unmacro allocate 1

    %undef PML4E
    %undef PDPTE
    %undef PDE
    %undef PTE

    .map_page:
    pop rax

    or rcx, rax
    mov [rsi], rcx

    .done:
    pop rsi
    pop r8

    pop rcx
    ret

%endif
