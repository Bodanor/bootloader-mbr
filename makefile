I386-AS=as
I386-LD=ld
I386-LDFLAGS=--oformat binary -m elf_i386

SUBDIRS := mbr vbr

BUILD_DIR := build
MAKE_DIR := $(pwd)

MBR_DIR := $(MAKE_DIR)/mbr

export I386-AS I386-LD I386-LDFLAGS BUILD_DIR

all: $(SUBDIRS)

$(SUBDIRS):
	mkdir -p $(BUILD_DIR)
	@$(MAKE) -C $@

.PHONY: all $(SUBDIRS) clean

clean:
	@$(MAKE) -C mbr clean
	@$(MAKE) -C vbr clean
	rm -rf $(BUILD_DIR)/* 

