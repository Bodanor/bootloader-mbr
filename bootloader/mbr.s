	.intel_syntax noprefix
	.code16
	.section .mbr, "ax"

/* This is a macro to place a breakpoint with bochs */
.macro DEBUG
xchg bx, bx
.endm

start:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, ax
	
relocate_mbr: 				# We have to relocate the mbr code to address 0x600
	mov cx, 256
	mov si, 0x7c00
	mov di, 0x0600
	rep movs dword ptr es:[di], dword ptr[si]
	ljmp 0x0000:low_start

low_start:
	sti
	mov byte ptr[bootDrive], dl
	
.CheckPartitionsBootFlag:
	mov ax, 4 						# They are 4 Partition tables in MBR
	mov bx, offset flat:Partition1 	#Load Partition1 offset address

.CheckPartitionsBootFlagLoop:
	cmp byte ptr [bx], 0x80 		# Is it the active partition ?
	je .CheckPartitionsBootFlagFound # Found it !
	add bx, 16 						# Let's try the other one then.. Partitions are 16 bytes large
	dec ax
	jnz .CheckPartitionsBootFlagLoop # Loop again with the next partition in BX

.CheckPartitionsBootFlagError:
	mov bx, offset flat:NoBootablePartitionErrMsg
	call print_string
	jmp CPU_HLT
	
.CheckPartitionsBootFlagFound: 			#We at least found an active partition
	mov word ptr[PartitonOffset], bx
	mov bx, offset flat:BootablePartitionFoundMsg
	call print_string

.LoadVBRPartition: 						# This a test to see if the BIOS supports the Extendended int h13 reads. If not, we can't boot !
	mov ah, 0x41
	mov bx, 0x55AA
	mov dl, byte ptr[bootDrive]
	int 0x13
	
	jc NoExtentions 					# If no Carry flag and BX contains 0xAA55 then int 13h extentions are supported
	cmp  bx, 0xAA55
	jne NoExtentions
	
	/* I decided to push directly a DAP struct into the stack instead of creating one in the MBR
	 * Here, we word on 16 bits code so a single push is 16 bits (OR 2 bytes), if we wanted 32 bits then we have to use the DWORD size.
	 * DAP STRUCT Typical Form :
	 *
	 *	Offset	Size	Description
 	 *	0		1		size of packet (16 bytes)
 	 *	1		1		always 0
 	 *	2		2		number of sectors to transfer (max 127 on some BIOSes)
 	 *	4		4		transfer buffer (16 bit segment:16 bit offset) (see note #1)
 	 *	8		4		lower 32-bits of 48-bit starting LBA
	 *	12		4		upper 16-bits of 48-bit starting LBA
	 *
	*/ 

	push dword ptr 0
	mov bx, word ptr[PartitonOffset]
	add bx, 8
	push dword ptr[bx]
	push 0x0
	push 0x7c00
	push 0x1
	push 0x10
	
	mov ah, 0x42
	mov dl, byte ptr[bootDrive]
	mov si, sp
	int 0x13
	jc .LoadVBRPartitionFailed

.CheckVBRSignature:
	cmp word ptr[0x7dfe], 0xAA55 		# Check if the active partiton is bootable
	jne .VBRSignatureError
.JmpToVBR:
	mov si, word ptr[PartitonOffset] 	# Finally jump to the load VBR and give control
	mov dl, byte ptr[bootDrive]
	jmp 0x7c00 							# We'll never return from this jump !

.VBRSignatureError:
	mov bx, offset flat:VBRSignatureErrorMsg
	call print_string
	jmp CPU_HLT

.LoadVBRPartitionFailed:
	mov bx, offset flat:LoadVBRPartitionFailedMsg
	call print_string
	jmp CPU_HLT

NoExtentions:
	mov bx, offset flat:ExtentionsErrorMsg
	call print_string
	jmp CPU_HLT

CPU_HLT:
	jmp .

PartitonOffset:
	.word 0
bootDrive:
	.byte 0 
NoBootablePartitionErrMsg:
	.asciz "[FATAL] No partition marked as active found !\n"

BootablePartitionFoundMsg:
	.asciz "Partition marked as active found !\n"
ExtentionsErrorMsg:
	.asciz "[FATAL] Reading Extentions are not supported on this CPU!\n"
LoadVBRPartitionFailedMsg:
	.asciz "[FATAL] Could not load VBR partition !\n"
VBRSignatureErrorMsg:
	.asciz "[FATAL] VBR is not bootable !\n"

.section .mbr.tail, "ax"
Partition1:
	.fill 16
Partition2:
	.fill 16
Partition3:
	.fill 16
Partition4:
	.fill 16

.word 0xAA55


