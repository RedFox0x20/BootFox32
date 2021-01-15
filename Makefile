.PHONY: all run Floppy

OBJECTS:=Stage1/Bootsector.o Stage2

all: $(OBJECTS) Floppy

clean:
	rm -rf Build
	rm -f ./Floppy.img
	mkdir Build Build/Stage1 Build/Stage2

Floppy: $(OBJECTS)
	dd if=/dev/zero of=./Floppy.img bs=512 count=2880 conv=notrunc
	dd if=./Build/Stage1/Bootsector.o of=./Floppy.img bs=512 conv=notrunc
	dd if=./Build/Stage2/Bootloader.o of=./Floppy.img bs=512 seek=1 conv=notrunc

run: Floppy
	qemu-system-i386 -fda ./Floppy.img

Stage1/%.o: Source/Stage1/%.asm
	nasm -fbin ./$< -o ./Build/$@

Stage2: Source/Stage2/Stage2.asm
	nasm -fbin ./$< -o ./Build/Stage2/Bootloader.o
