; Bootloaders start at 0x7C00 and are in Real Mode (except for the rare weird
; BIOS which may put you into Protected Mode because why not!?
[ORG 0x7C00]
[BITS 16]

; A standard dsign to just jump over some disk information
; This is a part of the FAT standard but I will borrow it for easy of the
; following structure
; [JUMP with some good measure NOP padding]
; [DATA]
; [CODE]
jmp Boot
nop

; FILE SYSTEM AND DRIVE DATA

FILE_SYSTEM_HEADER:
; FS identification
FSH_Magic:					db "RF"
FSH_BootFlag:				db 1
; Drive data
FSH_DriveName:				db "RedFox32"
FSH_DriveNumber: 			db 0
FSH_NumCylinders:			db 160 
FSH_NumHeads:				db 2
FSH_NumSectorsPerCylinder:	db 18
; FS Parameters
FSH_ReservedCylinders:		db 1
FSH_RootCylinder:			db 0
FSH_RootSector:				db 17
FSH_RootHead:				db 0
FSH_RootSectorMapLength:	db 1


; CODE
Boot:
	; A standard feature is that the BIOS will leave the boot drive number
	; in bl, this is useful for int 0x13 functions.
	mov byte [FSH_DriveNumber], bl

	; Enter a known video state
	; 80x25 column
VideoSetup:
	mov ax, 0x0003
	int 0x10

	; Show the user something
	mov si, STR_STAGE1
	call print_str

BootCheck:
	movzx ax, byte [FSH_BootFlag]
	test ax, ax
	jz NotABootableDrive 
	

	; Initialise some of the registers
RegisterInit:
	cli

	; Clear registers, 32 bit
	xor eax, eax
	mov ebx, eax
	mov ecx, eax
	mov edx, eax
	mov esi, eax
	mov edi, eax
	
	; Ensure segment registers other than CS and SS are cleared
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	
	; Setup the stack
	mov ax, 0x9000
	mov ss, ax
	mov sp, 0xFFFF 

	sti

	mov si, STR_STAGE2
	call print_str

Load:
	; Test to see if we should attempt to load or bail out
	;mov ax, word [LoadAttemptsCounter]
	;test ax, ax
	;jz LoadError 

	; Decrement the counter
	dec al
	mov byte [LoadAttemptsCounter], al
DiskSetup:
	mov ax, 0x0000
	mov dl, byte [FSH_DriveNumber] 
	int 0x13
	jc DiskSetup

	; Load the remaining bootloader sectors
	mov ah, 0x02
	mov al, 17
	mov bx, 0x0500
	mov ch, 0
	mov cl, 2
	mov dh, 0
	mov dl, byte [FSH_DriveNumber]
	int 0x13

	; Test that the load worked correctly else try again
	jc Load
	cmp al, 17
	jne Load

	; We are done here
	mov dl, byte [FSH_DriveNumber]
	jmp 0x0000:0x0500 

	; In the event of a load error we jump here
LoadError:
	mov si, STR_DISK_ERROR
	call print_str
	; Continue into the STOP code

	; Stop the system, disable interrupts and halt, in the event we somehow
	; continue then we just loop back.
STOP:
	sti
	mov si, STR_STOP
	call print_str
	cli
	hlt
	jmp STOP

NotABootableDrive:
	mov si, STR_NOT_BOOTABLE
	call print_str
	jmp STOP

%include "Source/Shared/print_str.asm"

; DATA
LoadAttemptsCounter:		dw 3

; String ends in [CR][LF][NULL] otherwise they seem to misbehave
STR_STAGE1: db "BOOT STAGE 1", STRING_END
STR_STAGE2: db "LOADING STAGE 2...", STRING_END
STR_DISK_ERROR: db "DISK ERROR LOADING...", STRING_END
STR_NOT_BOOTABLE: db "THIS IS NOT A BOOTABLE DRIVE!", STRING_END
STR_STOP: db "STOP", STRING_END
; Move to the end of the sector and write the magic boot signature bytes
times 510 - ($ - $$) db 0
BootSignature: dw 0xAA55
