.intel_syntax noprefix
	.code16
	.section .stage1, "ax"
	.global _start
	.type _start,@function

.macro DEBUG
	xchg bx, bx
.endm

.global iOEM
.global iSectSize
.global iClustSize
.global iResSect
.global iFatCnt
.global iRootSize
.global iTotalSect
.global iMedia
.global iFatSize
.global iTrackSect
.global iHeadCnt
.global iHiddenSect
.global iSect32
.global iBootDrive
.global iReserved
.global iBootSign
.global iVolID
.global acVolumeLabel
.global acFSType

_start:
	
	jmp _start_16
	nop

BPB:
	/* Start of the BPB, I'll be using a fake one as when copied to a USB drive, the correct ones will replace the fakes one */
	iOEM:          .ascii "NO NAME "  	# OEM String
  	iSectSize:     .word  0x0         		# bytes per sector
  	iClustSize:    .byte  0x0 				# sectors per cluster
  	iResSect:      .word  0x0 				# #of reserved sectors
  	iFatCnt:       .byte  0x0             	# #of FAT copies
  	iRootSize:     .word  0x0           	# size of root directory
  	iTotalSect:    .word  0x0       		# total # of sectors if over 32 MB
  	iMedia:        .byte  0x0         		# media Descriptor
  	iFatSize:      .word  0x0             	# size of each FAT
  	iTrackSect:    .word  0x0             	# sectors per track
  	iHeadCnt:      .word  0x0             	# number of read-write heads
  	iHiddenSect:   .int   0x0             	# number of hidden sectors
  	iSect32:       .int   0x0             	# # sectors for over 32 MB
  	iBootDrive:    .byte  0x0             	# holds drive that the boot sector came from
  	iReserved:     .byte  0x0             	# reserved, empty
  	iBootSign:     .byte  0x0    	      	# extended boot sector signature
	iVolID:        .ascii "seri"        	# disk serial
	acVolumeLabel: .ascii "MYVOLUME   " 	# volume label
	acFSType:      .ascii "FAT16   "    	# file system type

_start_16:
	ljmp 0x0000:_init

_init:
	cli
	
	mov byte ptr [bootDrive], dl # Save the bootDrive number we booted from.
	xor ax, ax
	mov es, ax
	mov fs, ax
	mov ss, ax
	mov gs, ax
	mov ds, ax

	mov bp, 0x7c00
	mov sp, bp
	
	
	mov bx, offset flat:FirstStageMsg
	call print_string


	call .checkA20_Line
	cmp al, 0
	jne .AfterA20Enabled
	
	mov bx, offset flat:A20DisabledMsg
	call print_string
	
	/* Enable A20 with BIOS Interrupt */

	call .enableA20Gate_BIOS
	call .checkA20_Line
	cmp al, 0
	jne .AfterA20Enabled
	/* Enable A20 with Keyboard Method */
	
	call .enableA20Gate_Keyboard
	call .checkA20_Line
	cmp al, 0
	jne .AfterA20Enabled
	

BootErrorA20:
	mov bx, offset flat:A20FatalErrorMsg
	call print_string
	hlt
	jmp .

.AfterA20Enabled: /* One of the above function to enable A20 worked */
	mov bx, offset flat:A20EnabledMsg
	call print_string

.LoadNextSector:

	mov ebx, dword ptr iHiddenSect
	mov dword ptr[DAP_lower_32], ebx
	inc word ptr[DAP_lower_32]
	mov word ptr[DAP_dest_buffer], 0x7e00
	mov word ptr[DAP_nb_sectors], 0x1

	mov ah, 0x42
	mov dl, byte ptr[bootDrive]
	mov si, offset flat:DAP
	int 0x13
	jc BootErrorA20
	jmp 0x7e00


/* 	This routines check wether the A20 line is enabled or not
 *  On return :
 *				AX == 0 : A20 line disabled  
 *				AX == 0 : A20 line enabled, nothing to be done
 */

.checkA20_Line:
	xor ax, ax # AX == 0x0
	mov ds, ax
	not ax 	   # AX == 0xffff
	mov es, ax

	mov di, 0x7dfe 
	mov si, 0x7e0e

	mov al, byte ptr ds:[di] # When get the 510 byte of the first sector which sould be the beginning of the magick number : 0x55
	push ax # We will need this ax value later when we check the value again
	cmp al, byte ptr es:[si] # Did memory wrapped around ? If so, A20line is not enabled, we should do so !!!
	
	mov bx, 1
	jne .potentielly_not_enabled
	mov bx, 0

.potentielly_not_enabled:
	/* Here we check if we didn't compare with the same value by mere chance. So we actually change the value and cmp again */
	mov byte ptr ds:[di], 0xff
	mov al, byte ptr ds:[di]
	cmp al, byte ptr es:[si]
	
	pop ax
	mov byte ptr ds:[di], al

	je .skip_a20
	mov bx, 1

.skip_a20:
	mov ax, bx
	ret

/* This is a routine to enable the a20 line if not already enabled ! */

.enableA20Gate_BIOS:
	mov ax, 0x2403
	int 0x15
	jb .a20_bios_not_supported
	cmp ah, 0
	jnz .a20_bios_not_supported
	
	mov ax, 0x2402
	int 0x15
	jb .a20_bios_not_supported
	cmp ah, 0
	jnz .a20_bios_not_supported

	cmp al, 1
	jz .a20Gate_BIOS_End

	mov ax, 0x2401
	int 0x15
	jb .a20_bios_not_supported
	cmp ah, 0
	jnz .a20_bios_not_supported
	jmp .a20Gate_BIOS_End

