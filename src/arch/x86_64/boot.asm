; makes entry point public
global start
extern long_mode_start

section .text

; specifies that the following are 32-bit instructions
bits 32

start:
	; stack top is used since stack grows downwards (push subtracts, pop adds)
	mov esp, stack_top
	mov edi, ebx	; move Multiboot info pointer to edi

	; various checks
	call check_multiboot
	call check_cpuid
	call check_long_mode

	call set_up_page_tables
	call enable_paging

	lgdt [gdt64.pointer]	; load 64-bit GDT

	;update cs (code segment register) through jumps, cannot be done with mov
	jmp gdt64.code:long_mode_start

	; prints 'OK'
	mov dword [0xB8000], 0x2F4B2F4F
	hlt

; prints 'ERR: ' and the error code
; 0xB8000 begins the VGA buffer
; a character consists of a 1-byte colour code and a 1-byte ASCII character
; 0x4F524F45 means the characters 4F52 and 4F45:
;   - red R (4F is red, 52 is R)
;   - red E (4F is red, 45 is E)
error:
	mov dword [0xB8000], 0x4F524F45	; RE
	mov dword [0xB8004], 0x4F3A4F52	; :R
	mov word [0xB8008], 0x4F52		; (space)!!!TODO
	mov byte [0xB800A], al			; error code
	hlt

; multiboot specification requires bootloader to write magic value 0x36D76289
; to register 'eax' before loading  a kernel
check_multiboot:
	cmp eax, 0x36D76289
	jne .no_multiboot
	ret
.no_multiboot:
	mov al, "0"
	jmp error

; CPU information check. Not all processors support it, so we test this by attempting
; to flip ID bit (bit 21). If this can be flipped, CPUID is available.
check_cpuid:
	; push FLAGS onto stack, then pop FLAGS value
	pushfd
	pop eax

	; preserve eax value for later comparison
	mov ecx, eax

	; flip ID bit by xor-ing at the 21st bit
	xor eax, 1 << 21

	; push and pop flipped value from stack into FLAGS
	push eax
	popfd

	; get FLAGS value again (should be flipped if CPUID is supported)
	pushfd
	pop eax

	; restore old FLAGS
	push ecx
	popfd

	; compare
	cmp eax, ecx
	je .no_cpuid
	ret
.no_cpuid:
	mov al, "1"
	jmp error

; use CPUID to check if long mode can be used.
; Long mode is supported if the 29th bit in 'edx' is set.
check_long_mode:
	; test if old CPU knows 0x80000001 argument
	mov eax, 0x80000000	; implicit argument for CPUID at eax
	cpuid				; gets highest supported argument
	cmp eax, 0x80000001	; needs to be at least 0x80000001
	jb .no_long_mode	; if less, no long mode

	; extended test
	mov eax, 0x80000001	; implicit argument for CPUID at eax
	cpuid				; loads information to 'ecx' and 'edx'
	test edx, 1 << 29	; test if LM-bit is set in 'edx'
	jz .no_long_mode	; jz functionally same as je (nuance: jz tests for 0)
	ret
.no_long_mode:
	mov al, "2"
	jmp error

set_up_page_tables:
	; map first PML4 entry to PDP
	mov eax, PDP
	or eax, 0b11	; first bit: present, second bit: writable
	mov [PML4], eax

	; map first PDP entry to PD
	mov eax, PD
	or eax, 0b11
	mov [PDP], eax

	; map each PD entry to a huge 2MiB page
	mov ecx, 0	; counter

.map_PD:
	mov eax, 0x200000	; 2MiB
	mul ecx				; 'eax' = 'eax' * 'ecx'
	or eax, 0b10000011	; present, writable, huge bits
	mov [PD + ecx * 8], eax

	; loop 512 times
	inc ecx
	cmp ecx, 512
	jne .map_PD

	ret

enable_paging:
	; load PML4 to 'cr3' register
	mov eax, PML4
	mov cr3, eax

	; enable PAE (physical address extension) flag in 'cr4'
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; set long mode bit in EFER MSR (model specific register)
	mov ecx, 0xC0000080
	rdmsr	; read MSR specified by 'ecx' into 'eax'
	or eax, 1 << 8
	wrmsr	; write value of 'eax' to MSR specified by 'ecx'

	; enable paging in 'cr0' register
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	ret

; stack, resb (reserve byte) stores the length of uninitialized data (64)
section .bss
; aligned to page size
align 4096
PML4:
	resb 4096
PDP:
	resb 4096
PD:
	resb 4096
stack_bottom:
	resb 4096 * 4
stack_top:

; read-only data
; code segments must have bits: descriptor type, present, executable, 64-bit flag
section .rodata
gdt64:
	dq 0
.code: equ $ - gdt64
	dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53)
.pointer:
	dw $ - gdt64 - 1	; $ means current address
	dq gdt64
