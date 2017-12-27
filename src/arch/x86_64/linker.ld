/* Notes: portions of memory under 1MiB mark are special (VGA buffer is at
   0xB8000), so we choose to load the kernel at 1MiB mark instead of 0x0 */

/* entry point to which bootloaders jumps after loading kernel */
ENTRY(start)

SECTIONS {
	. = 1M;	/* sets load address of first section to 1MiB*/

	.boot :
	{
		*(.multiboot_header) /* GRUB expects multiboot header near beginning of file */
	}

	.text :
	{
		*(.text) /* all input sections named .text */
	}
}
