typedef unsigned short u16;
typedef unsigned char  u8;

volatile u8 *VDP0 = (volatile u16*) /* put addr of VDP's MODE=0 loc here */;
volatile u8 *VDP1 = (volatile u16*) /* put addr of VDP's MODE=1 loc here */;

/* Read the VDP status register */
u8 vdp_read_status(void)
{   
        return *VDP1;
}   

/* Write to a VDP write-only control register */
void vdp_write_register(u8 value, u8 reg)
{   
        *VDP1 = value;                            /* Write value first                          */
        *VDP1 = (reg & 7) | 0x80;          /* Write reg # second, w/ MSB set.  */
}   

/* Read a single byte of VRAM via the VDP */
u8 vdp_read_byte(u16 vdp_addr)
{
        *VDP1 = vdp_addr & 0xFF;                /* Send lower 8 bits of VRAM address */
        *VDP1 = (vdp_addr >> 8 ) & 0x3F; /* Send upper 6 bits of VRAM address */
        return *VDP0;                              /* Read the data byte */
}

/* Read a block of bytes from VRAM via the VDP */
void vdp_read_block(u16 vdp_addr, u8 *dst, int len)
{
        *VDP1 = vdp_addr & 0xFF;                /* Send lower 8 bits of VRAM address */
        *VDP1 = (vdp_addr >> 8 ) & 0x3F; /* Send upper 6 bits of VRAM address */

        while (len-- > 0)
                *dst++ = *VDP0;                  /* Copy out the next data byte.          */
}

/* Write a single byte of VRAM via the VDP */
void vdp_write_byte(u16 vdp_addr, u8 data)
{
        /* Send lower 8 first, followed by upper 6.  Must also force upper 2 */
        /* bits of second write to be "01" to indicate "write".                   */
        *VDP1 = vdp_addr & 0xFF;
        *VDP1 = (vdp_addr >> 8 ) & 0x3F | 0x40;

        *VDP0 = data;                              /* Send the data */
}

/* Read a block of bytes from VRAM via the VDP */
void vdp_write_block(u16 vdp_addr, u8 *src, int len)
{
        /* Send lower 8 first, followed by upper 6.  Must also force upper 2 */
        /* bits of second write to be "01" to indicate "write".                   */
        *VDP1 = vdp_addr & 0xFF;
        *VDP1 = (vdp_addr >> 8 ) & 0x3F | 0x40;

        while (len-- > 0)
                *VDP0 = *src++;                  /* Copy out the next data byte.          */
}
