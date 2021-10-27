#
# NOTE: Pandoc, Latex (MiKTeX or TexLive), and gpp must be installed
# and available on commandline for this build to work!!!
# Typically "sudo apt install pandoc, texlive-latex-extra, gpp"
#
OBJECTS = GettingStarted.pdf GettingStarted.gfm GettingStarted.txt Applications.pdf Architecture.pdf Catalog.pdf ROM_Applications.pdf 
# DEST = ../../Doc
TOOLS = ../../Tools
OTHERS = *.tmp

include $(TOOLS)/Makefile.inc

all :: deploy

%.tmp : %.md
	gpp -o $@ -U "$" "$" "{" "}{" "}$" "{" "}" "@@@" "" -M "$" "$" "{" "}{" "}$" "{" "}" $<

%.pdf : %.tmp
	pandoc $< -f markdown -t latex -s -o $@ --default-image-extension=pdf

%.html : %.tmp
	pandoc $< -f markdown -t html -s -o $@ --default-image-extension=pdf

%.dw : %.tmp
	pandoc $< -f markdown -t dokuwiki -s -o $@ --default-image-extension=pdf

%.gfm : %.tmp
	pandoc $< -f markdown -t gfm -s -o $@ --default-image-extension=pdf

%.txt : %.tmp
	pandoc $< -f markdown -t plain -s -o $@ --default-image-extension=pdf

deploy :
	cp GettingStarted.pdf   "../../Doc/RomWBW Getting Started.pdf"
	cp GettingStarted.gfm   "../../ReadMe.md"
	cp GettingStarted.txt   "../../ReadMe.txt"
	cp Applications.pdf     "../../Doc/RomWBW Applications.pdf"
	cp Architecture.pdf     "../../Doc/RomWBW Architecture.pdf"
	cp Catalog.pdf          "../../Doc/RomWBW Disk Catalog.pdf"
	cp ROM_Applications.pdf "../../Doc/ROM Applications.pdf"
