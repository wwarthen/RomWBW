# mak/makebody.mfi 8/8/2011 dwg - 

# Misc other macros

BIN      = bin$(DELIM)
COM      = com$(DELIM)
INC      = inc$(DELIM)
LIB      = lib$(DELIM)
LST      = lst$(DELIM)
MAP      = map$(DELIM)
OBJ      = obj$(DELIM)
REF      = ref$(DELIM)
ROM      = rom$(DELIM)
SRC      = src$(DELIM)
TMP      = tmp$(DELIM)

# CP/M-80 v2.2 Command files written in SDCC
COMFILES = $(COM)copyfile.com $(COM)fdisk.com

# Components used by CP/M-80 v2.2 Command files
COMRELS  = $(OBJ)cpm0.rel $(OBJ)cpmbdos.rel $(OBJ)cprintf.rel

# Components of ROM image containing CP/M for SBC V2
CPMRELS  = $(OBJ)crt0.rel $(OBJ)dbgmon.rel  $(OBJ)bdosb01.rel \
		$(OBJ)ccpb03.rel $(OBJ)cbios.rel

# Components of ROM image used  in test protocols
ROMRELS  = $(OBJ)crt0jplp.rel $(OBJ)crt0scrm.rel

# Components that control hardware in SBC V2
SBCV2HW  = 

# Components that control hardware in the SCSI2IDE
SCSI2IDEHW = $(OBJ)z53c80.rel 

FDISK    = $(BIN)fdisk$(EXE)
DWGH2B   = $(BIN)dwgh2b$(EXE)
INCFILES = $(INC)cpmbdos.h $(INC)cprintf.h $(INC)portab.h
JRCH2B   = $(BIN)jrch2b$(EXE)
LOAD     = $(BIN)load$(EXE)
MK       = Makefile
#QUIET    = @

# ROM images for SBC V2 and N8
ROMFILES = $(ROM)scsiscrm.rom $(ROM)scsijplp.rom $(ROM)scsi2ide.rom $(ROM)baseline.rom $(ROM)n8.rom
SCSI2IDE = $(ROM)scsi2ide.rom

SYSGEN   = $(BIN)sysgen$(EXE)
VERIFY   = $(BIN)verify$(EXE)

# C programs compiled on host system used in build
TOOLS    = $(FDISK) $(DWGH2B) $(LOAD) $(JRCH2B) $(SYSGEN)

# Versions of 'echo' compiled on host system
ETOOLS   = $(BIN)lechocr $(BIN)lecholf $(BIN)lechocrlf $(BIN)lecholfcr

# dribdos.rel is not part of the production set yet
##TEST	 = dribdos.rel

############################################################

#all:    $(ETOOLS) $(TOOLS) $(BINFILES) $(COMFILES) $(CPMFILES) $(ROMFILES)

#all:	$(TEST) $(ROMFILES) $(COMFILES)

roms:	$(ROMFILES)
scsi2ide:	$(SCSI2IDE)

############################################################

# A test assembly of DRI source code for BDOS (from SIMH) 
dribdos.rel:	$(SRC)dribdos.s
	$(QUIET)$(SDAS) $(SDASFLG) dribdos.s
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)dribdos.lst $(LST)

############################################################
############################################################

# Build SCSIJPLP ROM image

$(ROM)scsijplp.rom:     $(OBJ)scsijplp.bin $(MK)
	$(QUIET)$(COPY) $(OBJ)scsijplp.bin $(ROM)scsijplp.rom
	$(QUIET)$(DEL)  $(DELFLG)  scsijplp.*

$(OBJ)scsijplp.bin:   $(OBJ)scsijplp.hex $(DWGH2B) $(MK)
	$(QUIET)$(DWGH2B) $(OBJ)scsijplp

$(OBJ)scsijplp.hex:   $(OBJ)scsijplp.ihx $(MK)
	$(QUIET)$(COPY) $(OBJ)scsijplp.ihx $(OBJ)scsijplp.hex

$(OBJ)scsijplp.ihx:     $(OBJ)crt0jplp.rel $(TMP)scsijplp.arf $(MK)
	$(QUIET)$(COPY) $(TMP)scsijplp.arf $(TMP)scsijplp.lk
	$(QUIET)$(COPY) $(TMP)scsijplp.arf $(TMP)scsijplp.lnk
	$(QUIET)$(SDLD) $(SDLDFLG) -nf $(TMP)scsijplp.lnk
	$(QUIET)$(COPY) $(COPYFLG) scsijplp.ihx $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) scsijplp.map $(MAP)

