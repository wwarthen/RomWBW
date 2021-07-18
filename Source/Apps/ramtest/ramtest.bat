tasm -t80 -b loader.asm loader.bin
tasm -t80 -b dbgmon.asm dbgmon.bin
copy /b loader.bin+dbgmon.bin ramtest.com
