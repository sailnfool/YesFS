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
		timestamp="$3"
		CHUNKLOG="$4"
		
		nhidhash="$(echo "${filename}" | b2sum)"
		nhid=${nhidhash:0:128}
		p_nhid=hashdirpath ${nhid}
		f_nhid="${p_nhid}/${nhid}"

		if [ -r "${f_nhid}.${SUFFIX[CHID]}" ]
		then
			stderrecho "Duplicate Backreference ${bhid}"
		fi
		echo "${filename}" > "${f_nhid}.${SUFFIX[CHID]}"

		echo -e "${nhid}\t$SUFFIX[CHID]}\t${HASHCODE}\t${timestamp}" \
			>> ${CHUNKLOG}
		backref[0]="HASHTYPE\tBACK"
		backref[1]="PREVIOUS\t0"
		backref[2]="NEXT\t0"
		backref[3]="NAMEHASH\t${nhid}"
		backref[4]="BACKTIME\t${timestamp}"
		backref[5]="SPEC\tTRUE"
		tmpback=${TMPDIR}.${filename}.BACK
		rm -f ${tmpback}
		for i in $(seq 0 5)
		do
			echo -e ${backref[$i}]} >> ${tmpback}
		done
		bhid=$(b2sum ${tmpback})
		p_bhid=hashdirpath ${bhid}
		f_bhid="${p_bhid}/${bhid}"
		mv ${tmpback} ${f_bhid}
		echo "${bhid}\t$SUFFIX[BACK]}\t${HASHCODE}\t${timestamp}" \
			>> ${CHUNKLOG}

		####################
		# This is where we put the code for the global put
		####################
		echo "${nhid}"
	}
	export put_nhid
fi # if [-z "${__yfunc_put_nhid}" ]