#########################################################
# Dynamically generate linker control file for scsi2ide #
# (now uses the macro controlled ECHO feature           #
#########################################################
$(TMP)scsijplp.arf:     $(MK)
	$(ECHO) -mjx > $(TMP)scsijplp.arf
	$(ECHO) -i scsijplp.ihx >> $(TMP)scsijplp.arf
	$(ECHO) -k $(SDCCLIB) >> $(TMP)scsijplp.arf
	$(ECHO) -l z80 >> $(TMP)scsijplp.arf
	$(ECHO) $(OBJ)crt0jplp.rel >> $(TMP)scsijplp.arf
	$(ECHO) -e >> $(TMP)scsijplp.arf

############################################################
############################################################

# Build SCSISCRM ROM image

$(ROM)scsiscrm.rom:     $(OBJ)scsiscrm.bin $(MK)
	$(QUIET)$(COPY) $(OBJ)scsiscrm.bin $(ROM)scsiscrm.rom
	$(QUIET)$(DEL)  $(DELFLG)  scsiscrm.*

$(OBJ)scsiscrm.bin:   $(OBJ)scsiscrm.hex $(DWGH2B) $(MK)
	$(QUIET)$(DWGH2B) $(OBJ)scsiscrm

$(OBJ)scsiscrm.hex:   $(OBJ)scsiscrm.ihx $(MK)
	$(QUIET)$(COPY) $(OBJ)scsiscrm.ihx $(OBJ)scsiscrm.hex

$(OBJ)scsiscrm.ihx:     $(OBJ)crt0scrm.rel $(TMP)scsiscrm.arf $(MK)
	$(QUIET)$(COPY) $(TMP)scsiscrm.arf $(TMP)scsiscrm.lk
	$(QUIET)$(COPY) $(TMP)scsiscrm.arf $(TMP)scsiscrm.lnk
	$(QUIET)$(SDLD) $(SDLDFLG) -nf $(TMP)scsiscrm.lnk
	$(QUIET)$(COPY) $(COPYFLG) scsiscrm.ihx $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) scsiscrm.map $(MAP)

#########################################################
# Dynamically generate linker control file for scsiscrm #
# (now uses the macro controlled ECHO feature           #
#########################################################
$(TMP)scsiscrm.arf:     $(MK)
	$(ECHO) -mjx > $(TMP)scsiscrm.arf
	$(ECHO) -i scsiscrm.ihx >> $(TMP)scsiscrm.arf
	$(ECHO) -k $(SDCCLIB) >> $(TMP)scsiscrm.arf
	$(ECHO) -l z80 >> $(TMP)scsiscrm.arf
	$(ECHO) $(OBJ)crt0scrm.rel >> $(TMP)scsiscrm.arf
	$(ECHO) -e >> $(TMP)scsiscrm.arf

############################################################
############################################################

# Build SCSI2IDE ROM image

$(ROM)scsi2ide.rom:     $(OBJ)scsi2ide.bin $(MK)
	$(QUIET)$(COPY) $(OBJ)scsi2ide.bin $(ROM)scsi2ide.rom
	$(QUIET)$(DEL)  $(DELFLG)  scsi2ide.*

$(OBJ)scsi2ide.bin:   $(OBJ)scsi2ide.hex $(DWGH2B) $(MK)
	$(QUIET)$(DWGH2B) $(OBJ)scsi2ide

$(OBJ)scsi2ide.hex:   $(OBJ)scsi2ide.ihx $(MK)
	$(QUIET)$(COPY) $(OBJ)scsi2ide.ihx $(OBJ)scsi2ide.hex

$(OBJ)scsi2ide.ihx:     $(CPMRELS) $(SCSI2IDEHW) $(OBJ)scsi2ide.rel $(TMP)scsi2ide.arf $(MK)
	$(QUIET)$(COPY) $(TMP)scsi2ide.arf $(TMP)scsi2ide.lk
	$(QUIET)$(COPY) $(TMP)scsi2ide.arf $(TMP)scsi2ide.lnk
	$(QUIET)$(SDLD) $(SDLDFLG) -nf $(TMP)scsi2ide.lnk
	$(QUIET)$(COPY) $(COPYFLG) scsi2ide.ihx $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) scsi2ide.map $(MAP)

