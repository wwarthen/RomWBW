README.win32.cygwin.txt
-----------------------

Building cpmtools-2.9 in Windows XP using:

- cpmtools http://www.moria.de/~michael/cpmtools/
- cygwin and the ncurses library - http://www.cygwin.com/

"The experts will always complain about shorter documents that do do not
provide enough details to confuse the rest of us, and longer documents that
do not omit enough details to confuse the rest of us. No documentation is
needed for people of that calibre."

- Bill Buckels, November 2008

This document is provided in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE. In particular, Bill Buckels has no warranty obligations
or liability resulting from its use in any way whatsoever. If you don't agree
then don't read it.

Introduction
------------

This document is intended as a general guideline. An annotated summary is
provided directly below especially for expert users followed by annotated
details.

Please review the other documentation and source code that comes with
cpmtools for more information about cpmtools. Please review the cygwin
documentation for more information about cygwin.

At time of this writing, I have used the latest versions of the packages
listed above to build the latest version of cpmtools in its entirety. I have
documented the steps I followed below. 

Although there are probably other environments and compilers that can build
cpmtools for Windows I have not been successful in using the other several I
tried. Using a complete cygwin installation I had no problems and I had
cpmtools built in moments after I had cygwin installed and the cpmtools
source in place as documented below.

Intended Audience
-----------------

This document takes two tracks for installing cpmtools binary executables
after they have been built in cygwin:

1. End users who will run cpmtools from within the cygwin shell. This
includes unix users who do not want to use the native Windows command line.

2. End users who will run cpmtools from the native Windows command line. The
average Windows user does not have cygwin, and probably won't want to install
cygwin or learn a unix-like shell to use cpmtools.

The consideration here is where cpmtools looks for its CP/M disk format
definitions file (diskdefs) when not in a unix-like environment like cygwin
and this consideration will affect the way you build cpmtools since this path
is hardcoded into the binary executables.

My hope is that this document will help address the needs of both types of
Windows end users and those who wish to provide cpmtools to them.

Summary 
-------

- Install cygwin with ncurses.
- Download cpmtools-2.9.tar.tar to your cygwin home directory.
- Start cygwin from the shortcut on the Windows desktop.

- Enter the following commands:

tar -xvf cpmtools.tar.tar
cd cpmtools-2.9
./configure --with-diskdefs=/usr/local/share/diskdefs
make
mkdir /usr/local/share
mkdir /usr/local/share/man
mkdir /usr/local/share/man/man1
mkdir /usr/local/share/man/man5
make install

Assumptions
-----------

The above builds cpmtools under cygwin for end users who will use cpmtools in
the cygwin shell and who will use the default installation.

I am assuming in this summary that all has gone well and that anyone who
deviates from what I have done or who has customized their cygwin
installation will be able to troubleshoot their own problems,

I therefore make the following related assumptions in this summary:

- That compiler related programs and libraries required to build cpmtools
under cygwin (including ncurses) are installed.

- That you wish to download into and work under your home directory. You may
also consider whether a better place to download is in /usr/local/src and
whether you should install in the binaries in /opt/cpmtools/ and things of
that nature.
 
Default Format
--------------

You can change the default format to accomodate the special needs of your
users so they don't need to type their favorite format. The following line
can be entered to configure for an apple-do default format:

./configure --with-defformat="apple-do" --with-diskdefs=/usr/local/share/diskdefs

Native Windows Installation
---------------------------

If you wish to distribute your binaries to Windows end users who will not
have the cygwin shell and who will use the Windows command line, you have 2
options:

1. Require your users to always work in the same directory as diskdefs.

- or -

2. Hardcode the default diskdefs path into your binary executables and
require your users to always use the expected directory for diskdefs.

The following line shows how to configure for an apple-do default format and
to set the default diskdefs path in a mannner that is acceptable to Windows
to a relative path from the root of the current drive:

./configure --with-defformat="apple-do" --with-diskdefs=/cpmtools/diskdefs

Cross-Cygwin Binary Installation
--------------------------------

You can still use the binaries built as above and installed using "make
install" in cygwin if you add the following line to /etc/fstab (assuming your
cygdrive is the Windows C:drive):

c:\cygwin\usr\local\share /cpmtools

Making a Zip Installation for Native Windows Users
--------------------------------------------------

If your target is the Windows user who does not have cygwin you can do the
following in cygwin in your build directory to create a zip file that will
contain the cpmtools binary executables:

