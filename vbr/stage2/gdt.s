	.intel_syntax noprefix
	.code16
	.section ".gdt", "ax"

.global gdt_descriptor
.global CODE_SEG
.global DATA_SEG

gdt_start:
	.int 0x0
	.int 0x0

gdt_code:
	.word 0xffff
	.word 0x0
	.byte 0x0
	.byte 0b10011010
	.byte 0b11001111
	.byte 0x0

gdt_data:
	.word 0xffff
	.word 0x0
	.word 0x0
	.byte 0b10010010
	.byte 0b11001111
	.byte 0x0
gdt_end:

gdt_descriptor:
	.word gdt_end -gdt_start -1
	.int offset flat:gdt_start

.set CODE_SEG, gdt_code-gdt_start
.set DATA_SEG, gdt_data-gdt_start

