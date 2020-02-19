#!/bin/bash
# given filename on the command line, echo the form of the file that 
# actually can be opened.  this needs to do filesystem case shenanigans
#
# we don't handle files with embedded spaces, a horrible idea anyway
#
search=/tmp/cn.search.$$
all=/tmp/cn.all.$$
in=/tmp/cn.in.$$

function cleanup {
	rm -f $all $search $in
}

trap cleanup EXIT
cleanup

if [ $# -lt 1 ] ; then
	exit 0
fi

#
# normalize to lower case all input file names
#

for infn in $* ; do
	dirn=$(dirname $infn)
	df=
	for dl in ${dirs[@]} ; do
		if [ $dl == $dirn ] ; then
			df=$dl
			break;
		fi
	done
	if [ -z $df ] ; then
		dirs+=( $dirn )
	fi
	echo -n $dirn/ >> $in
	basename $infn | tr '[A-Z]' '[a-z]' >> $in
done

sort -u $in > $search
#echo search: 
#cat $search

here=$(pwd)

#
# build join list of file names and lower case forms
#
rm -f $in
for dn in ${dirs[@]} ; do
	cd $here
	cd $dn
	for i in * ; do
		echo $dn/$(echo "$i" | tr '[A-Z]' '[a-z]')",$dn/$i" >> $in
	done
done
sort $in > $all

join -t, -o 1.2 $all $search | sort -u > $in
if [ $(wc -l < $in) -gt 0 ] ; then
	cat $in
	exit 0
fi

echo nofile
exit 2
