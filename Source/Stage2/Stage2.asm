; Stage 2 will be loaded into 0x0500
; We are still in real mode
[ORG 0x0500]
[BITS 16]

; For the simplicity of data
jmp Stage2
nop

; DATA

%define FILE_SYSTEM_HEAD_ADDR 0x7C03
%define MEMORY_MAP_LOCATION 0x2900

; String ends in [CR][LF][NULL] otherwise they seem to misbehave
%define STRING_END 0x0D, 0x0A, 0x00
STR_ENTERED_STAGE2: db "BOOT STAGE 2", STRING_END
STR_CREATING_MEMORY_MAP: db "CREATING MEMORY MAP", STRING_END

; CODE
Stage2:

	mov si, STR_ENTERED_STAGE2
	call print_str
	
	call CreateMemoryMap
		
		
STOP:
	cli
	hlt
	jmp STOP


%include "Source/Shared/print_str.asm"

%include "Source/Shared/CreateMemoryMap.asm"
