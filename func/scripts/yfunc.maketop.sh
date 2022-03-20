#!/bin/bash
if [ -z "${__yfunc_maketop}" ]
then
	export __yfunc_maketop=1

	function maketop {
		YesFSdir=$1
		TMPTOP="/tmp"
		YTMPDIR="${TMPTOP}/${YesFSdir##*/}.$$.dir"
		HASHES="${YesFSdir}/.hash"
		CHUNKLOG="${YesFSdir}/.chunklog"
		if [ ! -d "${YTMPDIR}" ]
		then
			mkdir -p ${YTMPDIR}
			chmod 777 ${YTMPDIR}
		fi
		if [ ! -d "${HASHES}" ]
		then
			mkdir -p ${HASHES}
			chmod 777 ${HASHES}
		fi
		if [ ! -d "${CHUNKLOG}" ]
		then
			mkdir -p ${CHUNKLOG}
			chmod 777 ${CHUNKLOG}
		fi
		
		export TMPTOP YTMPDIR HASHES CHUNKLOG
	}
	export maketop
fi # if [-z "${__yfunc_maketop}" ]
