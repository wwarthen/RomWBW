#!/usr/bin/python


# Written by Douglas Goodall 17:25 Wed, Jan 30, 2013

import sys
import os
import serial

filename = "rem.com"

print "*******************************************************************"
print "sendsave.py 1/30/2013 dwg - deliver file to cp/m using save and ddt"
print "*******************************************************************"
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

statinfo = os.stat(filename)
filelen =  statinfo.st_size

beg = 0x100
end = beg + filelen - 1

print "Target file is " + filename + " length is 0x" + hex(filelen) + "\n"

infile = open(filename,'rb');
data = infile.read()
infile.close()

ser = serial.Serial('/dev/cu.PL2303-0000201D', 19200, timeout=1)

# flush input queue
ser.read()

ser.write("\n")
print ser.read(80)

ser.write("save\n")
print ser.read(80)

ser.write("ddt\n")
print ser.read(128)

ser.write("s100\n")
print ser.read(20)

for x in range(1,filelen):
	ser.write(safebyte(data[x-1]))
	ser.write("\n")
	print ser.read(32)
	
ser.write(".\n")
print ser.read(200)

ser.write("g0\n")
print ser.read(160)

ser.write(filename)
ser.write("\n")
print ser.read(128)

ser.write("yes\n")
print ser.read(128)

ser.write(safeword(beg))
ser.write("\n")
print ser.read(128)

ser.write(safeword(end))
ser.write("\n")
print ser.read(128)

ser.write("\n")
print ser.read(128)

