#!/bin/bash
scriptname=${0##*/}
########################################################################
#copyright      :(C) 2022
#copyrightholder:Robert E. Novak  All Rights Reserved
#location       :Modesto, CA 95356 USA
########################################################################
#scriptname00   :yfunc.global
#description00  :global definitions of YesFS information and
#description02  :directories
#args00         :N/A
#author         :Robert E. Novak
#authorinitials :REN
#email          :sailnfool@gmail.com
#license        :CC by Sea2Cloud Storage, Inc.
#licensesource  :https://creativecommons.org/licenses/by/4.0/legalcode
#licensename    :Creative Commons Attribution license
#_____________________________________________________________________
# Rev.|Aut| Date     | Notes
#_____________________________________________________________________
# 1.0 |REN|08/08/2022| Initial Release
#_____________________________________________________________________
if [ -z "${__yfuncglobal}" ]
then
	export __yfuncglobal=1

	source bfunc.hex2dec

	################################################################
	# Define the top level YesFS directory.
	# sometimes the NFS mount of the top level directory fails so
	# we make a copy in /tmp for disconnected usage
	################################################################
	export YesFSdir=${HOME}/Dropbox/YesFS
	export tmpYesFSdir=/tmp/YesFS

	if [[ -d "${tmpYesFSdir}" && -d "${YesFSdir}" ]] ; then

		########################################################
		# if we are connected and have a tmp, then rsync it
		# back to the NFS mounted copy, then destroy the /tmp
		# copy
		########################################################
		rsync "${tmpYesFSdir}" "${YesFSdir}"
		rm -rf "${tmpYesFSdir}"
	fi

	################################################################
	# if the NFS mounted copy is not available put everything in
	# /tmp
	################################################################
	if [[ ! -d "${YesFSdir}" ]] ; then
		export YesFSdir=/tmp/YesFS
	fi
	export YesFSdiretc=${YesFSdir}/etc

	export YesFSdirhash=${YesFSdir}/.hash
	export YesFS_CHUNKLOG=${YesFSdir}/.chunklog

	export YesFS_FILECOUNT_lock="${YesFSdir}/FILECOUNT.lock"
	export YesFS_FILECOUNT_file="${YesFSdir}/FILECOUNT.file"

	mkdir -p ${YesFSdiretc}

	YesFShashdirchars=$(cat ${YesFSdir}/etc/dirchars.txt)
	xx=${YesFShashdirchars}
	YesFSflexhashrows=$(bfunc_hex2dec $(printf "%${xx}c" "F"))
fi # if [ -z "${__yfuncglobal}" ]
