#!/usr/bin/python
# Written by Douglas Goodall 17:25 Wed, Jan 30, 2013
# load cpm.bin and bios.bin then jump

import sys
import os
import serial

# passing in a string  either "12" or "0x12"
# return value is string of hex digits only (no 0x)
def safebyte(parm):
        xyz = parm
        myord = ord(xyz)
        hexdata = hex(myord)
        newstr = hexdata
        if (hexdata[0] == '0'):
                if(hexdata[1] == 'x'):
                        newstr = hexdata[2]
                        if(len(hexdata)>3):
                                newstr = newstr + hexdata[3]
        return newstr

# passing in a string either "1234" of  "0x1234"
# return value is string of hex digits only (1234) (no 0x)
def safeword(parm):
	xyz = parm
	myint = int(xyz)
	hexdata = hex(myint)
	newstr = hexdata
	if (hexdata[0] == '0'):
		if(hexdata[1] == 'x'):
			newstr = hexdata[2] 
			if(len(hexdata)>3):
				newstr = newstr + hexdata[3]
				if(len(hexdata)>4):
					newstr = newstr + hexdata[4]
					if(len(hexdata)>5):
						newstr = newstr + hexdata[5]
	return newstr

def loadngo(filename):
	statinfo = os.stat(filename)
	filelen  = statinfo.st_size
	infile = open(filename,'rb')
	filedata = infile.read()
	infile.close()
	ser = serial.Serial('/dev/cu.PL2303-0000201D', 19200, timeout=10)
	ser.write("\n\n")
	ser.write("sa400\n")
	print ser.read(12);
	for x in range(1,filelen):
        	ser.write(safebyte(filedata[x-1]))
        	ser.write(" ")
        	print ser.read(12)
	ser.write("\n")
	print ser.read(12)
	ser.close()

print "*******************************************************************"
print "loadcpm.py 1/30/2013 dwg - load&go S-100 CP/M using master-yoda ROM"
print "*******************************************************************"
#loadngo("cpm.bin")
ser = serial.Serial('/dev/cu.PL2303-0000201D', 19200, timeout=1)
ser.read(128)
ser.read(128)
ser.write("\n")
ser.close()
loadngo("cpm.bin")

