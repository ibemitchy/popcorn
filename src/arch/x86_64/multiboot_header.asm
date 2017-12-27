;db - define byte
;dw - define word (2 bytes) (word is 2 bytes but dword is 4 bytes)
;dd - define double (4 bytes on x86)
;dq - define quadword (8 bytes)
;checksum is: BIGNUM - (MAGIC + ARCHITECTURE + HEADER LENGTH)
;    since -(MAGIC + ...) is out of the range of 4 bytes, we need BIGNUM
;    to keep the checksum within the range

section .multiboot_header
header_start:
	dd 0xE85250D6	;magic number for multiboot 2 (0x1BADB002 for multiboot 1)
	dd 0x0	;architecture 0 (protected mode i386)
	dd header_end - header_start	;length of header
	;checksum
	dd 0x100000000 - (0xE85250D6 + 0x0 + (header_end - header_start))

	;required end tags
	dw 0x0		;type
	dw 0x0		;flags
	dd 0x8	;size
header_end:
