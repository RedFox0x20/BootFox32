.PHONY: all run Floppy

OBJECTS:=Stage1/Bootsector.o 

all: $(OBJECTS) Stage2Bootloader Floppy

clean:
	rm -rf Build
	rm -f ./Floppy.img
	mkdir Build Build/Stage1 Build/Stage2

Floppy: $(OBJECTS) Stage2Bootloader
	dd if=/dev/zero of=./Floppy.img bs=512 count=2880 conv=notrunc
	dd if=./Build/Stage1/Bootsector.o of=./Floppy.img bs=512 conv=notrunc
	dd if=./Build/Stage2/Stage2.o of=./Floppy.img bs=512 seek=1 conv=notrunc

run: Floppy
	[[ pts != /dev/tty1 ]] && qemu-system-i386 -fda ./Floppy.img \
			  || qemu-system-i386 -nographic -fda ./Floppy.img 

run_tty: Floppy
	qemu-system-i386 -nographic -fda ./Floppy.img

Stage1/%.o: Source/Stage1/%.asm
	nasm -fbin ./$< -o ./Build/$@

Stage2Bootloader: Source/Stage2/Stage2.asm
	nasm -fbin ./$< -o ./Build/Stage2/Stage2.o

