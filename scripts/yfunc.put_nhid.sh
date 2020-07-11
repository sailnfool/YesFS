#!/bin/bash
if [ -z "${__yfunc_put_nhid}" ]
then
	source yfunc.global
	source func.errecho
	source func.insufficient
	export __func_put_nhid=1

	function put_nhid {
		[ $# -lt 2 ] && insufficient 2 $@
		filename="$1"
		yesfsdir="$2"
		
		nhidhash="$(echo "${filename}" | b2sum)"
		nhid=${nhidhash:0:128}
		p_nhid=hashdirpath ${nhid}

		if [ -r "${p_nhid}/${nhid}.${SUFFIX[NHID]}" ]
		then
			stderrecho "Duplicate Backreference ${bhid}"
		fi
		echo "${filename}" > "${p_nhid}/${nhid}.${SUFFIX[NHID]}"

		echo "${nhid}\t$SUFFIX[NHID]}\t${HASHCODE}\t${timestamp}" \
			>> ${CHUNKLOG}

		####################
		# This is where we put the code for the global put
		####################
		echo "${nhid}"
	}
	export put_nhid
fi # if [-z "${__yfunc_put_nhid}" ]
