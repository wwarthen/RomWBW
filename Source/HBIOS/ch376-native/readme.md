# Native CH376 Driver

The native CH376 HBIOS driver is written in c, using z88dk's zcc compiler.

The build process, is a 3 stage process.

1. Compile all the C code to assembly files (.asm)
2. Translate the produced .asm files syntax to compile with the RomWBW assembler (.s)
3. Assemble the driver .s files as per the standard HBIOS build process

The original C code and produced/translated .s files are all committed units in the repo. But it is
expected, that only the c files are to be modified/updated.  

The .s files are checked in, so builders do not require the C compiler tool chain (z88dk) to be installed.

The c compiling/translating process is only supported on linux, as the script to translate the .asm files
to .s files is a linux bash script.  (Although the script can be easily run within Windows's Sub-system for linux)

## Compiling the C code

> Requires linux with docker installed.

> The C code only needs to be recompiled if and when you change any of the `.c` source files.

To compile the `.c` code to generate updated `.s` files:

Within the `Source/HBIOS/ch376-native` directory:

```
make
```

The make script will search for z88dk's `zcc` compiler, if not found, will attempt to use a docker wrapper.
It will not work if z88dk or docker is not installed.

## USB Native Driver systems

The default builds of RomWBW do not enable the CH376 native usb drivers.  These drivers take a reasonable chunk of ROM space.  As such you
will need to build a new HBIOS image customised for your platform.  Please familiarise yourself with the HBIOS/RomWBW build and configuration process.

The usb driver is divided into a few sub-system, which can be individually enabled within the standard HBIOS config files.

For activating the full native USB support, the non native CH365 drivers need to be disabled and the relevant `CHNATIVE` drivers enabled

Example:

```
CHENABLE       .SET    FALSE    ; CH: ENABLE CH375/376 USB SUPPORT
CH0USBENABLE   .SET    FALSE    ; CH375: ENABLE CH375 USB DRIVER
CH1USBENABLE   .SET    FALSE    ; CH376: ENABLE CH376 USB DRIVER
CHNATIVEENABLE .SET    TRUE     ; CH376: ENABLE CH376 NATIVE USB DRIVER
CHSCSIENABLE   .SET    TRUE     ; CH376: ENABLE CH376 NATIVE MASS STORAGE DEVICES (REQUIRES CHNATIVEENABLE)
CHUFIENABLE    .SET    TRUE     ; CH376: ENABLE CH376 NATIVE UFI FLOPPY DISK DEVICES (REQUIRES CHNATIVEENABLE)
CHNATIVEEZ80   .SET    FALSE    ; CH376: DELEGATE USB DRIVERS TO EZ80'S FIRMWARE
CHNATIVEFORCE  .SET    TRUE     ; CH376: DISABLE AUTO-DETECTION OF MODULE - ASSUME ITS INSTALLED
```

As the USB driver is a fairly large, you may need to disable other HBIOS drivers in your configuration.  As such, it is
recommend to only enable drivers for your platform's hardware configuration - for example, enable only the serial driver
required for your system.

```
DUARTENABLE   .SET    FALSE     ; DUART: ENABLE 2681/2692 SERIAL DRIVER (DUART.ASM)
UARTENABLE    .SET    FALSE     ; UART: ENABLE 8250/16550-LIKE SERIAL DRIVER (UART.ASM)
ACIAENABLE    .SET    FALSE     ; ACIA: ENABLE MOTOROLA 6850 ACIA DRIVER (ACIA.ASM)
SIOENABLE     .SET    TRUE      ; SIO: ENABLE ZILOG SIO SERIAL DRIVER (SIO.ASM)
```

You may also need to disable other storage drivers:

```
FDENABLE      .SET    FALSE     ; FD: ENABLE FLOPPY DISK DRIVER (FD.ASM)
IDEENABLE     .SET    FALSE     ; IDE: ENABLE IDE DISK DRIVER (IDE.ASM)
PPIDEENABLE   .SET    FALSE     ; PPIDE: ENABLE PARALLEL PORT IDE DISK DRIVER (PPIDE.ASM)
```

### base-drv `CHNATIVEENABLE`

The `base-drv` system contains the core code to discover, enumerate, and communicate with USB devices.

It also includes the driver code to enumerate and operating USB devices through a USB hub.

### scsi-drv `CHSCSIENABLE`

The `scsi-drv` system can be enabled with the HBIOS config `CHSCSIENABLE`

When activated, access to most USB mass storage devices (thumb drives, magnetic usb drives) is enabled.

### ufi-drv `CHUFIENABLE`

The `ufi-drv` system can be enabled with the HBIOS config `CHUFIENABLE`

When activated, access to 3.5" Floppy USB devices will be enabled.

### keyboard `TMSMODE_MSXUKY`

The `keyboard` system can be enabled with the inferred config entry `USBKYBENABLE`

This config item is not to be directly set, but is activated via the TMS keyboard driver

Example configuration, combined with the TMS VDP module driver.

```
TMSENABLE    .SET   TRUE              ; TMS: ENABLE TMS9918 VIDEO/KBD DRIVER (TMS.ASM)
TMSMODE      .SET   TMSMODE_MSXUKY    ; TMS: DRIVER MODE: TMSMODE_[SCG|N8|MSX|MSXKBD|MSXMKY|MBC|COLECO|DUO|NABU|MSXUKY]
TMS80COLS    .SET   FALSE             ; TMS: ENABLE 80 COLUMN SCREEN, REQUIRES V9958
TMSTIMENABLE .SET   TRUE              ; TMS: ENABLE TIMER INTERRUPTS (REQUIRES IM1)
```

When activated, usb keyboards can be used as input devices.

### Force activation `CHNATIVEFORCE`

The CH376 module, during a cold power on boot, can take many seconds before it will
respond to the CPU.  As such, the CPU may fail to detect the presence of the module.

A manual reset (without power cycling) generally enables detection.  The config entry
`CHNATIVEFORCE` can be enabled to force the CPU to always wait for the module to come online.


### eZ80 support `CHNATIVEEZ80`

If you have the eZ80 CPU installed with onboard USB firmware support, you 
can gain performance by delegating HBIOS to the firmware implementation.  To enable
delegation, enable the config entry `CHNATIVEEZ80`
