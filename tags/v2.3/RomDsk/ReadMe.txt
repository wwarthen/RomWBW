This is the parent directory for all files to
be included in the rom disk when the ROM is built.

When constructing the ROM disk as part of a build,
the build process first grabs all of the "standard"
files for the size of ROM being built and the type
of the OS being used.  So, if you are building a
ZSystem, 1MB ROM, all of the files in zsys_1024KB
will be pulled in.  If you are building a CP/M
512KB ROM, then all the files in cpm_512KB will
be pulled in.

After adding all of the standard files for the
size of ROM being built, the build process will
add the files from the appropriate configuration
directory.  So, if you are building the "zeta"
configuration, all of the files in the cfg_zeta
directory will be added.

Finally, the build process will gather all of the
custom applications created by Douglas in the 
Apps directory and add those.

If you are building your own ROM, you will need to
add a new directory of the name cfg_xxx where xxx
is the name of your configuration that matches the
config_xxx.asm file in the Source directory.  You
will want to add any specific files you want added
to your ROM build to this directory.  Note that the
build will complain if there are no files in your
custom configuration directory, but it is not a
real problem (error can be ignored).