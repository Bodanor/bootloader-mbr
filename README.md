# bootloader-mbr
This is a simple bootloader used for a future kernel for my personal usage.

It concists of an mbr boot manager which sole purpose is rellocate itself, find the active partition, load it at address 0x7C00 and jump to it
