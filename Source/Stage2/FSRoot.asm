[bits 16]

db 0xFF, 0xFF, 0x03 ; Mark cylinder one as used
times 357 db 0		; Mark the rest of the disk as un-used

dw 18	; Word Used sectors
dw 2880 ; Word Un-used sectors

times 512 - ($ - $$) db 0	; Fill the rest of the sector with zeroes

; TEST FILE
db 0b00001110
db "TEST_FILE"
dw 19
dw 20

times 512 - 15 db 0	; Fill bytes for the FS Root
