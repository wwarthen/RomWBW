# These variations of ZDE are built here as reference copies.  They
# are not copied anywhere else during the build.
# The resulting .COM files are manually
# copied to /Source/Images/d_ws/u1 as needed.

OBJECTS = zde16.com zde16a.com zde17.com zde18.com zde19.com
DEST = ../../../Binary/Apps/ZDE
TOOLS = ../../../Tools
OTHERS = *.hex

include $(TOOLS)/Makefile.inc

zde16a.com: zde16.com zde16a.pat
	$(ZXCC) ZMAC zde16a.pat -/H
	$(ZXCC) MLOAD25 zde16a=zde16.com,zde16a.hex || exit /b
