	.intel_syntax noprefix
	.code16
	.section ".stage2", "ax"

.macro DEBUG
	xchg bx, bx
.endm

stage2_begin:
	mov bx, offset flat:Stage2Msg
	call print_string
	
/* Computing Root Directory offset in order to find the kernel start cluster */

	call computeRootSectors
	call computeRootOffset
	call CheckKernelPresence
	cmp ax, 0
	je KernelFounded
	jmp BootKernelNotFound

KernelFounded:
	mov bx, offset flat:KernelFoundMsg
	call print_string
	
	mov bx, offset flat:stage2MsgLoading
	call print_string

	mov ebx, dword ptr iHiddenSect
	inc ebx
	mov dword ptr[DAP_lower_32], ebx
	inc word ptr[DAP_lower_32]
	mov word ptr[DAP_dest_buffer], 0x9000
	mov word ptr[DAP_nb_sectors], 0x1

	mov ah, 0x42
	mov dl, byte ptr[bootDrive]
	mov si, offset flat:DAP
	int 0x13
	jc BootDiskErrorReadMsg
	jmp 0x9000

computeRootSectors:
	mov ax, 32
	xor dx, dx
	mul word ptr iRootSize
	add ax, word ptr iSectSize 		# formula is (32*root_size + bytes_per_sector -1)/ bytes_per_sector. So we add this value
	dec ax 							# Then we dec by one to get bytes_per_sector -1 before dividing
	div word ptr iSectSize
	mov cx, ax
	mov word ptr root_sectors, cx
	ret

computeRootOffset:
	xor ax, ax
	mov al, byte ptr iFatCnt
	mov bx, word ptr iFatSize
	mul bx
	add ax, word ptr iHiddenSect
	adc ax, word ptr iHiddenSect+2
	add ax, word ptr iResSect
	mov word ptr root_start_pos, ax
	ret
	
/*
 * Check if the KERNEL.BIN entry is in the root directory
 * If it is this function returns 0 and set the variable KernelClusterStart
 * To the one present int the root directory. Return 1 if KERNEL.BIN not in the RD
 *
*/


CheckKernelPresence:

init:
	mov si, word ptr root_start_pos
	xor ax, ax

/*
 * We load one sector at a time from the root directory
 * Always at offset 0x0000:0x8000
 *
*/

.loadSector:
	push si
	mov word ptr [DAP_lower_32], si
	mov word ptr[DAP_dest_buffer], 0x8000
	mov cx, 1
	mov word ptr[DAP_nb_sectors], cx

	mov ah, 0x42
	mov dl, byte ptr[bootDrive]
	mov si, offset flat:DAP
	int 0x13
	jc BootDiskErrorReadMsg
	
	xor di, di
	xor dx, dx
	xor cx, cx
	mov si, 0x8000

.findKernel:
	/* Save the current Cluster number of the current entry we are reading from the Root Directory */
	push si
	push bx
	add si, 0x1a /* Cluster number starts at offset 26 from the beginning of the entry */
	mov bl, byte ptr[si]
	mov byte ptr[KernelClusterStart], bl
	pop bx
	pop si
	
/* From offset 0-8 is the filename and from 9-11 is the extention file */

/* SI : Contains the root offset.
 * DX : Current index in the current loaded sector, always a multiple of 32
 * DI : Current index in the filename entry in the current root directory entry 
*/
.loopKernel:
	cmp cx, 11 			/* if at the end of filename max lenght */
	je compareKernelFile
	mov bl, byte ptr[si]
	cmp bl, 0x20 		/* If a blank character we delete it */
	je .skipBlank
	cmp cx, 8
	je .addDot 			/* If we are at the end of the filename we just add a "." */
	mov byte ptr[di + CurrentTargetFileName], bl
	jmp .incLoop

.addDot:
	mov byte ptr[di + CurrentTargetFileName], 0x2e
	inc di
	mov byte ptr[di + CurrentTargetFileName], bl
	jmp .incLoop

.skipBlank:
	dec di
.incLoop:
	inc si
	inc di
	inc cx
	jmp .loopKernel

/* This routine just compares 2 given string, kind like strcmp does */
compareKernelFile:
	push si
	xor cx, cx
	mov di, offset flat:CurrentTargetFileName
	mov si, offset flat:TargetKernelFileName
	xor cx, cx

.loop:
	cmp cx, 10
	je KernelFoundInRoot
	mov bl, byte ptr[di]
	cmp bl, byte ptr[si]
	jne .fileNotMatch
	inc di
	inc si
	inc cx
	jmp .loop

/* If the two filenames do not correspond we then load the next entry in the RD */
.fileNotMatch:
	pop si
	jmp nxt_file_entry

/* If we are here then a file called KERNEL.BIN has been found, we return 0 */
KernelFoundInRoot:
	DEBUG
	mov ax, 0
	pop si
	pop si
	ret

nxt_file_entry:
	add dx, 0x20
	cmp dx, 512 		/* Are we at then end of the current loaded sector ? (512 bytes) */
	je incRootEntry 	
	xor di, di
	xor cx, cx
	add si, 0x15 		/* If not, then we loop all over again and increment si by 0x15 ( here we are at offset 11 thus we add 0x15 to get to 32  */
	jmp .findKernel 	/* Which is the next entry as they are 32 bits long ) */

incRootEntry:
	cmp ax, word ptr root_sectors 	/* Did we load the whole Root Directory ? */
	je NoMoreFiles 					/* If yes, then KERNEL.BIN has not been found, we abord booting!!!! */
	pop si
	inc si
	inc ax
	jmp .loadSector 				/* If not, simply load the next sector */

NoMoreFiles:
	mov ax, 1 						/* Return 1 as KERNEL.BIN has not been found !! */
	pop si
	ret


BootDiskErrorReadMsg:
	mov bx, offset flat:BootErrorMsg
	call print_string
	jmp CPU_HLT_ABORT_BOOT

BootKernelNotFound:
	mov bx, offset flat:KernelNotFoundMsg
	call print_string

CPU_HLT_ABORT_BOOT:
	cli
	hlt
	jmp .

Stage2Msg:
	.asciz "Entered stage 2 !\n"

KernelFoundMsg:
	.asciz "KERNEL.BIN file found !\n"
KernelNotFoundMsg:
	.asciz "KERNEL.BIN not found !\nAbording BOOT\n"
BootErrorMsg:
	.asciz "Could not load sector !\n"
TargetKernelFileName:
	.ascii "KERNEL.BIN"
CurrentTargetFileName:
	.ascii "            "
stage2MsgLoading:
	.asciz "Loading Stage 2...\n"
root_sectors:
	.word 0
root_start_pos:
	.word 0
KernelClusterStart:
	.byte 0


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
