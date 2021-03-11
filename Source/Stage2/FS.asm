;FS.asm

%define FSH 0x7C03
%define FSH_Magic FSH
%define FSH_BootFlag FSH+2
%define FSH_DriveName FSH+3
%define FSH_DriveNumber FSH+11
%define FSH_NumCylinders FSH+12
%define FSH_NumHeads FSH+13
%define FSH_NumSectorsPerCylinder FSH+14
%define FSH_Reserved FSH+15
%define FSH_RootCylinder FSH+16
%define FSH_RootSector FSH+17
%define FSH_RootHead FSH+18
%define FSH_RootSectorMap FSH+19

STR_ERR_INVALID_BOOT_DISK: db "ERROR: INVALID FILEFOX32 DISK!", STRING_END
STR_ERR_FAILED_TO_LOAD_ROOT: db "ERROR: FAILED TO LOAD ROOT DIRECTORY!", STRING_END
STR_RECOGNISE: db "FILE SYSTEM: RECOGNISE", STRING_END
STR_LOAD_ROOT: db "FILE SYSTEM: LOAD ROOT", STRING_END 

FS_Recognise:
	mov si, STR_RECOGNISE
	call print_str

	pusha
	mov ax, word [FSH_Magic]
	cmp ax, "RF"
	jne .Invalid
	popa
	clc
	ret

	.Invalid:
	mov si, STR_ERR_INVALID_BOOT_DISK
	call print_str
	popa
	jmp STOP

RootLoadAttempts: db 3

FS_LoadFSRoot:
	
	mov si, STR_LOAD_ROOT
	call print_str

	mov ah, 0x02
	mov al, 2 ; Load the sector map and the FS root
	mov bx, ROOT_LOAD_LOCATION
	movzx cx, byte [FSH_RootCylinder]
	shl cx, 5
	add cl, byte [FSH_RootSector]
	mov dh, byte [FSH_RootHead]
	mov dl, byte [FSH_DriveNumber]
	
	clc
	mov si, 0
	int 0x13
	jc .Error
	ret
	.Error:
	mov si, STR_ERR_FAILED_TO_LOAD_ROOT
	call print_str
	jmp STOP