#########################################################
# Dynamically generate linker control file for scsi2ide #
# (now uses the macro controlled ECHO feature           #
#########################################################
$(TMP)scsi2ide.arf:     $(MK)
	$(ECHO) -mjx > $(TMP)scsi2ide.arf
	$(ECHO) -i scsi2ide.ihx >> $(TMP)scsi2ide.arf
	$(ECHO) -k $(SDCCLIB) >> $(TMP)scsi2ide.arf
	$(ECHO) -l z80 >> $(TMP)scsi2ide.arf
#       $(ECHO) -b _CCPB03 = 0xD000 >> $(TMP)scsi2ide.arf
#       $(ECHO) -b _BDOSB01 = 0xD800 >> $(TMP)scsi2ide.arf
#       $(ECHO) -b _CBIOS = 0xE600 >> $(TMP)scsi2ide.arf
#	$(ECHO) -b _DBGMON = 0x8000 >> $(TMP)scsi2ide.arf
	$(ECHO) $(OBJ)crt0.rel >> $(TMP)scsi2ide.arf
	$(ECHO) $(OBJ)scsi2ide.rel >> $(TMP)scsi2ide.arf
#	$(ECHO) $(OBJ)dbgmon.rel >> $(TMP)scsi2ide.arf
#       $(ECHO) $(OBJ)ccpb03.rel >> $(TMP)scsi2ide.arf
#       $(ECHO) $(OBJ)bdosb01.rel >> $(TMP)scsi2ide.arf
#       $(ECHO) $(OBJ)cbios.rel >> $(TMP)scsi2ide.arf
	$(ECHO) -e >> $(TMP)scsi2ide.arf

########################################################
# Compile C portion of the scsi2ide EEPROM Image
$(OBJ)scsi2ide.rel:   $(SRC)scsi2ide.c $(MK)
	$(QUIET)$(SDCC) $(SDCCFLG) -c $(SRC)scsi2ide.c
	$(QUIET)$(COPY) $(COPYFLG) scsi2ide.rel $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) scsi2ide.lst $(LST)


############################################################
############################################################

# Build SBC V2 ROM image

$(ROM)baseline.rom:	$(OBJ)baseline.bin $(MK)
	$(QUIET)$(COPY) $(OBJ)baseline.bin $(ROM)baseline.rom
	$(QUIET)$(DEL)  $(DELFLG)  baseline.*

$(OBJ)baseline.bin:   $(OBJ)baseline.hex $(DWGH2B) $(MK)
	$(QUIET)$(DWGH2B) $(OBJ)baseline

$(OBJ)baseline.hex:   $(OBJ)baseline.ihx $(MK)
	$(QUIET)$(COPY) $(OBJ)baseline.ihx $(OBJ)baseline.hex

$(OBJ)baseline.ihx:	$(CPMRELS) $(SBCV2HW) $(OBJ)baseline.rel $(TMP)baseline.arf $(MK)
	$(QUIET)$(COPY) $(TMP)baseline.arf $(TMP)baseline.lk
	$(QUIET)$(COPY) $(TMP)baseline.arf $(TMP)baseline.lnk
	$(QUIET)$(SDLD) $(SDLDFLG) -nf $(TMP)baseline.lnk
	$(QUIET)$(COPY) $(COPYFLG) baseline.ihx $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) baseline.map $(MAP)

#########################################################
# Dynamically generate linker control file for baseline #
# (now uses the macro controlled ECHO feature           #
#########################################################
$(TMP)baseline.arf:	$(MK)
	$(ECHO) -mjx > $(TMP)baseline.arf
	$(ECHO) -i baseline.ihx >> $(TMP)baseline.arf
	$(ECHO) -k $(SDCCLIB) >> $(TMP)baseline.arf
	$(ECHO) -l z80 >> $(TMP)baseline.arf
	$(ECHO) -b _CCPB03 = 0xD000 >> $(TMP)baseline.arf
	$(ECHO) -b _BDOSB01 = 0xD800 >> $(TMP)baseline.arf
	$(ECHO) -b _CBIOS = 0xE600 >> $(TMP)baseline.arf
	$(ECHO) -b _DBGMON = 0x8000 >> $(TMP)baseline.arf
	$(ECHO) $(OBJ)crt0.rel >> $(TMP)baseline.arf
	$(ECHO) $(OBJ)baseline.rel >> $(TMP)baseline.arf
	$(ECHO) $(OBJ)dbgmon.rel >> $(TMP)baseline.arf
	$(ECHO) $(OBJ)ccpb03.rel >> $(TMP)baseline.arf
	$(ECHO) $(OBJ)bdosb01.rel >> $(TMP)baseline.arf
	$(ECHO) $(OBJ)cbios.rel >> $(TMP)baseline.arf
	$(ECHO) -e >> $(TMP)baseline.arf

