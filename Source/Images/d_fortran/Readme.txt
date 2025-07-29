===== Microsoft Fortran-80 Compiler v.3.44 =====

This is Microsoft's implementation of the FORTRAN scientific-oriented high level
programming language. It was one of their early core languages developed for the
8-bit computers and later brought to the 8086 and IBM PC. In 1993 Microsoft
rebranded the product as Microsoft Fortran Powerstation. (Note: -80 refers to
the 8080/Z80 platform, not the language specification version)

The user manual is available in the Doc/Language directory,
Microsoft_FORTRAN-80_Users_Manual_1977.pdf

== Sample Application ==

This disk image includes a very small sample application called
HELLO.FOR that can be used to demonstrate the build process.  The
following commands will build this sample application.

f80 hello,hello=hello
l80 hello,forlib/s,hello/n,/e:hellow
