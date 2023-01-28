SECTIONS
{
    .mbr 0x0600 : 
    {
		*(.mbr)
		*(.common_rountines)
		. = 0x1BE;
		*(.mbr.tail)

	}
}