########################################################
# Compile C portion of the Baseline PROM Image
$(OBJ)baseline.rel:   $(SRC)baseline.c $(MK)
	$(QUIET)$(SDCC) $(SDCCFLG) -c $(SRC)baseline.c
	$(QUIET)$(COPY) $(COPYFLG) baseline.rel $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) baseline.lst $(LST)

############################################################

# Build N8 ROM image

#
# Save the resulting merged image in the Rom folder
#
$(ROM)n8.rom:     $(OBJ)n8-romim.bin $(MK)
	$(QUIET)$(COPY) $(OBJ)n8-romim.bin $(ROM)n8.rom
	$(QUIET)$(DEL) $(DELFLG) n8.*

#
# Convert the Intel hex file into a binary, similar
# to the results of the "copy /B ..."
#
$(OBJ)n8-romim.bin:   $(OBJ)sysimage.hex $(REF)n8-romim.ref $(SYSGEN) $(HEX2BIN) $(MK)
	$(QUIET)$(DWGH2B) $(OBJ)sysimage
	$(QUIET)$(COPY) $(REF)n8-romim.ref $(OBJ)n8-romim.bin
	$(QUIET)$(SYSGEN) -i $(OBJ)sysimage.bin $(OBJ)n8-romim.bin

#
# Take the output of the linker and rename to the more
# recognizable .hex form and the expected name "sysimage.hex"
#
$(OBJ)sysimage.hex:   $(OBJ)n8.ihx $(MK)
	$(QUIET)$(COPY) $(OBJ)n8.ihx $(OBJ)sysimage.hex

#
# Combine the independently assembled components into one piece
# and output Intel hex file (ihx)
#
$(OBJ)n8.ihx:	$(OBJ)loadern8.rel $(OBJ)dbgmon.rel $(OBJ)ccpb03.rel $(OBJ)bdosb01.rel $(OBJ)cbiosn8.rel $(TMP)n8.arf $(MK)
	$(QUIET)$(COPY) $(TMP)n8.arf $(TMP)n8.lk
	$(QUIET)$(COPY) $(TMP)n8.arf $(TMP)n8.lnk
	$(QUIET)$(SDLD) $(SDLDFLG) -nf $(TMP)n8.lnk
	$(QUIET)$(COPY) $(COPYFLG) n8.ihx $(OBJ)n8.ihx
	$(QUIET)$(COPY) $(COPYFLG) n8.map $(MAP)

$(OBJ)cbiosn8.rel:	$(SRC)cbiosn8.s $(MK)
	$(QUIET)$(SDAS) $(SDASFLG) $(SRC)cbiosn8.s
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)cbiosn8.rel $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)cbiosn8.lst $(LST)

