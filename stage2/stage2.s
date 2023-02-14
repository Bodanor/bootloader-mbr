	.intel_syntax noprefix
	.code16
	.section ".stage2", "ax"

.macro DEBUG
	xchg bx, bx
.endm

/* Loading the FAT to read the KERNEL data in memory 
 * FAT Table will be loaded at 0xe00:0x0000
 * Kernel will be loaded at 0x0fff:0x0010 --> 0x10000
 */
loadFat:
	mov ax, 0xe00
	mov es, ax

computeBeginningFatOffset:
	mov ax, word ptr iResSect
	add ax, word ptr iHiddenSect
	adc ax, word ptr iHiddenSect+2

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
	/* Init loading kernel */
	mov ax, 0xe01
	mov es, ax
	mov cl, byte ptr[KernelClusterStart]
	xor bx, bx
	mov bx, 0x10
	
loadkernelCluster:
	/* Compute exact sector number to read data based on cluster */
	push cx
	mov ax, cx
	sub ax, 2
	xor cx, cx
	mov cl, byte ptr iClustSize
	mul cx

	add ax, root_sectors
	add ax, root_start_pos
	
	mov word ptr[DAP_lower_32], ax
	mov word ptr[DAP_dest_buffer], bx
	mov word ptr[DAP_dest_buffer + 2], 0x0fff
	xor cx, cx
	mov cl, byte ptr[iClustSize]
	mov word ptr[DAP_nb_sectors], cx
	mov ah, 0x42
	mov dl, byte ptr[bootDrive]
	mov si, offset flat:DAP
	int 0x13
	jc BootDiskErrorReadMsg
	xor ax, ax
	mov al, byte ptr [iClustSize]
	mov cx, word ptr[iSectSize]
	mul cx
	add bx, ax
	
read_next_cluster_in_FAT:
	pop si
	push bx
	push ds
	mov ax, 0xe00
	mov ds, ax
	mov bx, 0x0000
	shl si # 2 bytes in address
	mov cx, word ptr[bx + si]
	pop ds
	pop bx
	
	cmp cx, 0xffff
	je read_next_cluster_done

	jmp loadkernelCluster

read_next_cluster_done:
	mov bx, offset flat:KernelLoadSuccessMsg
	call print_string
	jmp .
KernelLoadSuccessMsg:
	.asciz "Kernel loaded at offset 0x10000\n"
