#!/bin/bash
# given a filename on the command line, echo the form of the file that 
# actually can be opened.  this needs to do filesystem case shenanigans
#
for infn in $* ; do
	dir=$(dirname $infn)
	lowname=$(basename $infn | tr '[A-Z]' '[a-z]')
	cd $dir
	for i in * ; do
		cand=$(basename ./"$i" | tr '[A-Z]' '[a-z]')
		if [ ./"$cand" = ./$lowname ] ; then
			echo -n "$dir/$i "
		fi
	done
done
echo
