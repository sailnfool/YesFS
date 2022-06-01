#!/bin/bash
########################################################################
# Author: Robert E. Novak
# email: sailnfool@gmail.com
# Copyright (C) 2022 Sea2Cloud Storage, Inc. All Rights Reserved
# Modesto, CA 95356
#
# Extract the number of leading characters from the hashname which
# constitute the "flexhash" row number.  This can be variable
# depending on the size of hte file system.
#
########################################################################
#_____________________________________________________________________
# Rev.|Auth.| Date     | Notes
#_____________________________________________________________________
# 1.0 | REN |06/01/2022| original version
#_____________________________________________________________________
#

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
		YesFSdir="$2"

		maketop "${YesFSdir}"

    ##################################################################
    ##################################################################
		dir=${hashid:${hashoffset}:${flexdirchars}}
		if [ -z "${dir}" ]
		then
			errecho "Empty directory - bad hash?"
			exit -1
		fi
		dirpath=${YesFS_HASHES}/${dir}
		mkdir -p ${dirpath}
		echo "${dirpath}"
	}
	export hashdirpath
fi # if [-z "${__yfunc_hashdirpath}" ]
