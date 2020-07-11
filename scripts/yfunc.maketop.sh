#!/bin/bash
if [ -z "${__yfunc_maketop}" ]
then
	export __yfunc_maketop=1

	function maketop {
		yesfsdir=$1
		TMPTOP="/tmp"
		YTMPDIR="${TMPTOP}/${yesfsdir##*/}.$$.dir"
		HASHES="${yesfsdir}/.hash"
		CHUNKLOG="${yesfsdir}/.chunklog"
		if [ ! -d "${YTMPDIR}" ]
		then
			sudo mkdir -p ${YTMPDIR}
			sudo chmod 777 ${YTMPDIR}
		fi
		if [ ! -d "${HASHES}" ]
		then
			sudo mkdir -p ${HASHES}
			sudo chmod 777 ${HASHES}
		fi
		if [ ! -d "${CHUNKLOG}" ]
		then
			sudo mkdir -p ${CHUNKLOG}
			sudo chmod 777 ${CHUNKLOG}
		fi
		
		export TMPTOP YTMPDIR HASHES CHUNKLOG
	}
	export maketop
fi # if [-z "${__yfunc_maketop}" ]
