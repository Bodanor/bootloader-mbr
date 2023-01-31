	.intel_syntax noprefix
	.code16
	.section .stage1_nxt, "ax"

.stage1_next:
	mov bx, offset flat:NextSectorMsg
	call print_string
	jmp .




NextSectorMsg:
	.asciz "Next sector !\n"
	


