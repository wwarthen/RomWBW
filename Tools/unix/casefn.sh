#!/bin/bash
# given a filename on the command line, echo the form of the file that 
# actually can be opened.  this needs to do filesystem case shenanigans
#
n=0
for infn in $* ; do
	dir=$(dirname $infn)
	lowname=$(basename $infn | tr '[A-Z]' '[a-z]')
	cd $dir
	for i in * ; do
		cand=$(basename ./"$i" | tr '[A-Z]' '[a-z]')
		if [ ./"$cand" = ./$lowname ] ; then
			echo -n "$dir/$i "
			((n++))
		fi
	done
done
if [ $n == 0 ] ; then
	echo "nofile"
else
	echo
fi
