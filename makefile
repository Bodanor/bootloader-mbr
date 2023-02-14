I386-AS=i386-elf-as
I386-LD=i386-elf-ld
I386-LDFLAGS=--oformat binary

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

