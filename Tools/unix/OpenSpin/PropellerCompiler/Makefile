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

LIBNAME=$(BUILD)/libopenspin.a
SRCDIR=.
OBJ=$(BUILD)/BlockNestStackRoutines.o \
	$(BUILD)/CompileDatBlocks.o \
	$(BUILD)/CompileExpression.o \
	$(BUILD)/CompileInstruction.o \
	$(BUILD)/CompileUtilities.o \
	$(BUILD)/DistillObjects.o \
	$(BUILD)/Elementizer.o \
	$(BUILD)/ErrorStrings.o \
	$(BUILD)/ExpressionResolver.o \
	$(BUILD)/InstructionBlockCompiler.o \
	$(BUILD)/StringConstantRoutines.o \
	$(BUILD)/SymbolEngine.o \
	$(BUILD)/Utilities.o \
	$(BUILD)/UnusedMethodUtils.o \
	$(BUILD)/PropellerCompiler.o \
	$(BUILD)/CompileSpin.o \
	$(BUILD)/flexbuf.o \
	$(BUILD)/preprocess.o \
	$(BUILD)/textconvert.o \
	$(BUILD)/objectheap.o


all: $(BUILD) $(LIBNAME) Makefile

$(LIBNAME): $(OBJ)
	$(AR) rs $@ $^

$(BUILD)/%.o: $(SRCDIR)/%.cpp
	$(CXX) $(CXXFLAGS) -o $@ -c $<

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)
