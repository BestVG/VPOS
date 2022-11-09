# VPOS
VPOS is an operating system designed (primarily for fun) with the end goal of creating an OS from scratch. We hope to eventually implement advanced features such as native shared library linking support, a GUI interface, etc. with minimal support from existing tutorials, so we can arrive at our own solutions and, hopefully, learn a lot about the methodology and issues which arise through this development.

At the moment, we are busy with other things in life, so changes will be slow for now. Expect more rapid development to return in Summer 2023.

## Memory Layout
We are working on migrating the built live-image file to be a functional FAT-32 partition. At the moment, is arranged as follows:

1st sector (loaded to `0x7C00`): boot_section (Contains some FAT-32 metadata; ends with word `0xaa55`)  
2nd sector: FS_INFO sector (More FAT-32 metadata)  
(dynamic) (loaded to `0x1000`): kernel code (Note: due to the dynamic nature of kernel code, the following sections may not fall exactly on sector boundaries)  
Next 2 sectors (1024 bytes): Reserved for the stack  
Next 10 sectors (5120 bytes): Reserved for malloc (heap)  
After this, any remaining space in the sector is padded with `0x00`  
Memory Map (Will be loaded from BIOS into `0x8000`)  
Page Tables (Will be generated at `0x100000`)  

## Boot Process
At the moment, the process for booting the OS is as follows:

1. Begin Program
2. Jump over FAT_32 metadata
3. Setup a small stack (`ss = 0x07e0` `sp = 0x1200`)
4. Load the kernel from disk (to `0x1000`)
5. Enable [`A20 line`](https://wiki.osdev.org/A20_Line)
6. Jump to kernel
7. Make sure CPU supports all required features (See [Feature Checks](#feature-checks))
8. Load the memory map from BIOS (into `0x8000`) (See [`int 0x15, eax=0xE820'`](https://wiki.osdev.org/Detecting_Memory_(x86)#BIOS_Function:_INT_0x15.2C_EAX_.3D_0xE820))
9. Load [GDT](https://wiki.osdev.org/Global_Descriptor_Table)
10. Enable protected mode in [`cr0`](https://wiki.osdev.org/CPU_Registers_x86#CR0)
11. Set all segment registers (besides CS) to the data segment
12. Update the 32-bit stack pointer to use the stack defined in the kernel
13. Enable Physical Address Extensions (PAE) in [`cr4`](https://wiki.osdev.org/CPU_Registers_x86#CR4)
14. Generate page tables (starting at `0x100000`)
15. Store page table location in [`cr3`](https://wiki.osdev.org/CPU_Registers_x86#CR3)
16. Enable long mode in [`EFER_MSR`](https://wiki.osdev.org/Model_Specific_Registers#Additional_x86_64_Registers)
17. Enable paging in [`cr0`](https://wiki.osdev.org/CPU_Registers_x86#CR0)
18. Jump to 64-bit kernel code
19. Reset 64-bit stack pointer to the kernel stack
20. Jump to kernel_main

## Feature Checks
1. Check that the CPU supports [`cpuid`](https://wiki.osdev.org/CPUID) by [changing the CPUID bit](https://wiki.osdev.org/CPUID#Checking_CPUID_availability) in [`EFLAGS`](https://wiki.osdev.org/EFLAGS#EFLAGS_Register)
2. Check that the CPU's vendor id matches "`AuthenticAMD`" or "`GenuineIntel`" (`eax = 0x00` should return valid values in `ebx` `edx` and `ecx`)
3. Check that the `cpuid` instruction supports all of the `leaves` required to check the remaining features (`eax = 0x00` should return `eax >= 0x80000008`)
4. Check that long mode is supported (`eax = 0x80000001` should return `edx & 0x20000000 = 0x20000000`)
5. Check that model specific registers are supported (`eax = 0x1` should return `edx & 0x00000020 = 0x00000020`)
6. Check that all required paging features are supported (PSE, PAE, PAT, and PSE36) (`eax = 0x1` should return `edx & 0x00030048 = 0x00030048`)
7. Check that [APIC](https://wiki.osdev.org/APIC) is supported (`eax = 0x1` should return `edx & 0x0000200 = 0x0000200`)

If any of the above checks fail, the user will be notified and given the option to ignore the error (at risk).

## Building/Running
The [`Makefile`](Makefile) contains the following targets

`build`: Builds the `bin/live-image` binary which contains the compiled OS  
`clean`: Deletes the `bin` directory, effectively removing the binaries from all previous builds  
`rebuild`: Runs `clean` followed by a `build`  
`run`: Attempts to build and run the `live-image` using [QEMU](https://www.qemu.org/)  
`debug`: Attempts to build and run the `live-image` using QEMU with `guest_errors` logging enabled to `log.txt`  
`disk`: Builds the `live-image` and packages it in `bin/disk.vdi`  
`run-vbox`: Builds `bin/disk.vdi` and attempts to start a `VPOS` vm in [VirtualBox](https://www.virtualbox.org/). (This assumes that a vm named `VPOS` is already configured in VirtualBox)  
`*.mem`: Connects to a running VirtualBox machine and dumps the memory to the requested file  
