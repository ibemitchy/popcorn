/* Notes: portions of memory under 1MiB mark are special (VGA buffer is at
   0xB8000), so we choose to load the kernel at 1MiB mark instead of 0x0 */

/* entry point to which bootloaders jumps after loading kernel */
ENTRY(start)

SECTIONS {
	. = 1M;	/* sets load address of first section to 1MiB*/

	.boot :
	{
		/* *(.multiboot_header) GRUB expects multiboot header near beginning of file */
		KEEP(*(.multiboot_header)) /* KEEP tells linker to keep multiboot header */
	}

	.text :
	{
		*(.text .text.*) /* all input sections named .text */
	}

	.rodata : {
        *(.rodata .rodata.*)
    }

    .data.rel.ro : {
        *(.data.rel.ro.local*) *(.data.rel.ro .data.rel.ro.*)
    }
}
