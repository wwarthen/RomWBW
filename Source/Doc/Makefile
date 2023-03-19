#
# NOTE: Pandoc, Latex (MiKTeX or TexLive), and gpp must be installed
# and available on commandline for this build to work!!!
# Typically "sudo apt install pandoc, texlive-latex-extra, gpp"
#
OBJECTS = ReadMe.gfm ReadMe.txt UserGuide.pdf SystemGuide.pdf Applications.pdf ROM_Applications.pdf Catalog.pdf Errata.pdf
# DEST = ../../Doc
TOOLS = ../../Tools
OTHERS = *.tmp

include $(TOOLS)/Makefile.inc

all :: deploy

%.tmp : %.md
	gpp -o $@ -U "$$" "$$" "{" "}{" "}$$" "{" "}" "@@@" "" -M "$$" "$$" "{" "}{" "}$$" "{" "}" $<

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
	cp ReadMe.gfm            "../../ReadMe.md"
	cp ReadMe.txt            "../../ReadMe.txt"
	cp UserGuide.pdf         "../../Doc/RomWBW User Guide.pdf"
	cp SystemGuide.pdf       "../../Doc/RomWBW System Guide.pdf"
	cp Applications.pdf      "../../Doc/RomWBW Applications.pdf"
	cp ROM_Applications.pdf  "../../Doc/RomWBW ROM Applications.pdf"
	cp Catalog.pdf           "../../Doc/RomWBW Disk Catalog.pdf"
	cp Errata.pdf             "../../Doc/RomWBW Errata.pdf"