$(OBJ)loadern8.rel:	$(SRC)loadern8.s $(MK)
	$(QUIET)$(SDAS) $(SDASFLG) $(SRC)loadern8.s
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)loadern8.rel $(OBJ)
	$(QUIET)$(COPY  $(COPYFLG) $(SRC)loadern8.lst $(LST)

########################################################
# Dynamically generate the linker control  file for N8 #
# Now uses the macro controlled ECHO feature           #
########################################################
$(TMP)n8.arf:	Makefile
	$(ECHO) -mjx > $(TMP)n8.arf
	$(ECHO) -i n8.ihx >> $(TMP)n8.arf
	$(ECHO) -k $(SDCCLIB) >> $(TMP)n8.arf
	$(ECHO) -l z80 >> $(TMP)n8.arf
	$(ECHO) -b _CCPB03  = 0x0900 >> $(TMP)n8.arf
	$(ECHO) -b _BDOSB01 = 0x1100 >> $(TMP)n8.arf
	$(ECHO) -b _CBIOS   = 0x1f00 >> $(TMP)n8.arf
	$(ECHO) $(OBJ)loadern8.rel >> $(TMP)n8.arf
	$(ECHO) $(OBJ)dbgmon.rel >> $(TMP)n8.arf
	$(ECHO) $(OBJ)ccpb03.rel >> $(TMP)n8.arf
	$(ECHO) $(OBJ)bdosb01.rel >> $(TMP)n8.arf
	$(ECHO) $(OBJ)cbiosn8.rel >> $(TMP)n8.arf
	$(ECHO) -e >> $(TMP)n8.arf

############################################################

# Hardware specific assemblies (most likely used by BIOS's)

#
# Assemble hardware control code for the Zilog Z53C8003V5C
#
$(OBJ)z53c80.rel:	$(SRC)z53c80.c $(MK)
	$(QUIET)$(SDCC) $(SDCCFLG) $(SRC)z53c80.c
	$(QUIET)$(COPY) $(COPYFLG) z53c80.rel $(OBJ)
	$(QUIET)$(DEL)  $(DELFLG)  z53c80.*

#
# Compile ersatz printf routine for use in CP/M-80 command files
#
$(OBJ)cprintf.rel:    $(SRC)cprintf.c $(MK)
	$(QUIET)$(SDCC) $(SDCCFLG) $(SRC)cprintf.c
	$(QUIET)$(COPY) $(COPYFLG) cprintf.rel obj
	$(QUIET)$(DEL)  $(DELFLG)  cprintf.*

############################################################

# Build CP/M 2.2 command files (copyfile.com, fdisk.com)

#-----------------------------------------------------------

$(COM)copyfile.com:     $(OBJ)copyfile.com $(MK)
	$(QUIET)$(COPY) $(OBJ)copyfile.com $(COM)copyfile.com
	$(QUIET)$(DEL)  $(DELFLG) copyfile.*

$(OBJ)copyfile.com:   $(OBJ)copyfile.hex $(LOAD) $(BINFILES) $(MK)
	$(QUIET)$(LOAD) $(OBJ)copyfile

$(OBJ)copyfile.hex:   $(OBJ)copyfile.ihx $(MK)
	$(QUIET)$(COPY) $(OBJ)copyfile.ihx $(OBJ)copyfile.hex

$(OBJ)copyfile.ihx:   $(OBJ)copyfile.rel $(COMRELS) $(TMP)copyfile.arf $(MK)
	$(QUIET)$(COPY) $(TMP)copyfile.arf $(TMP)copyfile.lnk

	$(QUIET)$(SDLD) $(LOPTS) -nf $(TMP)copyfile.lnk
	$(QUIET)$(COPY) $(COPYFLG) copyfile.ihx obj
	$(QUIET)$(COPY) $(COPYFLG) copyfile.map map

##############################################################
# Dynamicaly create linker command file for copyfile utility #
# Now uses the macro controlled ECHO feature                 #
##############################################################
$(TMP)copyfile.arf:	Makefile
	$(ECHO) -mjx > $(TMP)copyfile.arf
	$(ECHO) -i copyfile.ihx >> $(TMP)copyfile.arf
	$(ECHO) -k $(SDCCLIB) >> $(TMP)copyfile.arf
	$(ECHO) -l z80 >> $(TMP)copyfile.arf
	$(ECHO) $(OBJ)cpm0.rel >> $(TMP)copyfile.arf
	$(ECHO) $(OBJ)copyfile.rel >> $(TMP)copyfile.arf
	$(ECHO) $(OBJ)cpmbdos.rel >> $(TMP)copyfile.arf
	$(ECHO) $(OBJ)cprintf.rel >> $(TMP)copyfile.arf
	$(ECHO) -e >> $(TMP)copyfile.arf

$(OBJ)copyfile.rel:	$(SRC)copyfile.c $(MK)
	$(QUIET)$(SDCC) $(SDCCFLG) $(SRC)copyfile.c
	$(QUIET)$(COPY) copyfile.rel obj
	$(QUIET)$(DEL) $(DELFLG) copyfile.rel
	ls obj

#-----------------------------------------------------------

#
# Use locally compiled 'load' command to covert  Intel
# hex formal file to a binary CP/M-80 command file.
#
$(COM)fdisk.com:      $(OBJ)fdisk.hex $(TOOLS) $(MK)
	$(QUIET)$(BIN)load $(OBJ)fdisk
	$(QUIET)$(COPY) $(COPYFLG) $(OBJ)fdisk.com com
	$(QUIET)$(DEL) $(DELFLG) fdisk.*

#
# rename 'ihx' output of linker to 'hex'
										
$(OBJ)fdisk.hex:      $(OBJ)fdisk.ihx $(MK)
	$(QUIET)$(COPY) $(OBJ)fdisk.ihx $(OBJ)fdisk.hex

$(OBJ)fdisk.ihx:      $(OBJ)fdisk.rel $(TMP)fdisk.arf $(MK)
	$(QUIET)$(COPY) $(TMP)fdisk.arf $(TMP)fdisk.lnk
	$(QUIET)$(COPY) $(TMP)fdisk.arf $(TMP)fdisk.lk
	$(QUIET)$(SDLD) $(SDLDFLG) -nf $(TMP)fdisk.lnk
	$(QUIET)$(COPY) $(COPYFLG) fdisk.ihx $(OBJ)fdisk.ihx
	$(QUIET)$(COPY) $(COPYFLG) fdisk.map map

$(OBJ)fdisk.rel:      $(SRC)fdisk.c $(INCFILES) $(MK)
	$(QUIET)$(SDCC) -I inc $(SDCCFLG) $(SRC)fdisk.c
	$(QUIET)$(COPY) $(COPYFLG) fdisk.rel $(OBJ)

############################################################################
# Dynamically created linker command file for fdisk utility (CP/M version) #
# Now uses macro controlled ECHO feature                                   #
############################################################################
$(TMP)fdisk.arf:	$(MK)
	$(ECHO) -mjx > $(TMP)fdisk.arf
	$(ECHO) -i fdisk.ihx >> $(TMP)fdisk.arf
	$(ECHO) -k $(SDCCLIB) >> $(TMP)fdisk.arf
	$(ECHO) -l z80 >> $(TMP)fdisk.arf
	$(ECHO) $(OBJ)cpm0.rel >> $(TMP)fdisk.arf
	$(ECHO) $(OBJ)fdisk.rel >> $(TMP)fdisk.arf
	$(ECHO) $(OBJ)cpmbdos.rel >> $(TMP)fdisk.arf
	$(ECHO) $(OBJ)cprintf.rel >> $(TMP)fdisk.arf
	$(ECHO) -e >> $(TMP)fdisk.arf


#-----------------------------------------------------------

# Also build host version of fdisk for testing purposes

$(BIN)fdisk$(EXE):     $(SRC)fdisk.c $(MK)
	$(QUIET)$(TCC) $(TCCFLG) $(SRC)fdisk.c -o $(BIN)fdisk 

############################################################

# Build CP/M-80 Command File Structure Files

$(OBJ)cpm0.rel:       $(SRC)cpm0.s $(MK)
	$(QUIET)$(SDAS) $(SDASFLG) $(SRC)cpm0.s 
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)cpm0.rel $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)cpm0.lst $(LST)

