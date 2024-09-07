***********************************************************************
***                                                                 ***
***                          R o m W B W                            ***
***                                                                 ***
***                    Z80/Z180 System Software                     ***
***                                                                 ***
***********************************************************************

This document describes the process to build the custom documentation
for RomWBW.  The RomWBW documentation is not normally built as part of
the full build process.  This is because it requires external tools
to be installed.

All source documents are first pre-processed with gpp to allow use of
some global variable expansions.  Pandoc is then used to generate a
variety of output formats.  The most significant of these are the PDF
documents.  Pandoc invokes a Latex-type processor (LuaTeX) to
produce the final PDF documents.

Required for Windows:
 - Pandoc (https://pandoc.org/)
 - MiKTeX (https://miktex.org/)
   - Install Roboto font from MiKTeX Console

Required for Ubuntu Linux:
 - gpp (apt install gpp)
 - Pandoc (apt install pandoc)
 - TexLive (apt install texlive texlive-luatex texlive-fonts-extra)

Required for MacOS:
 - gpp (brew install gpp)
 - pandoc (brew install pandoc)
 - TexLive (brew install texlive)
 - Roboto Font (brew install --cask font-roboto)

The source directory for the documentation is /Source/Doc. From this 
directory run "Build.cmd" on Windows or "make" on Linux/Mac to create
the output documents.  This will create the final documents and copy
them to their destination directories.