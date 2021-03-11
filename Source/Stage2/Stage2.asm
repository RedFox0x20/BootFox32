; Stage 2 will be loaded into 0x0500
[ORG 0x500]
; We are still in real mode
[BITS 16]

; For the simplicity of data
jmp Stage2
nop

; DATA

%define FILE_SYSTEM_HEAD_ADDR 0x7C03
%define MEMORY_MAP_LOCATION 0x2900
%define ROOT_LOAD_LOCATION 0x3300
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
		
STOP:
	sti
	mov si, STR_STOP
	call print_str
	cli
	hlt
	jmp STOP



%include "Source/Shared/print_str.asm"

%include "Source/Shared/CreateMemoryMap.asm"

%include "Source/Stage2/FS.asm"
