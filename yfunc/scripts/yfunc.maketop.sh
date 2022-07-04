#!/bin/bash
########################################################################
# Author: Robert E. Novak
# email: sailnfool@gmail.com
# Copyright (C) 2022 Sea2Cloud Storage, Inc. All Rights Reserved
# Modesto, CA 95356
#
# Create the top level directories used by the YesFS filesystem.
# There are two directories,
# 1) the .hash directory YesFS_HASHES which contains all of the objects 
#    (files, directories, manifests, etc.
# 2) the .chunklog YesFS_CHUNKLOG that contains a trail of every 
#    chunk created.
########################################################################
#_____________________________________________________________________
# Rev.|Aut| Date     | Notes
#_____________________________________________________________________
# 1.1 |REN|06/12/2022| Used modern test
# 1.0 |REN|06/01/2022| original version
#_____________________________________________________________________
#

if [ -z "${__yfunc_maketop}" ]
then
	export __yfunc_maketop=1
  source func.errecho

	function yfunc_maketop {
    if [[ ! -d "$1" ]]
    then
      errecho "maketop passed a non-directory parameter"
      exit 1
    fi
    YesFSdir=realpath("$1")
		YesFS_HASHES="${YesFSdir}/.hash"
		YesFS_CHUNKLOG="${YesFSdir}/.chunklog"
		if [[ ! -d "${YesFS_HASHES}" ]]
		then
			mkdir -p ${YesFS_HASHES}
			chmod 777 ${YesFS_HASHES}
		fi
		if [[ ! -d "${YesFS_CHUNKLOG}" ]]
		then
			mkdir -p ${YesFS_CHUNKLOG}
			chmod 777 ${YesFS_CHUNKLOG}
		fi
		
		export YesFSdir YesFS_HASHES YesFS_CHUNKLOG
	}
	export yfunc_maketop
fi # if [-z "${__yfunc_maketop}" ]
