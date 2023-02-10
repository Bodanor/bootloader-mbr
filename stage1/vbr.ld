SECTIONS
{
    .stage1 0x7c00 :
    {
		*(.stage1)
		*(.common_rountines)
		FILL(0x0)
		. = 0x1FE;
		SHORT(0xaa55)
		*(.stage1_nxt)
		. = 0x3FE;
		SHORT(0xaa55)
	}
	.stage2 0x9000 :AT(0x1200)
	{
		*(.stage2)
	}
}

