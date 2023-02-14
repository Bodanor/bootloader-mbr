SECTIONS
{
    .stage1 0x7c00 : AT(0x0)
    {
		*(.stage1)
		*(.common_rountines)
		FILL(0x0)
		. = 0x1FE;
		SHORT(0xaa55)
		*(.stage2)
		. = 0x3FE;
		SHORT(0xaa55)
	}
	.stage2_next 0x9000 : AT(0x400)
	{
		*(.stage2_next)
		*(.gdt)
	}
}

