AS_SRC := $(wildcard *.s)
AS_OBJ := $(AS_SRC:.s=.o)

.PHONY: clean

all: $(AS_OBJ)

%.o:%.s
	$(I386-AS) -o $@ $<

clean:
	rm -rf *.o
