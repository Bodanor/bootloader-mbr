I386-AS=i386-elf-as

I386-LD=i386-elf-ld
I386-LDFLAGS= --oformat binary -Ttext 0x0600 

mbr: mbr.o
	$(I386-LD) $(I386-LDFLAGS) $< -o $@
mbr.o: mbr.s
	$(I386-AS) -o $@ $<

clean:
	rm -rf *.o
	rm -rf mbr

