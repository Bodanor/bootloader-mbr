SECTIONS
{
    .stage1 0x7c00 : AT(0) 
    {
		*(.stage1)
		*(.common_rountines)
		FILL(0x0)
		. = 0x1FE;
		SHORT(0xaa55)
	}
}
