#!/bin/bash
if [ -z "${__yfunc_put_firstbackref}" ]
then
	source yfunc.global
	source func.errecho
	source func.insufficient
	export __func_put_firstbackref=1

	function put_firstbackref {
		[ $# -lt 1 ] && insufficient 1 $@
		nhid="$1"

		####################
		# Create the initial backreference chunk for the manifest
		# that we are building.  Since it is the initial one, there
		# is no PREVIOUS and no NEXT backreferences.
		####################
		chunk_back[0]=echo -e "${HASHTYPE}\t${SUFFIX[BACK]}"
		chunk_back[1]=echo -e "${PREVIOUS}\t0"
		chunk_back[2]=echo -e "${NEXT}\t\\0"
		chunk_back[3]=echo -e "${NAMEHASH}\t${nhid}"
		chunk_back[4]=echo -e "${BACKTIME}\t${timestamp}"
		chunk_back[5]=echo -e "${SPEC}\tTRUE"

		for i in $(seq 0 5)
		do
			echo ${chunk_back[$i]} >> ${TMPDIR}/tempback.BACK
		done
		hashline=$(b2sum ${TMPDIR}/tempback.BACK)
		bhid=${hashline:0:128}
		p_bhid="$(hashdirpath ${bhid})"
		f_bhid="${p_bhid}/${bhid}.BACK"
		if [ -f "${f_bhid}" ]
		then
			stderrecho "Duplicate Backreference ${bhid}"
		fi
		mv ${TMPDIR}/tempback.BACK "${f_bhid}"
		echo "${bhid}\t$SUFFIX[BHID]}\t${HASHCODE}\t${timestamp}" \
			>> ${CHUNKLOG}

		####################
		# This is where we put the code for the global put
		####################
		echo "${bhid}"
	}
	export put_firstbackref
fi # if [-z "${__yfunc_put_firstbackref}" ]
