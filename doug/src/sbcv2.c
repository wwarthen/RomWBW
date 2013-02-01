/*
 *
 * sbcv2.c
 *
 */

#include "portab.h"
#include "sbcv2.h"

void mpcl_ram(U8 page)
{
	pMPCL_RAM = page;
}

void mpcl_rom(U8 page)
{
	pMPCL_ROM = page;
}

void uart_init(void)
{
        wUART_LCR = UART_DLAB;
        wUART_DIV_HI = 0;
        wUART_DIV_LO = 12;
        wUART_LCR = 0x03;
        wUART_MCR = 0x03;

}

unsigned char uart_get(void)
{
        while(UART_RDA & rUART_LSR) ;
        return rUART_RDR;
}

void uart_put(unsigned char c)
{
        while(UART_TBE & rUART_LSR) ;
        wUART_TDR = c;
}

/*
 *
 * eof - sbcv2.c
 *
 */