$(OBJ)cpmbdos.rel:    $(SRC)cpmbdos.s $(MK)
	$(QUIET)$(SDAS) $(SDASFLG) $(SRC)cpmbdos.s
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)cpmbdos.rel $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)cpmbdos.lst $(LST)

############################################################

# Build ROM Image structure files

$(OBJ)crt0.rel:       $(SRC)crt0.s    $(MK)
	$(QUIET)$(SDAS) $(SDASFLG) $(SRC)crt0.s
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)crt0.rel $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)crt0.lst $(LST)

$(OBJ)crt0jplp.rel:       $(SRC)crt0jplp.s    $(MK)
	$(QUIET)$(SDAS) $(SDASFLG) $(SRC)crt0jplp.s
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)crt0jplp.rel $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)crt0jplp.lst $(LST)

$(OBJ)crt0scrm.rel:       $(SRC)crt0scrm.s    $(MK)
	$(QUIET)$(SDAS) $(SDASFLG) $(SRC)crt0scrm.s
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)crt0scrm.rel $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)crt0scrm.lst $(LST)

$(OBJ)bdosb01.rel:    $(SRC)bdosb01.s $(MK)
	$(QUIET)$(SDAS) $(SDASFLG) $(SRC)bdosb01.s
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)bdosb01.rel $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)bdosb01.lst $(LST)

$(OBJ)ccpb03.rel:     $(SRC)ccpb03.s $(MK)
	$(QUIET)$(SDAS) $(SDASFLG) $(SRC)ccpb03.s
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)ccpb03.rel $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)ccpb03.lst $(LST)

