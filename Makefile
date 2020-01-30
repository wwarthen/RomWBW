all:
	cd Tools/unix ; make install
	cd Source ; make all

clean:
	cd Tools/unix ; make clean
	cd Source ; make clean
	cd Binary ; make clean

clobber:
	cd Tools/unix ; make clobber
	cd Source ; make clobber
	cd Binary ; make clobber

diff:
	cd Source ; make diff

