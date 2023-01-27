I386-AS=i386-elf-as

I386-LD=i386-elf-ld
I386-LDFLAGS= --oformat binary -Ttext 0x0600 

mbr: mbr.o
	$(I386-LD) $(I386-LDFLAGS) $< -o $@
mbr.o: mbr.s
	$(I386-AS) -o $@ $<
debug: mbr hdd.img
	(echo o;echo n; echo p; echo 1; echo; echo; echo t; echo 0c; echo a; echo p; echo w) | fdisk -u -C1000 -S63 -H16 ./hdd.img
	dd if=./mbr of=./hdd.img bs=446 count=1 conv=notrunc
	sudo losetup -o 1048576 /dev/loop0 ./hdd.img
	sudo mkfs.vfat -F32 /dev/loop0
	sudo losetup -d /dev/loop0

hdd.img:
	dd if=/dev/zero of=./hdd.img bs=516096c count=100

clean:
	rm -rf *.o
	rm -rf mbr