#
# Assemble hardware control code for SBC V2
#
$(OBJ)cbios.rel:      $(SRC)cbios.s $(MK)
	$(QUIET)$(SDAS) $(SDASFLG) $(SRC)cbios.s
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)cbios.rel $(OBJ)
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)cbios.lst $(LST)

#
# Assemble a monitor program for the SBC V2
#
$(OBJ)dbgmon.rel:     $(SRC)dbgmon.s $(MK)
	$(QUIET)$(SDAS) $(SDASFLG) $(SRC)dbgmon.s
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)dbgmon.rel $(OBJ) 
	$(QUIET)$(COPY) $(COPYFLG) $(SRC)dbgmon.lst $(LST)

###########################################################

# Build host based tools ( dwgh2b, jrch2b, load, verify)

$(DWGH2B):   $(SRC)dwgh2b.c $(MK)
	$(QUIET)$(TCC) $(TCCFLG) $(SRC)dwgh2b.c -o $(BIN)dwgh2b$(EXE)

#
# Compile John Coffman's hex2bin program
#
$(JRCH2B):	$(SRC)jrch2b.c $(MK)
	$(QUIET)$(TCC) $(TCCFLG) $(SRC)jrch2b.c -o $(BIN)jrch2b$(EXE)
	$(QUIET)$(COPY) $(COPYFLG) $(BIN)jrch2b $(BIN)jrcb2h

#
# Compile Doug's "load" program 
#
$(LOAD):      $(SRC)load.c $(MK)
	$(QUIET)$(TCC) $(TCCFLG) $(SRC)load.c -o $(BIN)load$(EXE)

$(SYSGEN):	$(SRC)sysgen.c $(MK)
	$(QUIET)$(TCC) $(TCCFLG) $(SRC)sysgen.c -o $(BIN)sysgen$(EXE)

#
# Compile Doug's verif program that compares binary file regions
#
$(VERIFY):  $(SRC)verify.c Makefile $(MK)
	$(QUIET)$(TCC) $(TCCFLG) $(SRC)verify.c -o $(BIN)verify
																				
$(BIN)lechocr:	$(SRC)lechocr.c $(MK)
#	$(QUIET)$(TCC) $(TCCFLG) $(SRC)lechocr.c -o $(BIN)lechocr
	$(QUIET)$(TCC) $(TCCFLG) $(SRC)lechocr.c
	$(QUIET)$(COPY) lechocr.exe $(BIN) 

$(BIN)lecholf:	$(SRC)lecholf.c $(MK)
#	$(QUIET)$(TCC) $(TCCFLG) $(SRC)lecholf.c -o $(BIN)lecholf
	$(QUIET)$(TCC) $(TCCFLG) $(SRC)lecholf.c
	$(COPY) lecholf.exe $(BIN)

$(BIN)lechocrlf:	$(SRC)lechocrlf.c $(MK) 
	$(QUIET)$(TCC) $(TCCFLG) $(SRC)lechocrlf.c -o $(BIN)lechocrlf

$(BIN)lecholfcr:	$(SRC)lecholfcr.c $(MK)
#	$(QUIET)$(TCC) $(TCCFLG) $(SRC)lecholfcr.c -o $(BIN)lecholfcr
	$(QUIET)$(TCC) $(TCCFLG) $(SRC)lecholfcr.c -o $(BIN)lecholfcr

############################################################

# Builder specific utility rules

dwginstall:
	$(COPY) $(COMFILES) ~/Documents/devobox/cdrive

############################################################

#
# Delete all dynamically generated files that don't need to be
# saved.
#
clean:
	$(QUIET)$(DEL) $(DELFLG) *.hex *.ihx *.lst *.rel *.rst *.lnk *.lk
	$(QUIET)$(DEL) $(DELFLG) *.sym *.map *.noi *.asm *.com *.ini *.bin
	$(QUIET)$(DEL) $(DELFLG) obj$(DELIM)*.*
	$(QUIET)$(DEL) $(DELFLG) bin$(DELIM)*.*
	$(QUIET)$(DEL) $(DELFLG) com$(DELIM)*.*
	$(QUIET)$(DEL) $(DELFLG) rom$(DELIM)*.*
	$(QUIET)$(DEL) $(DELFLG) tmp$(DELIM)*.*
	$(QUIET)$(DEL) $(DELFLG) map$(DELIM)*.*
	$(QUIET)$(DEL) $(DELFLG) lst$(DELIM)*.*

##################
# eof - Makefile #
##################
