SUBDIRS := ../16-routines stage1 stage2

.PHONY: all $(SUBDIRS) clean

all: $(SUBDIRS) vbr-bootloader

$(SUBDIRS):
	@$(MAKE) -C $@

vbr-bootloader: ../16-routines/print_16.o stage1/stage1.o stage2/stage2.o stage2/gdt.o
	$(I386-LD) $(I386-LDFLAGS) -T vbr.ld -o $@ $^


clean:
	make -C ../16-routines clean
	make -C stage1 clean
	make -C stage2 clean
	rm -rf *.o
	rm -rf vbr-bootloader


