; Stage 2 will be loaded into 0x0500
[ORG 0x0500]
; We are still in real mode
[BITS 16]

; For the simplicity of data
jmp 0x0000:Stage2
nop

; DATA

%define STAGE2_LOCATION			0x0500	; 18 * 512
%define MEMORY_MAP_LOCATION 	0x2900	; 1  * 512
%define FS_LOAD_LOCATION 		0x3100	; 2  * 512
%define KERNEL_LOAD_LOCATION 	0x3500  ; Safe until 0x0007 FFFF ~499K
%define KERNEL_BASE				0x3500	; 
%define KERNEL_IDENTIFIER 		KERNEL_BASE+5
;******************************************************************************
; Global Descriptor Table (GDT)
;******************************************************************************
; Creates a flat style memory layout
;******************************************************************************
gdt_data: 
dq 0							; null descriptor

; gdt code:						; code descriptor
dw 0xFFFF 						; limit low
dw 0 							; base low
db 0 							; base middle
db 10011010b 					; access
db 11001111b 					; granularity
db 0 							; base high

; gdt data:						; data descriptor
dw 0xFFFF 						; limit low (Same as code)
dw 0 							; base low
db 0 							; base middle
db 10010010b 					; access
db 11001111b 					; granularity
db 0							; base high

end_of_gdt:						; Save the end point
dw end_of_gdt - gdt_data - 1 	; limit (Size of GDT)
dd gdt_data						; base of GDT
;******************************************************************************

; CODE
Stage2:

	mov si, STR_ENTERED_STAGE2
	call print_str
	
	call CreateMemoryMap

	call FS_Recognise
	call FS_LoadFSRoot	
	call FS_LoadKernel

	mov ah, 0x0003
	int 0x10

	mov ax, 0x0100
	mov cx, 0x3F00
	int 0x10

	cli
	lgdt [end_of_gdt]

	mov eax, cr0
	or  eax, 1
	mov cr0, eax

	jmp 0x08:Stage232

STOP:
	sti
	mov si, STR_STOP
	call print_str
	cli
	hlt
	jmp STOP

; Compare si to di on cx letters
strcmp:
	pusha

	.Loop:
	test cx, cx
	jz .Done
	dec cx

	mov al, byte [si]
	mov ah, byte [di]
	inc si
	inc di
	cmp al, ah
	je .Loop
	
	.NoMatch:
	popa
	mov ax, 1
	ret

	.Done:
	popa
	mov ax, 0
	ret


%include "Source/Shared/print_str.asm"

%include "Source/Stage2/CreateMemoryMap.asm"

%include "Source/Stage2/FS.asm"

STR_ENTERED_STAGE2: db "BOOT STAGE 2", STRING_END
STR_CREATING_MEMORY_MAP: db "MEMORY: CREATING MEMORY MAP", STRING_END
STR_STOP: db "STOP", STRING_END

;******************************************************************************
; Stage2 - 32 bit
;******************************************************************************
[BITS 32]

STR_STOP32: db "STOP", STRING_END
STR_KERN_ID: db "RFKN"

Stage232:
	mov ax, 0x10	; Load the value 0x10 into EAX and clear higher bits
	mov ds, ax		; DS = 0x10
	mov es, ax		; ES = 0x10
	mov fs, ax		; FS = 0x10
	mov gs, ax		; GS = 0x10
	mov ss, ax		; SS = 0x10 as per GDT

	; Setup the stack (Ensure that there's no incorrect bits in high)
	; A 20KB stack starting at the first section of free memory, this is an
	; assumed free section
	mov ebp, 0x00105000		; Set the base pointer
	mov esp, 0x00105000		; Set the top of the stack to 

	mov eax, dword [KERNEL_IDENTIFIER]
	mov ebx, dword [STR_KERN_ID]
	cmp eax, ebx
	jne INVALID_KERNEL

	call EnableA20

	push MEMORY_MAP_LOCATION
	call KERNEL_BASE

STOP32:
	cli
	hlt
	jmp STOP32


INVALID_KERNEL_STR: db "KERNEL: INVALID!", STRING_END
INVALID_KERNEL:
	mov esi, INVALID_KERNEL_STR
	mov edi, 0xB8000
	.Loop
	mov al, byte [esi]
	test al, al
	jz .Done
	mov byte [edi], al
	inc esi
	add edi, 2
	jmp .Loop
	.Done:
	jmp STOP32

;******************************************************************************
; Enable A20
;******************************************************************************
EnableA20:
	call    a20wait		; Call to the a20wait function
	mov     al, 0xAD	; Set AL to 0xAD
	out     0x64, al	; Write to port 0x64

	call    a20wait		; Call to the a20wait function
	mov     al,0xD0		; Set AL to 0xD0
	out     0x64,al		; Write to port 0x64

	call    a20wait2	; Call to the a20wait function
	in      al,0x60		; Read port 0x60
	push    eax			; Push eax to the stack

	call    a20wait		; Call the a20wait function
	mov     al,0xD1		; Set AL to 0xD1
	out     0x64,al		; Write to port 0x64

	call    a20wait		; Call the a20wait function
	pop     eax			; Pop the value back off the stack
	or      al,2		; Or AL with 2
	out     0x60,al		; Write the result to port 0x60

	call    a20wait		; Call to the a20wait function
	mov     al,0xAE		; AL = 0xAE 
	out     0x64,al		; Write to port 0x64

	call    a20wait		; Call the a20wait function
	ret					; Return to the init code

	a20wait:
	in      al,0x64		; Read form port 0x64
	test    al,2		; Test the value with bit 2
	jnz     a20wait		; If the value is 2 then jump to a20wait2
	ret					; Else return now

	a20wait2:			;
	in      al,0x64		; Read from port 0x64
	test    al,1		; Compare the value with 1
	jz      a20wait2	; If the value is 0 repeat
	ret					; Else we're returning to the caller

