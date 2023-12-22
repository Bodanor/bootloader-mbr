AS_SRC := $(wildcard *.s)
AS_OBJ := $(AS_SRC:.s=.o)

all: mbr
	make -C ../16-routines


mbr: $(AS_OBJ) ../16-routines/print_16.o
	$(I386-LD) $(I386-LDFLAGS) -T mbr.ld -o $@ $^

.PHONY: all clean

%.o:%.s
	$(I386-AS) --32 -o $@ $<

clean:
	make -C ../16-routines clean
	rm -rf *.o
	rm -rf mbr


