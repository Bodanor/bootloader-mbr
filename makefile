I386-AS=i386-elf-as
I386-LD=i386-elf-ld
i386-LDFLAGS=--oformat binary

BUILD_DIR := build
MAKE_DIR := $(pwd)

MBR_DIR := $(MAKE_DIR)/mbr

export I386-AS I386-LD I386-LDFLAGS BUILD_DIR

all:
	mkdir -p $(BUILD_DIR)
	@$(MAKE) -C mbr
	@$(MAKE) -C stage1

.PHONY: clean

clean:
	@$(MAKE) -C mbr clean
	@$(MAKE) -C stage1 clean

