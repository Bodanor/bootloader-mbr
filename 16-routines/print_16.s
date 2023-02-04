	.intel_syntax noprefix
	.code16
	.section .common_rountines, "ax"
	.global print_string
	.global print_char
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
