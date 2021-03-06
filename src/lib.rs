#![feature(lang_items)]
#![feature(const_fn)]
#![feature(unique)]
#![feature(const_unique_new)]
#![no_std]

extern crate multiboot2;
extern crate rlibc;
extern crate spin;
extern crate volatile;

use core::fmt::Write;

#[macro_use]
mod memory;
mod vga_buffer;

#[no_mangle]
pub extern fn rust_main(multiboot_information_address: usize) {
    // ATTENTION: we have a very small stack and no guard page
    vga_buffer::clear_screen();
    println!("Hello World{}", "!");
	
	let boot_info = unsafe{ multiboot2::load(multiboot_information_address) };
	let memory_map_tag = boot_info.memory_map_tag()
		.expect("Memory map tag required");

	println!("memory areas:");
	for area in memory_map_tag.memory_areas() {
	    println!("    start: 0x{:x}, length: 0x{:x}",
			area.base_addr, area.length);
	}

	let elf_sections_tag = boot_info.elf_sections_tag()
	    .expect("Elf-sections tag required");

	println!("kernel sections:");
	for section in elf_sections_tag.sections() {
	    println!("    addr: 0x{:x}, size: 0x{:x}, flags: 0x{:x}",
	        section.addr, section.size, section.flags);
	}

    loop{}
}

#[lang = "eh_personality"]
extern fn eh_personality() {}

#[lang = "panic_fmt"]
#[no_mangle]
pub extern fn panic_fmt(fmt: core::fmt::Arguments, file: &'static str,
    line: u32) -> ! {
    println!("\n\nPANIC in {} at line {}:", file, line);
    println!("    {}", fmt);
    loop{}
}