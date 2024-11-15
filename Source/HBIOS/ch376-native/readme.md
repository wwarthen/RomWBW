# Native CH376 Driver

The native CH376 HBIOS driver is written in c, using z88dk's zcc compiler.

The build process, is a 3 stage process.

1. Compile all the C code to assembly files (.asm)
2. Translate the produced .asm files syntax to compile with the RomWBW assembler (.s)
3. Assemble the driver .s files as per the standard HBIOS build process

The original C code and produced/translated .s files are all committed units in the repo. But it is
expected, that only the c files are to be modified/updated.  

The .s files are checked in, to builders to not require the C compiler tool chain (z88dk) to be installed.

The c compiling/translating process is also only support on linux, as the script to translate the .asm files
to .s files is a linux bash script.  (Although the script can be easily run within Windows's Sub-system for linux)

## Compiling the C code

To compile the c code, to update the .s files:

Within the `Source/HBIOS/ch376-native` directly:

```
make
```

The make script will search for z88dk's `zcc` compiler, if not found, will attempt to use a docker wrapper.  
It will not work if z88dk or docker is not installed.

## USB Native Driver systems

The usb driver is divided into a few sub-system, which can be individually enabled within the standard HBIOS config files.

### base-drv

The `base-drv` system contains the core code to discover, enumerate, and communicate to USB devices.

It also includes the driver code for enumerate and operating USB devices on USB hubs.

### scsi-drv

The `scsi-drv` system can be enabled with the HBIOS config `CHSCSIENABLE`

When activated, access to most USB mass storage devices (thumb drives, magnetic usb drives) is enabled.

### ufi-drv

The `ufi-drv` system can be enabled with the HBIOS config `CHUFIENABLE`

When activated, access to 3.5" Floppy USB devices will be enabled.

### keyboard

The `keyboard` system can be enabled with the HBIOS config `USBKYBENABLE`

When activated, usb keyboards can be used as input devices.


