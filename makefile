include makefile.inc

all : $(DEST_FOLDER)/hdd.img

$(DEST_FOLDER)/hdd.img: $(DEST_FOLDER)/vbr-bootloader $(DEST_FOLDER)/mbr
	mkdir -p $(DEST_FOLDER)
	dd if=/dev/zero of=$(DEST_FOLDER)/hdd.img bs=516096c count=100

$(DEST_FOLDER)/vbr-bootloader:
	make -C bootloader

debug: $(DEST_FOLDER)/hdd.img $(DEST_FOLDER)/vbr-bootloader $(DEST_FOLDER)/mbr
	(echo o;echo n; echo p; echo 1; echo; echo; echo t; echo 0c; echo a; echo p; echo w) | fdisk -u -C1000 -S63 -H16 $(DEST_FOLDER)/hdd.img
	dd if=$(DEST_FOLDER)/mbr of=$(DEST_FOLDER)/hdd.img bs=446 count=1 conv=notrunc
	sudo losetup -o 1048576 /dev/loop0 $(DEST_FOLDER)/hdd.img
	sudo mkfs.vfat -F16 /dev/loop0
	sudo dd if=$(DEST_FOLDER)/vbr-bootloader of=/dev/loop0 bs=1 count=3 conv=notrunc
	sudo dd if=$(DEST_FOLDER)/vbr-bootloader of=/dev/loop0 bs=1 skip=62 seek=62 conv=notrunc
	sudo losetup -d /dev/loop0


$(DEST_FOLDER)/mbr:
	make -C bootloader

clean:
	rm -rf $(DEST_FOLDER)/vbr-bootloader
	rm -rf $(DEST_FOLDER)/mbr
	rm -rf $(DEST_FOLDER)/hdd.img
	make -C bootloader clean
