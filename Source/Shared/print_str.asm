; PRINT_STR - Print a NULL terminated string
; SI = string
print_str:
	mov ah, 0x0E
	xor bx, bx
.Loop:
	mov al, byte [si]
	test al, al
	je .Done
	int 0x10
	inc si
	jmp .Loop
.Done:
	ret

