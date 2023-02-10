	.intel_syntax noprefix
	.code16
	.section ".stage2", "ax"

.macro DEBUG
	xchg bx, bx
.endm

.stage2Begin:
	DEBUG
	jmp .
