;FS.asm
[BITS 16]

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
STR_ERR_FAILED_TO_LOAD_KERNEL: db "ERROR: FAILED TO LOAD KERNEL!", STRING_END
STR_ERR_NO_KERNEL: db "ERROR: NO KERNEL FOUND!", STRING_END
STR_RECOGNISE: db "FILE SYSTEM: RECOGNISE", STRING_END
STR_LOAD_ROOT: db "FILE SYSTEM: LOAD ROOT", STRING_END 

FS_Recognise:
	mov si, STR_RECOGNISE
	call print_str

	mov ax, word [FSH_Magic]
	cmp ax, "RF"
	jne .Invalid
	ret

	.Invalid:
	mov si, STR_ERR_INVALID_BOOT_DISK
	call print_str
	jmp STOP

; Temporarily ignoring retries.
RootLoadAttempts: db 3

FS_LoadFSRoot:
	mov si, STR_LOAD_ROOT
	call print_str

	mov ah, 0x02
	mov al, 2 ; Load the sector map and the FS root
	mov bx, FS_LOAD_LOCATION 
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

%define FS_ROOT_LOCATION FS_LOAD_LOCATION + 512
%define FILE_ENTRY_SIZE 15
STR_KERNEL_FILE_NAME: db "KERNEL.BIN"

KernelCylinder: dw 0
KernelSector: dw 0
KernelHead: dw 0
FS_LoadKernel:
	mov si, FS_ROOT_LOCATION
	mov di, STR_KERNEL_FILE_NAME
	
	.CheckEntry:
	test si, si
	jz .NoKernel
	inc si

	mov cx, 10
	call strcmp
	cmp ax, 1
	jne .Found

	add si, FILE_ENTRY_SIZE-1
	jmp .CheckEntry

	.Found:
	clc

	add si, 10
	mov bx, word [si] 	; Get start sector
	add si, 2
	mov cx, word [si] 	; Get end sector
	sub cx, bx			; Number of sectors to load
	movzx ax, cl		; This method should be temporary in order to allow
						; larger kernel loading in the future
	mov ah, 0x02 ;Set the read command

	push ax

	sub si, 2
	mov ax, [si] 	; Get start sector
	mov bx, 18	 	; Divide by the number of sectors
	div bx			
	inc dx			; Add 1 to the sector number for int 13
	mov word [KernelSector], dx
	dec ax			; Decrement the cylinder for int 13 
	mov word [KernelCylinder], ax
	inc ax			; Increment the cylinder for correct head calculation
	mov bx, 2		; Divide by the number of heads
	div bx
	mov word [KernelHead], dx

	mov bx, KERNEL_LOAD_LOCATION	; Set load location 

	mov cx, word [KernelCylinder]	; Set cylinder (Floppy only)
	shl cx, 8
	add cx, word [KernelSector]		; Set sector

	mov dx, word [KernelHead]		; Set head
	shl dx, 8
	mov dl, byte [FSH_DriveNumber]	; Set drive number

	pop ax	; Restore the command and number of sectors to load
	
	int 0x13	; Load
	jc .Error 

	ret

	.NoKernel:
	mov si, STR_ERR_NO_KERNEL
	call print_str
	jmp STOP

	.Error:
	mov si, STR_ERR_FAILED_TO_LOAD_KERNEL
	call print_str
	jmp STOP

