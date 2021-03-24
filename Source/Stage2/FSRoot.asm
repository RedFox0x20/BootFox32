[bits 16]
dw 18	; Word Used sectors
dw 2880 ; Word Un-used sectors

db 0xFF, 0xFF, 0b11000000 ; Mark cylinder one as used
times 357 db 0		; Mark the rest of the disk as un-used


times 512 - ($ - $$) db 0	; Fill the rest of the sector with zeroes

; Possible 34 files per directory sector
; Zero based sector readings

times 512 - 2 db 0	; Fill bytes for the FS Root

dw 0 ; Next sector for directory
