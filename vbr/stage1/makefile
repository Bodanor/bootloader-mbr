AS_SRC := $(wildcard *.s)
AS_OBJ := $(AS_SRC:.s=.o)

.PHONY: clean

all: $(AS_OBJ)

%.o: %.s
	$(I386-AS) --32 -o $@ $<

clean:
	rm -rf *.o
