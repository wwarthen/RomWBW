#
# NOTE: gpp, Pandoc, LuaLatex (MiKTeX or TexLive), and Roboto Font must be installed
# and available on commandline for this build to work!!!
#
# On MacOS:
# brew install gpp pandoc texlive
# brew install --cask font-roboto
#
# On Ubuntu Linux:
# apt install gpp pandoc texlive texlive-luatex texlive-fonts-extra
#
OBJECTS = ReadMe.gfm ReadMe.txt UserGuide.pdf SystemGuide.pdf Applications.pdf Catalog.pdf Errata.pdf
# DEST = ../../Doc
TOOLS = ../../Tools
OTHERS = *.tmp

include $(TOOLS)/Makefile.inc

all :: deploy

%.tmp : %.md
	gpp -o $@ -U "$$" "$$" "{" "}{" "}$$" "{" "}" "@@@" "" -M "$$" "$$" "{" "}{" "}$$" "{" "}" $<

%.pdf : %.tmp
	pandoc $< -f markdown -t pdf -s -o $@ --default-image-extension=pdf --pdf-engine=lualatex

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
	cp Catalog.pdf           "../../Doc/RomWBW Disk Catalog.pdf"
	cp Errata.pdf            "../../Doc/RomWBW Errata.pdf"
