	.intel_syntax noprefix
	.code16

/* This is a macro to place a breakpoint with bochs */
.macro DEBUG
xchg bx, bx
.endm

start:
	DEBUG
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
	DEBUG
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
	
.CheckPartitionsBootFlagFound:
	mov word ptr[PartitonOffset], bx
	mov bx, offset flat:BootablePartitionFoundMsg
	call print_string

.LoadVBRPartition:
	mov ah, 0x41
	mov bx, 0x55AA
	mov dl, byte ptr[bootDrive]
	int 0x13
	
	jc NoExtentions
	cmp  bx, 0xAA55
	jne NoExtentions
	mov bx, word ptr[PartitonOffset]
	
	add bx, 8
	mov ebx, dword ptr[bx]
	mov dword ptr[DAP + 8], ebx

	mov ah, 0x42
	mov dl, byte ptr[bootDrive]
	mov si, offset flat:DAP
	int 0x13
	jc .LoadVBRPartitionFailed

.CheckVBRSignature:
	cmp word ptr[0x7dfe], 0xAA55
	jne .VBRSignatureError
.JmpToVBR:
	mov si, word ptr[PartitonOffset]
	mov dl, byte ptr[bootDrive]
	jmp 0x7c00
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

print_string:
    pusha       # store all register onto the stack

print_loop:
    mov al, byte ptr[bx]        # mov char value at address BX into al
    mov ah, 0x0E                # 0X0E to write text in teletype mode with int 0x10
    cmp al, 0
    je print_end                # If equal to 0 (null terminator), whe jump to the end
    cmp al, 10
    je print_newline
    int 0x10                    # interrupt with ah=0x0E --> Teletype mode

print_increment:
    add bx, 1                   # move pointer from the address in BX
    jmp print_loop              # We loop until al = 0 (null terminator)

print_newline:
    
    mov al, 0xa # newline
    mov ah, 0x0e
    int 0x10

    mov al, 0xd # Carriage return
    mov ah, 0x0e
    int 0x10
    
    jmp print_increment
print_end:
    popa                        # restore registers from the stack before returning
    ret


print_char:
    pusha

    mov al, bl
    mov ah, 0x0E
    int 0x10
    popa
    ret

CPU_HLT:
	jmp .

DAP:
	.byte 0x10
	.byte 0
	.word 1
	.word 0x7c00
	.long 0
	.long 0

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

. = 0x1BE + start /* Padding for till the first mbr entry */


Partition1:
	.fill 16
Partition2:
	.fill 16
Partition3:
	.fill 16
Partition4:
	.fill 16

.word 0xAA55


