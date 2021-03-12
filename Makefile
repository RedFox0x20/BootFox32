.PHONY: all run run_tty Floppy 

all: Stage1 Stage2 FSRoot Floppy

Stage1: 
	nasm -fbin ./Source/Stage1/Bootsector.asm -o ./Build/Stage1/Bootsector.bin

Stage2Objects:=Source/Stage2/Stage2.asm \
			   Source/Stage2/FS.asm \
			   Source/Stage2/CreateMemoryMap.asm

Stage2: 
	nasm -fbin ./Source/Stage2/Stage2.asm -o ./Build/Stage2/Stage2.bin

FSRoot:
	nasm -fbin ./Source/Stage2/FSRoot.asm -o ./Build/Stage2/FSRoot.bin

run: Floppy
	[[ pts != /dev/tty1 ]] && qemu-system-i386 -fda ./Floppy.img \
			  || qemu-system-i386 -nographic -fda ./Floppy.img 

run_tty: Floppy
	qemu-system-i386 -nographic -fda ./Floppy.img

Floppy: all 
	dd if=/dev/zero of=./Floppy.img bs=512 count=2880 conv=notrunc
	dd if=./Build/Stage1/Bootsector.bin of=./Floppy.img bs=512 conv=notrunc
	dd if=./Build/Stage2/Stage2.bin of=./Floppy.img bs=512 seek=1 conv=notrunc
	dd if=./Build/Stage2/FSRoot.bin of=./Floppy.img bs=512 seek=16 conv=notrunc

clean:
	rm -rf Build
	rm -f ./Floppy.img
	mkdir Build Build/Stage1 Build/Stage2


