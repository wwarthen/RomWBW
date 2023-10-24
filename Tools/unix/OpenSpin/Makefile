# modified for RomWBW build environment

UNAME := $(shell uname)
DEST = ../../$(UNAME)

# cross compilation scheme taken from Eric Smith's spin2cpp compiler
# if CROSS is defined, we are building a cross compiler
# possible targets are: win32, rpi

ifeq ($(CC),)
  CC=gcc
endif

ifeq ($(CXX),)
  CXX=g++
endif

ifeq ($(CROSS),win32)
  CC=i686-w64-mingw32-gcc
  CXX=i686-w64-mingw32-g++
  EXT=.exe
  BUILD=./build-win32
else ifeq ($(CROSS),rpi)
  CC=arm-linux-gnueabihf-gcc
  CXX=arm-linux-gnueabihf-g++
  EXT=
  BUILD=./build-rpi
else
  EXT=
  BUILD=./build
endif

OS:=$(shell uname)

ifeq ($(OS),Darwin)
	CFLAGS+=-Wall -g -Wno-self-assign
else
	CFLAGS+=-Wall -g $(MSTATIC)
endif

CXXFLAGS += $(CFLAGS)

TARGET=$(BUILD)/openspin$(EXT)
SRCDIR=SpinSource
OBJ=$(BUILD)/openspin.o \
	$(BUILD)/pathentry.o

LIBNAME=$(BUILD)/PropellerCompiler/libopenspin.a

all: $(BUILD) $(DEST) $(LIBNAME) $(OBJ) Makefile
	$(CXX) -o $(TARGET) $(CXXFLAGS) $(OBJ) $(LIBNAME)
	cp -p $(TARGET) $(DEST)

$(BUILD)/%.o: $(SRCDIR)/%.cpp
	$(CXX) $(CXXFLAGS) -o $@ -c $<

$(LIBNAME): $(BUILD)
	$(MAKE) -C PropellerCompiler CROSS=$(CROSS) BUILD=$(realpath $(BUILD))/PropellerCompiler all

$(BUILD):
	mkdir -p $(BUILD)

$(DEST):
	mkdir -p $(DEST)

clean:
	rm -rf $(BUILD)
	make -C PropellerCompiler BUILD=$(realpath $(BUILD))/PropellerCompiler clean
