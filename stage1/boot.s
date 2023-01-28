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
	
	mov bx, offset flat:FirstStageMsg
	call print_string
	jmp .	
FirstStageMsg:
	.asciz "First Stage loaded !\n"
bootDrive:
	.byte 0

