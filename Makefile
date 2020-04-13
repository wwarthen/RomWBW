all:
	cd Tools/unix ; make
	cd Source ; make
	cd Source/Images ; make

clean:
	cd Tools/unix ; make clean
	cd Source ; make clean
	cd Binary ; make clean

clobber:
	cd Tools/unix ; make clobber
	cd Source ; make clobber
	cd Binary ; make clobber
	rm -f typescript

diff:
	cd Source ; make diff

