AS_SRC := $(wildcard *.s)
AS_OBJ := $(AS_SRC:.s=.o)


all: vbr-bootloader
	make -C ../16-routines
	make -C ../stage2


vbr-bootloader: $(AS_OBJ) ../16-routines/print_16.o ../stage2/stage2.o
	$(I386-LD) $(I386-LDFLAGS) -T ../vbr.ld -o $@ $^

.PHONY: all clean

%.o:%.s
	$(I386-AS) -o $@ $<

clean:
	make -C ../16-routines clean
	make -C ../stage2 clean
	rm -rf *.o
	rm -rf vbr-bootloader


