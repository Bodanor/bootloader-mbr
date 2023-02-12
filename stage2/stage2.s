	.intel_syntax noprefix
	.code16
	.section ".stage2", "ax"

.macro DEBUG
	xchg bx, bx
.endm

/* Loading the FAT to read the KERNEL data in memory */

loadFat:
	mov ax, 0xe00
	mov es, ax

computeFatOffset:
	mov ax, word ptr iResSect
	add ax, word ptr iHiddenSect
	adc ax, word ptr iHiddenSect+2
	DEBUG

loadFatInMem:
	mov word ptr[DAP_lower_32], ax
	mov word ptr[DAP_dest_buffer], 0x00
	mov word ptr[DAP_dest_buffer + 2], es

	mov bx, iFatSize
	mov word ptr[DAP_nb_sectors], bx
	mov ah, 0x42
	mov dl, byte ptr[bootDrive]
	mov si, offset flat:DAP
	int 0x13
	jc BootDiskErrorReadMsg

loadKernel:
	mov ax, 0xe01
	mov es, ax
	mov si, word ptr[KernelOffsetStartFile]
	mov cx, word ptr[si]
	xor bx, bx
	mov bx, 0x10

loadkernelNextSector:
	mov ax, cx
	add ax, root_sectors
	add ax, root_start_pos
	sub ax, 2
loadCurrentKernelSector:
	mov word ptr[DAP_lower_32], ax
	mov word ptr[DAP_dest_buffer], bx
	mov word ptr[DAP_dest_buffer + 2], 0xffff
	mov word ptr[DAP_nb_sectors], 0x1
	mov ah, 0x42
	mov dl, byte ptr[bootDrive]
	mov si, offset flat:DAP
	int 0x13
	jc BootDiskErrorReadMsg
	
	add bx, iSectSize

	push ds
	mov dx, 0xe00
	mov ds, dx

	mov si, cx
	
	DEBUG
	mov dx, ds:[si]
	test cx, 1
	jnz read_next_cluster_odd
	and dx, 0x0ffff
	jmp read_next_cluster_done
read_next_cluster_odd:
	shr dx, 4

read_next_cluster_done:
	pop ds
	mov cx, dx
	cmp cx, 0xff8
	jl loadkernelNextSector
DEBUG
jmp .
