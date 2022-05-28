#!/bin/bash
if [ -z "${__yfunc_hashdirpath}" ]
then
  source yfunc.global
	source yfunc.maketop
	source func.errecho
	source func.insufficient
	export __yfunc_hashdirpath=1

	function hashdirpath {
		[ "$#" -lt 2 ] && insufficient 2 $@
		hashid="$1"
		yesfsdir="$2"

		maketop "$2"
		dir=${hashid:${hashoffset}:${flexdirchars}}
		dirpath=${HASHES}/${dir}
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
