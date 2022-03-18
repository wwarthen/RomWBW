PIOMON is a program to verify operation of the Z80 MBC DUALPIO board

Most testing requires the use of loopback hardware constructed as:

Channel A   RDY STB  D0  D1  D2  D3  D4  D5  D6  D7
             \   /   |   |   |   |   |   |   |   |
              \ /    |   |   |   |   |   |   |   |
               X     |   |   |   |   |   |   |   |
              / \    |   |   |   |   |   |   |   |
             /   \   |   |   |   |   |   |   |   |
Channel B   RDY STB  D0  D1  D2  D3  D4  D5  D6  D7

The DUALPIO has, well, 2 PIO chips.  Only one chip
is tested at a time.  At startup, PIOMON will ask
you for the port of the chip to test.  It defaults
to the standard port number for the primary PIO chip
on an MBC DUALPIO board.

The port number specified is the base I/O port.  Each
chip has two channels which are addressed in the
menu by specifying A or B.

MBC DUALPIO Primary PIO = 0xB8
MBC DUALPIO Secondary PIO = 0xBC

If you try to use PIOMON without the RDY and STB
cross connected, you may have interrupt issues
because STB will be floating.

N.B., V1 and V2 of the DUALPIO lack a hardware reset.  The
PIO chips will reset at power-on, but they do not reset
when the reset button is pushed.

Happy St. Patrick's Day!!!

--WBW 7:42 PM 3/17/2022