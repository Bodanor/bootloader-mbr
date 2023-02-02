	.intel_syntax noprefix
	.code16
	.section ".stage1_nxt", "ax"

.stage1_next:
	mov bx, offset flat:NextSectorMsg
	call print_string
	jmp .



.compute_root_sectors:
	mov ax, 32
	xor dx, dx
	mul word ptr iRootSize

NextSectorMsg:
	.asciz "Next sector !\n"

root_sectors:
	.word 0
root_start_pos:
	.int 0



