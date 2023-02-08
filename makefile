I386-AS=i386-elf-as
I386-LD=i386-elf-ld
I386-LDFLAGS=--oformat binary

SUBDIRS := mbr stage1

BUILD_DIR := build
MAKE_DIR := $(pwd)

MBR_DIR := $(MAKE_DIR)/mbr

export I386-AS I386-LD I386-LDFLAGS BUILD_DIR

all: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p $(BUILD_DIR)
	@$(MAKE) -C $@

image: $(SUBDIRS)
	dd if=/dev/zero of=$(BUILD_DIR)/hdd.img bs=516096c count=20
	(echo o;echo n; echo p; echo 1; echo; echo; echo t; echo 6; echo a; echo p; echo w) | fdisk -u -C1000 -S63 -H16 $(BUILD_DIR)/hdd.img
	dd if=mbr/mbr of=$(BUILD_DIR)/hdd.img bs=446 count=1 conv=notrunc
	sudo losetup -o 1048576 /dev/loop0 $(BUILD_DIR)/hdd.img
	sudo mkfs.fat -F16 -v /dev/loop0 -h 0x800
	sudo dd if=stage1/vbr-bootloader of=/dev/loop0 bs=1 count=3 conv=notrunc
	sudo dd if=stage1/vbr-bootloader of=/dev/loop0 bs=1 skip=62 seek=62 conv=notrunc
	sudo mount /dev/loop0 /mnt
	sudo touch /mnt/KERNEL.BIN
	sudo touch /mnt/FILE.BIN
	echo "123"  >> /mnt/FILE.BIN
	sudo umount /mnt
	sudo losetup -d /dev/loop0	

.PHONY: all $(SUBDIRS) clean

clean:
	@$(MAKE) -C mbr clean
	@$(MAKE) -C stage1 clean
	rm -rf $(BUILD_DIR)/* 

