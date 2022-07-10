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
# Rev.|Aut| Date     | Notes
#_____________________________________________________________________
# 1.0 |REN|06/01/2022| original version
#_____________________________________________________________________
#

if [[ -z "${__yfunc_hashdirpath}" ]]
then
  source yfunc.global
	source yfunc.maketop
	source func.errecho
	source func.insufficient
	export __yfunc_hashdirpath=1

	function yfunc_hashdirpath {

    local hashid
    local YesFSdir
    local dirpath

		[[ "$#" -lt 2 ]] && insufficient 2 $@
    if [[ ! "$1" =~ ${re_cryptohash} ]]
    then
      errecho -e "First argument is an invalid cryptohash"
      exit 1
    fi
		hashid="$1"
    if [[ ! -d "$2" ]]
      errecho -e "Second argument is not a directory"
      exit 2
    fi
		YesFSdir="$2"

		maketop "${YesFSdir}"

    ####################################################################
    # hashoffset defined in yfunc.global
    # flexdirchars defined in yfunc.global`
    ####################################################################
		dir=${hashid:${hashoffset}:${flexdirchars}}

    ####################################################################
    # This should never happen due to the inbound testing.
    ####################################################################
		if [[ -z "${dir}" ]]
		then
			errecho "Empty directory - bad hash?"
			exit -1
		fi
		dirpath=${YesFSdir}/.hashes/${dir}
		mkdir -p ${dirpath}
		echo "${dirpath}"
	}
	export yfunc_hashdirpath
fi # if [-z "${__yfunc_hashdirpath}" ]
