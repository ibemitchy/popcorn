global long_mode_start
extern rust_main

section .text
bits 64
long_mode_start:
	; overwrites data segment offests of old 32-bit GDT
	mov ax, 0
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	call rust_main

	; prints 'OKAY' to screen
	mov rax, 0x2F592F412F4B2F4F
	mov qword [0xB8000], rax
	hlt
