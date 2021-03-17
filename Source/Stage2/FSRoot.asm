[bits 16]

db 0xFF, 0xFF, 0x03 ; Mark cylinder one as used
times 357 db 0		; Mark the rest of the disk as un-used

dw 18	; Word Used sectors
dw 2880 ; Word Un-used sectors

times 512 - ($ - $$) db 0	; Fill the rest of the sector with zeroes

; Possible 34 files per directory sector
; Zero based sector readings

; TEST FILE
db 0b00001110
db "KERNEL.BIN"
dw 18
dw 50

times 512 - 15 - 2 db 0	; Fill bytes for the FS Root

dw 0 ; Next sector for directory
