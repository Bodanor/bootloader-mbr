	.intel_syntax noprefix
	.code16
	.section .stage1, "ax"
	.global _start
	.type _start,@function

.macro DEBUG
	xchg bx, bx
.endm

_start:
	jmp _start_16
	nop
	/* Start of the BPB, I'll be using a fake one as when copied to a USB drive, the correct ones will replace the fakes one */
BPB:
	iOEM:          .ascii "NO NAME   "  	# OEM String
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
	DEBUG
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
	

.SetVideoMode:
	mov ah, 0x0
	mov al, 0x3
	int 0x10
	
	mov bx, offset flat:VideoModeMsg
	call print_string
	
	mov bx, offset flat:FirstStageMsg
	call print_string



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
	jne .skip_a20
	
	/* Here we check if we didn't compare with the same value by mere chance. So we actually change the value and cmp again */
	mov byte ptr ds:[di], 0xff
	mov al, byte ptr ds:[di]
	cmp al, byte ptr es:[si]
	
	pop ax
	mov byte ptr ds:[di], al

	jne .skip_a20
	mov bx, 0

.skip_a20:

		ret

/* This is a routine to enable the a20 line if not already enabled ! */

.enableA20Gate:
	

FirstStageMsg:
	.asciz "First Stage loaded !\n"
VideoModeMsg:
	.asciz "Changing Video mode to 80x25 16bit color\n"
A20EnabledMsg:
	.asciz "A20 Gate enabled !\n"
A20DisabledMsg:
	.asciz "A20 Gate disabled, trying to enable it\n"
bootDrive:
	.byte 0

