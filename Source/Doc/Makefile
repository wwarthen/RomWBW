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
OBJECTS = Introduction.gfm Introduction.txt Introduction.pdf UserGuide.pdf SystemGuide.pdf Applications.pdf Catalog.pdf Hardware.pdf
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
	pandoc $< -f markdown -t gfm-yaml_metadata_block -s -o $@ --default-image-extension=svg

%.txt : %.tmp
	pandoc $< -f markdown -t plain -s -o $@ --default-image-extension=pdf

deploy : deploy_mkdocs
	cp Introduction.gfm      "../../ReadMe.md"
	cp Introduction.txt      "../../ReadMe.txt"
	cp Introduction.pdf      "../../Doc/RomWBW Introduction.pdf"
	cp UserGuide.pdf         "../../Doc/RomWBW User Guide.pdf"
	cp SystemGuide.pdf       "../../Doc/RomWBW System Guide.pdf"
	cp Applications.pdf      "../../Doc/RomWBW Applications.pdf"
	cp Catalog.pdf           "../../Doc/RomWBW Disk Catalog.pdf"
	cp Hardware.pdf          "../../Doc/RomWBW Hardware.pdf"

deploy_mkdocs : Introduction.gfm UserGuide.gfm SystemGuide.gfm Applications.gfm Catalog.gfm Hardware.gfm ReadMe.gfm
	rm -rf mkdocs
	mkdir -p mkdocs/UserGuide/Graphics mkdocs/SystemGuide/Graphics
	cp Introduction.gfm      mkdocs/Introduction.md
	cp UserGuide.gfm         mkdocs/UserGuide.md
	cp SystemGuide.gfm       mkdocs/SystemGuide.md
	cp Applications.gfm      mkdocs/Applications.md
	cp Catalog.gfm           mkdocs/Catalog.md
	cp Hardware.gfm          mkdocs/Hardware.md
	cp ReadMe.gfm            mkdocs/README.md
	cp Graphics/*.svg        mkdocs/UserGuide/Graphics
	cp Graphics/*.svg        mkdocs/SystemGuide/Graphics
