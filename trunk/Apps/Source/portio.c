/* portio.c 8/30/2012 dwg - skeleton for inb and outb routines */

int inb(address)
	unsigned int address;
{

	return address;
}

int outb(address,data)
	unsigned int address;
	int data;
{
	return address+data;
}

