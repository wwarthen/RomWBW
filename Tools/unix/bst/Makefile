#
# build the propeller tools for linux and Darwin
#
UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
	SUFFIX=linux
endif
ifeq ($(UNAME), Darwin)
	SUFFIX=osx
endif

DEST = ../../$(UNAME)

all: $(DEST)
	-for i in *.$(SUFFIX) ; do \
		chmod +x $$i ; \
		cp -p $$i $(DEST)/$$(basename $$i .$(SUFFIX)) ; \
	done

$(DEST):
	mkdir $(DEST)

clean:
