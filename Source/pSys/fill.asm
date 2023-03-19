#include "psys.inc"

	.fill	(8 * 1024) - loader_size - bios_size - boot_size - (512 * 3)
	.end
