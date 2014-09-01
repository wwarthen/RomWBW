#!/usr/bin/python
import serial

def memcmd():
	ser.flushInput()
	str = "A"
	ser.write(str)
	print ser.read(1024)

def menucmd():
	ser.flushInput()
	str = "k"
	ser.write(str)
	print ser.read(1024)

def portscmd():
	ser.flushInput()
	str = "R"
	ser.write(str)
	print ser.read(1024)

def dispcmd(beg,end):
	ser.flushInput()
	str = "D" + repr(beg) + " " + repr(end) + " "
	ser.write(str)
#	print ser.read(4096)
	print ser.read( ((end+1-beg)/16*80)+100 )

def reset():
	ser.flushInput()
	str = "GF000 "
	ser.write(str)
	print ser.read(256)

def getpage(startaddr):
	ser.flushInput()
	str = "D" + repr(startaddr) + " " + repr(startaddr+255) + " "
	print str
	ser.write(str)
	print ser.read(4096)


ser = serial.Serial('/dev/cu.PL2303-0000201D', 38400, timeout=2)
#reset()
#menucmd()
#portscmd()
#dispcmd(1000,1300)
#getpage(256)
#dispcmd(256,256+2)
#reset()
#getpage(0)
d1 = 100
d2 = d1 + 255
dispcmd(d1,d2)


