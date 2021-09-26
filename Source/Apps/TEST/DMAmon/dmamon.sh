~/RomWBW-dev/Tools/unix/uz80as/uz80as -t z80 dmamon.asm dmamon.bin
#srec_cat dmamon.bin -binary -offset 0x0100 --address-length=2 -o dmamon.hex -Intel
cat dmamon.bin > dmamon.com