.a20_bios_not_supported:

.a20Gate_BIOS_End:
	ret

.enableA20Gate_Keyboard:
	cli
	call .a20wait
	mov al, 0xAD
	out 0x64, al

	call .a20wait
	mov al, 0xD0
	out 0x64, al
	
	call .a20wait2
	in al, 0x60
	push eax
	
	call .a20wait
	mov al, 0xD1
	out 0x64, al

	call .a20wait
	pop eax
	or al, 2
	out 0x60, al

	call .a20wait
	mov al, 0xAE
	out 0x64, al

	call .a20wait
	sti
	ret
.a20wait:
	in al, 0x64
	test al, 2
	jnz .a20wait
	ret

.a20wait2:
	in al, 0x64
	test al, 1
	jnz .a20wait2
	ret

FirstStageMsg:
	.asciz "First Stage loaded !\n"
A20EnabledMsg:
	.asciz "A20 Gate enabled !\n"
A20DisabledMsg:
	.asciz "A20 Gate disabled\n"
A20FatalErrorMsg:
	.asciz "Could not enable A20 Gate\nAbording BOOT !"
.global bootDrive
bootDrive:
	.byte 0

.global DAP
.global DAP_packet_size
.global DAP_reserved
.global DAP_nb_sectors
.global DAP_dest_buffer
.global DAP_lower_32
.global DAP_upper_16

DAP:

DAP_packet_size:
	.byte 0x10
DAP_reserved:
	.byte 0x0
DAP_nb_sectors:
	.word 0x0
DAP_dest_buffer:
	.int 0x0
DAP_lower_32:
	.int 0x0
DAP_upper_16:
	.int 0x0



/* From here, we have successfully enabled the A20gate and now we read the FAT filesystem to load the kernel
 * Then, we can load the GDT, switch to protected mode and finally jump to the kernel
 */

.section .stage1_nxt, "ax"

stage1_next:
	mov bx, offset flat:NextSectorMsg
	call print_string
	call compute_root_sectors
	call compute_root_location
	call showFilesRoot
	cmp ax, 0
	je KernelFound
	
	jmp BootKernelNotFound

KernelFound:
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

compute_root_sectors:
	mov ax, 32
	xor dx, dx
	mul word ptr iRootSize
	add ax, word ptr iSectSize 		# formula is (32*root_size + bytes_per_sector -1)/ bytes_per_sector. So we add this value
	dec ax 							# Then we dec by one to get bytes_per_sector -1 before dividing
	div word ptr iSectSize
	mov cx, ax
	mov word ptr root_sectors, cx
	ret

compute_root_location:
	xor ax, ax
	mov al, byte ptr iFatCnt
	mov bx, word ptr iFatSize
	mul bx
	add ax, word ptr iHiddenSect
	adc ax, word ptr iHiddenSect+2
	add ax, word ptr iResSect
	mov word ptr root_start_pos, ax
	ret

showFilesRoot:
.init:
	mov si, word ptr root_start_pos
	xor ax, ax
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
	
	/* SI : Contains the LBA of the first sector
	 * DX : Current index in the current loaded sector
	 * DI : Current index in target file name
	 * CX : Current index in current filename
	 */

	xor di, di
	xor dx, dx
	xor cx, cx
	mov si, 0x8000

.findKernel:
	push si
	add si, 0x1a
	mov word ptr[KernelOffsetStartFile], si
	pop si
.loopKernel:
	cmp cx, 11 # if at the end of filename max lenght
	je compareKernelFile
	mov bl, byte ptr[si]
	cmp bl, 0x20
	je .skipBlank
	cmp cx, 8
	je .addDot
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

compareKernelFile:
	push si
	xor cx, cx
	mov di, offset flat:CurrentTargetFileName
	mov si, offset flat:TargetKernelFileName
	xor cx, cx

.loop:
	cmp cx, 10
	je .compareKernelFileEnd
	mov bl, byte ptr[di]
	cmp bl, byte ptr[si]
	jne .fileNotMatch
	inc di
	inc si
	inc cx
	jmp .loop

.fileNotMatch:
	pop si
	jmp nxt_file_entry
.compareKernelFileEnd:
	mov ax, 1
	pop si
	jmp .KernelFound

nxt_file_entry:
	add dx, 0x20
	cmp dx, 512
	je incRootEntry
	xor di, di
	xor cx, cx
	add si, 0x15
	jmp .findKernel

incRootEntry:
	cmp ax, word ptr root_sectors
	je NoMoreFiles
	pop si
	inc si
	inc ax
	jmp .loadSector

NoMoreFiles:
	DEBUG
	mov ax, 1
	pop si
	ret

.KernelFound:
	mov ax, 0
	pop si
	ret

.global BootDiskErrorReadMsg
BootDiskErrorReadMsg:
	mov bx, offset flat:BootErrorMsg
	call print_string

BootKernelNotFound:
	mov bx, offset flat:KernelNotFoundMsg
	call print_string
ErrorBootStrap:
	hlt
	jmp .
NextSectorMsg:
	.asciz "Next sector !\n"

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
.global root_sectors
.global root_start_pos
root_sectors:
	.word 0
root_start_pos:
	.word 0
.global KernelOffsetStartFile
KernelOffsetStartFile:
	.word 0
