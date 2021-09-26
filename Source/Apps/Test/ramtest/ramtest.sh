../../../Tools/unix/uz80as/uz80as -t z80 loader.asm loader.bin
../../../Tools/unix/uz80as/uz80as -t z80 dbgmon.asm dbgmon.bin
cat loader.bin dbgmon.bin > ramtest.com
