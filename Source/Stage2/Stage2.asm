; Stage 2 will be loaded into 0x0500
[ORG 0x500]
; We are still in real mode
[BITS 16]

; For the simplicity of data
jmp Stage2
nop

; DATA

%define STAGE2_LOCATION			0x0500	; 18 * 512
%define MEMORY_MAP_LOCATION 	0x2900	; 1  * 512
%define FS_LOAD_LOCATION 		0x3100	; 2  * 512
%define KERNEL_LOAD_LOCATION 	0x3500  ; Safe until 0x0007 FFFF ~499K

; String ends in [CR][LF][NULL] otherwise they seem to misbehave
%define STRING_END 0x0D, 0x0A, 0x00
STR_ENTERED_STAGE2: db "BOOT STAGE 2", STRING_END
STR_CREATING_MEMORY_MAP: db "CREATING MEMORY MAP", STRING_END
STR_FS_INIT: db "LOADING FILE SYSTEM", STRING_END
STR_STOP: db "STOP ", STRING_END

; CODE
Stage2:

	mov si, STR_ENTERED_STAGE2
	call print_str
	
	call CreateMemoryMap

	mov si, STR_FS_INIT
	call print_str

	call FS_Recognise
	call FS_LoadFSRoot	
	call FS_LoadKernel

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

