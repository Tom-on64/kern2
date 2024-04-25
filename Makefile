# Variables
CC = i386-elf-gcc
LD = i386-elf-ld
AS = nasm

CFLAGS = -ffreestanding -m32 -Iinclude -Wall -Wextra

SRC = ./src
BUILD = ./build
C_FILES = calc
# C_FILES = $(shell find $(SRC) -name "*.c" -exec basename -s ".c" {} \;)

.PHONY: os clean run

# Main compilation target
os: $(BUILD) bootloader kernel $(C_FILES)
	@echo "Assembling $(SRC)/testfont.asm..."
	@$(AS) -fbin -o $(BUILD)/testfont.bin $(SRC)/testfont.asm
	@echo "Building filesystem..."
	@$(AS) -fbin -o $(BUILD)/filetable.bin $(SRC)/filetable.asm
	@cat $(BUILD)/boot.bin $(BUILD)/filetable.bin $(BUILD)/kernel.bin > $(BUILD)/os.bin
	@echo "Building kern.iso..."
	@dd if=/dev/zero of=kern.iso bs=512 count=2880 status=none
	@dd if=$(BUILD)/os.bin of=kern.iso conv=notrunc status=none
	@dd if=$(BUILD)/testfont.bin of=kern.iso bs=512 seek=36 conv=notrunc status=none
	@dd if=$(SRC)/fs/test.txt of=kern.iso bs=512 seek=40 conv=notrunc status=none
	@dd if=$(BUILD)/calc.bin of=kern.iso bs=512 seek=41 conv=notrunc status=none
	@echo "\nDone!\n"

$(BUILD):
	@[ -d $(BUILD) ] || mkdir $(BUILD)
	@rm -rf $(BUILD)/*

# Bootloader: This target is responsible for creating boot.bin
bootloader:
	@echo "Assembling $(SRC)/stage1.asm..."
	@$(AS) -fbin -o $(BUILD)/stage1.bin $(SRC)/stage1.asm
	@echo "Assembling $(SRC)/stage2.asm..."
	@$(AS) -fbin -o $(BUILD)/stage2.bin $(SRC)/stage2.asm
	@cat $(BUILD)/stage1.bin $(BUILD)/stage2.bin > $(BUILD)/boot.bin

# Kernel: This target is responsible for creating kernel.bin
kernel: $(SRC)/kernel.c $(SRC)/entry.asm
	@echo "Assembling $(SRC)/entry.asm..."
	@$(AS) -felf32 -o $(BUILD)/entry.o $(SRC)/entry.asm
	@echo "Compiling $(SRC)/kernel.c..."
	@$(CC) $(CFLAGS) -o $(BUILD)/kernel.o -c $(SRC)/kernel.c
	@$(LD) -T $(SRC)/kernel.ld --oformat binary -o $(BUILD)/kernel.bin $(BUILD)/*.o
	@rm $(BUILD)/*.o

$(C_FILES):
	@echo "Compiling $(SRC)/$@.c..."
	@$(CC) $(CFLAGS) -o $(BUILD)/$@.o -c $(SRC)/$@.c
	@$(LD) -T $(SRC)/$@.ld --oformat binary -o $(BUILD)/$@.bin $(BUILD)/$@.o
	@rm $(BUILD)/$@.o

# Run QEMU
run:
	qemu-system-x86_64 -drive format=raw,file="./kern.iso",index=0,media=disk -m 256M -accel tcg

# Clean all build files
clean:
	@rm -rf $(BUILD)
	@rm -f kern.iso
