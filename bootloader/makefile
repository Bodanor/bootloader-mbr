include ../makefile.inc

AS_SOURCES := $(wildcard *.s)
AS_OBJECTS := $(AS_SOURCES:.s=.o)

DEST_FOLDER = ../build
all: $(DEST_FOLDER)/mbr $(DEST_FOLDER)/vbr-bootloader

$(DEST_FOLDER)/mbr: mbr.o print_16.o
	$(I386-LD) $(I386-LDFLAGS) -T linker.ld -o $@ $^

$(DEST_FOLDER)/vbr-bootloader: boot.o print_16.o
	$(I386-LD) $(I386-LDFLAGS) -T linker.ld -o $@ $^

%.o:%.s
	$(I386-AS) $< -o $@

clean:
	rm -rf *.o

