#!/bin/bash
if [ -z "${__yfunc_hashdirpath}" ]
then
	source yfunc.maketop
	source func.errecho
	source func.insufficient
	export __yfunc_hashdirpath=1

	function hashdirpath {
		[ "$#" -lt 2 ] && insufficient 2 $@
		hashid="$1"
		yesfsdir="$2"

		maketop "$2"
		dir=${hashid:0:2}
		subdir=${hashid:2:2}
		dirpath=${HASHES}/${dir}/${subdir}
		if [ -z "${dirpath}" ]
		then
			errecho "Empty directory"
			exit -1
		fi
		mkdir -p ${dirpath}
		echo "${dirpath}"
	}
	export hashdirpath
fi # if [-z "${__yfunc_hashdirpath}" ]
