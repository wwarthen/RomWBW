# System Configuration

## Introduction

An utility applicaton that sets NVR Attributes that affect HBIOS and 
RomWBW Operation. Write to RTC NVRAM to store config is reliant on HBIOS

## Building

TASM (Telemark Assembler) ([Anderson, 1998](##References)).

### RomWBW Version

Is part of the SBCv2 RomWBW distribution. And deployed as a Rom Application
It is included in Rom Bank 1

### CP/M Version

The resulting `sysconfig.com` command file can be run in CP/M.
It is copied in the Binary/Apps folder.

