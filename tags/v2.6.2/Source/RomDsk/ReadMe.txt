This is the parent directory for all files to
be included in the rom disk when the ROM is built.

When constructing the ROM disk as part of a build,
the build process first grabs all of the "standard"
files for the size of ROM being built and the type
of the OS being used.  So, if you are building a
ZSystem, 1MB ROM, all of the files in ZSYS_1024KB
will be pulled in.  If you are building a CP/M
512KB ROM, then all the files in CPM_512KB will
be pulled in.

After adding all of the standard files for the
size of ROM being built, the build process will
add the files from the appropriate configuration
directory.  So, if you are building the standard
Zeta configuration (zeta_std), all of the files
in the zeta_std directory will be added.

If you are building your own ROM, you will need to
add a new directory of the name xxx_yyy where xxx
is the name of your platform (N8VEM, N8, ZETA, etc.)
and yyy is the name of the configuration you have
created.  The xxx_yyy name must match the
xxx_yyy.asm file in the Config directory.  You
will want to add any specific files you want added
to your ROM build to this directory.  Note that the
build will complain if there are no files in your
custom configuration directory, but it is not a
real problem (error can be ignored).