- mkdir cpmtools
- cp *.exe cpmtools/.
- cp diskdefs cpmtools/.
- cp /bin/cygwin1.dll cpmtools/.
- cp /bin/cygncurses-8.dll cpmtools/.
- zip -R cpmtools/*.*

Making Documentation for Native Windows Users
---------------------------------------------

If you wish to provide the cpmtools manual pages in html format you can use
man2html to generate your html in ugly format and redirect to a file and edit
by hand. Here's an example:

man2html -r cpm.5 > cpm.html

If you wish to avoid html and provide the cpmtools manual pages in text
format you can use troff to generate your text in ugly format and redirect to
a file and edit by hand. Here's an example:

troff -a cpm.5 > cpm.txt

This concludes the summary. 

Details, Alternatives, and Other Fluff
--------------------------------------

1.cygwin
--------

Cygwin gave me a complete and free environment to both configure and build
cpmtools in its entirety.

I installed cygwin from http://www.cygwin.com/ in its entirety which included
the ncurses library and when prompted to select a download site I chose 
ftp://mirrors.kernel.org/sourceware/cygwin/

The site you pick will depend on your own preference and how much of cygwin
you decide to install will be up to you. I have a good Internet connection
and a large hard disk so installing ALL of cygwin was no problem for me.
Those who don't may wish to attempt an incremental installation which I
personally found to be annoying and tedious.

It is not necessary to install ALL cygwin options. Another alternative is to
take the minimalistic approach and just install the compiler related
programs and libraries required to build cpmtools (including ncurses). If you
have missed something you will still be able to select additional components
via Cygwin Setup.

By default cygwin installs into c:\cygwin and puts a shortcut on the Windows
desktop. By default the cygwin shell starts in your cygwin home directory
under c:\cygwin\home\. I used the cygwin default paths for my installation of
cygwin.

2. cpmtoools
------------

I then downloaded Download cpmtools-2.9 from 
http://www.moria.de/~michael/cpmtools/
and used WinRAR to extract cpmtools-2.9 to  
C:\cygwin\home\bbuckels\cpmtools-2.9\

I have noted in the summary that tar can be used. Use whatever you are
comfortable with to handle things from unix of a tarball nature.

3. Building 
-----------

3.1. I started cygwin by clicking on the cygwin shortcut on my desktop which
placed me into my cygwin home directory in the cygwin shell.

3.2  Now in the cygwin shell, I changed to the cpmtools directory by typing
the following and pressing the [Enter] key:

cd cpmtools-2.9


3.3 Running the configure script
--------------------------------

Before making cpmtools, the configure script must be run to create the
cpmtools makefile and the config.h header file required by cpmtools.

I ran the configure script with two options; to set the default format for
cpmtools to Apple II DOS 3.3 disk images and to tell cpmtools where to find
the diskdefs format definitions file (which is required to run cpmtools. See
far below.)

3.3.2 Building for use in the cygwin shell
------------------------------------------

If I was building for use in the cygwin shell and I was using the default
paths used by "make install" noted far below, to be certain that my diskdefs
file would be found and to set my default format to "apple-do" I would type
the following and press the [Enter] key:

./configure --with-defformat="apple-do" --with-diskdefs=/usr/local/share/diskdefs

3.3.1  Building for the Native Windows command line
---------------------------------------------------

To set the default format to "apple-do" and to provide a relative path for
native Windows to my diskefs file which I would later copy to C:\cpmtools\ ,
I typed the following and pressed the [Enter] key:

./configure --with-defformat="apple-do" --with-diskdefs=/cpmtools/diskdefs

Note: Windows paths are typed into the Windows native command line with
backslashes in the MS- DOS tradition. Historically the forward slash used by
unix as a path separator was used as a switch character in MS-DOS utilities
and this has carried forward with the commands that come with Windows. But in
a program, local Windows paths can be used with forward slashes instead and
they still work. Backslashes will cause problems for configure so use forward
slashes.

3.4. The configure script created my cpmtools makefile and config.h with the
options I chose. I then ran make by typing the following and pressing the
[Enter] Key.

make

This concludes the first part of the details section of this document and I
have covered the basic steps that I followed to build cpmtools. What you do
will likely be a close variation.

4. Installing
-------------

4.1 Some of this is also noted in the summary. Also keep in mind that if
cpmtools is used outside of cygwin access to the documentation which is in
the form of unix-style man pages will not be available unless reformatted to
a media type that Windows users are familiar with.

4.1.1 Installing for the cygwin shell
-----------------------------------

You can review the summary and the cpmtools INSTALL document for more
information on unix-like installations. Installation of cpmtools for use in
the cygwin shell follows those conventions.

If installing cpmtools to be used in cygwin using the cpmtools defaults and
assuming the directories below don't already exist, you will need to manually
create the following directories using the mkdir command as follows:

mkdir /usr/local/share
mkdir /usr/local/share/man
mkdir /usr/local/share/man/man1
mkdir /usr/local/share/man/man5

This is because the manual pages (man pages) will not be installed if you
don't. If you install the man pages, then when you need help on cpmtools in
cygwin, you can just enter "man cpmls" or "man cpmchmod", etc. 

After you make the directories above enter the following command:

make install

Assuming all has gone well, cpmtools is now part of your cygwin installation
and can be used wherever you work in cygwin. 

4.1.2 Installing for Use Outside Cygwin
---------------------------------------

Please also read the summary.

The requirements of my installation were to create a directory structure for
a binary executable version of cpmtools targetted at Apple II disk image
users that would run at the native Windows cmd prompt. I offer the following
for general reference. The cygwin paths are based on my installation of
cygwin and are presented using conventional windows pathname notation.

4.1.2.1 Dll's
-------------

Two dll's from the c:\cygwin\bin\ directory were required:

cygwin1.dll
cygncurses-8.dll

Regardless of installation, for this cygwin and this ncurses version access
to these dll's will be required by this version of the cpmtools excecutables.

4.2 Manually Placing Files for Use Outside Cygwin
-------------------------------------------------

I did my installation by hand. 

My executables were created in c:\cygwin\home\bbuckels\cpmtools-2.9\ (my
cygwin home directory) which is also where the diskdefs file was.

I used Windows Explorer to manually do the following:

4.2.1 create c:\cpmtools\ directory.
4.2.2 copy all 8 exes into c:\cpmtools\
4.2.3 copy both dll's listed above into c:\cpmtools\
4.2.4 copy diskdefs into c:\cpmtools\

This gave me my directory structure and files for testing and distribution.

I also placed an Apple II CP/M disk image called EXMPLCPM.dsk in c:\cpmtools\
as a test target.


5. Additional Notes 
-------------------

5.1 diskdefs - CP/M disk format definitions
--------------------------------------------

The diskdefs file is a plain ascii text file that serves as a database of
disk and disk image format definitions. It can be reviewed for available CP/M
formats and their names. For Apple II CP/M 80 users the disk image formats
apple-do and apple-po are available.

The possible locations where cpmtools first looks for the diskdefs file:

- Can vary depending on the preferences of the person who builds the cpmtools
binaries (executables) from the source code.

- The location is also installation dependent and the diskdefs file may also
have been renamed (but we hope not).

If it's not found the current (work) directory is then searched for a file
called diskdefs.

On a unix-like system, a ${prefix}/share/ style path like /usr/local/share/
is a possible place that cpmtools could be made to first look for diskdefs.

In a Win32 system sometimes unix-like shells like cygwin are used to run
cpmtools instead of Windows cmd. For those installations unix-like
conventions probably should apply.

For cpmtools installations targetted at the average Windows user who does not
have a unix-like shell and uses the Windows cmd prompt to run cpmtools there
is no standard shared place that cpmtools can be made to first look for
diskdefs. Pathed File names like \cpm\diskdefs or even c:\cpmtools\diskdefs
are possible.

5.2 Difficulties in using the Windows File System
---------------------------------------------------

This is not a troubleshooting guide. Unless you wish to find-out for yourself
as I did just how many problems you can face with all of this, or you are
really an expert, please do yourself a favour and try to stay within what I
am suggesting as standard or alternative ways of building cpmtools.

Missing libaries and compiler tools can be solved by trial and error and
reading the cygwin and cpmtools documentation.

There are however some things about path names and file names that you need
to be aware of, some of which I have mentioned throughout this document and
some which I deliberately did not mention yet, like avoiding absolute paths
and drive letters.

If you use a drive letter like C: when hardcoding a path to diskdefs you are
making several assumptions:

First off, you are assuming that your build of cpmtools will only be run from
within Windows cmd shell on the local drive C:, (not from a bash-like shell
like cygwin which doesn't support drive letters the same way Windows cmd and
Windows itself does), and that diskdefs will not be on another drive, and
that drive C: exists in the first place, and that diskdefs is not on a
Windows network either unless drive C:,X:,Y:,Z:,etc is a mapped network
drive. It is questionable whether cpmtools build process for diskdefs pathing
supports UNC pathing anyway. I couldn't get \\ to work since the first slash
disappears in the configure script and the second slash becomes an escape
sequence for the next letter. 

Relative pathing will work and if you want to use conventions like
/cpmtools-2.9/diskedefs this will work. Environments like ${USERPROFILE}
aren't a good idea even if I could have got them to work since they are not
portable for several reasons and I will say no more on this except I
recommend that any path that you decide to use for diskdefs will only be
almost portable between shells if off the root directory and contains forward
slashes and no drive letters or colons.

I hope what I have said proved less confusing to read than to write if you
have bothered to read it. If you are not confused yet read further.

- Since cpmtools has special meanings for A: and B: as command line targets
it probably isn't a good idea to use these drives especially.

- Some programmers and users have no difficulty in shifts between unix-like
and Windows pathing. Some will be familiar with how colons are used on
systems like Mac OSX. I think the only point to be made here is to consider
your target audience and all the things you can anticipate going wrong with
interoperability of all of this, (cpmtools being a set of command line
tools), and build cpmtools accordingly for the needs of you or your users,
then test what you have built with all this in mind.

5.3 Testing your build of cpmtools
----------------------------------

To test what you have built I suggest you start with cpmls and cpmcp and an
apple disk image or equivalent.

John Elliot said "If you have appropriate rights, the CPMTOOLS should be able
to access the floppy drive by using "A:" or "B:" as the name of the disc
image.". I say don't bother mucking with your physical disk drive unless you
have a physical CP/M disk of a format supported by cpmtools safely in the
drive.

Get an apple CP/M disk image and use it for testing is what I suggest. The
following examples assume you have an Apple II DOS 3.3 order disk image
called EXMPLCPM.dsk for testing.

To list the files:

cpmls -f apple-do EXMPLCPM.dsk

The following example shows how to copy a file from an Apple II DOS 3.3 order
cpm disk image to the current directory:

cpmcp -f apple-do EXMPLCPM.dsk bhead.c 0:bhead.c

The following example shows how to copy a file to an Apple II DOS 3.3 order
cpm disk image from the current directory:

cpmcp -f apple-do EXMPLCPM.dsk 0:bhead.c bhead.c

To test the other utilities in cpmtools like cpmrm, cpmchattr, cpmchmod,
fsck.cpm and fsed.cpm, review the appropriate manpages for usage.

Those are simple tests as well using an apple-do format disk image. For
mkfs.cpm I will leave it to those more capable than I to decide what to do
there. Compared to them I am merely dangerous.

Acknowledgements and Stuff
--------------------------

Michael Haardt - for cpmtools in the first place and for his tireless and
ongoing efforts in supporting cpmtools in the second.

John Elliot - for bringing cpmtools to Windows.

My focus is on Windows XP (and other Windows) users and making this available
to them. At this point in time my focus is also on Apple II Z80 Softcard
users. Thankfully Michael Haardt has considered Apple II disk images in
cpmtools. My focus is also on the Aztec C Z80 MS-DOS cross-compiler which
creates Apple II CP/M programs in Windows XP.

Between Michael and John, with cpmtools I can now easily get these onto an
Apple disk image and transfer the disk image over to my real Apple II which
has a Z80 softcard clone using my Microdrive with a CF card and make a real
CP/M disk from the image with DISKMAKER.8 or DSK2FILE then run my Aztec C
CP/M programs using the real thing. I can also use the emulator that came
with Apple II Oasis to run the disk image.

Apparently nothing is missing from cpmtools for Windows XP that is available
on cpmtools for unix-like systems and I am thankful for that. Hopefully you
will be too.

I would also like to acknowledge the following individuals from the
comp.os.cpm and apple2.sys usenet newsgroups who gave their experience,
thoughts and encouragement during my adventure with all of this and in no
particular order:

David Schmidt - for cygwin feedback.
Udo Munk - for cygwin feedback. 
Peter Dassow - for cygwin feedback.
Stevo Tarkin - for msys feedback.
Volker Pohlers - for msys and pdcurses feedback.
Rolf Harmann - for linux feedback.
Richard Brady - who may or may not know watfor:) 

If I missed anyone, I thank them too. I am somewhat new to some of this and
needed all the help I received. cygwin is now my friend.

Bill Buckels
bbuckels@mts.net
November 2008