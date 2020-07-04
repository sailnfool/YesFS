#!/bin/bash
HASHES=/hashes
HASHCNT=0
TMPDIR=/tmp/${HASHES}.$$.dir
re_hexnumber='^[0-9a-f][0-9a-f]*$'
if [-z "${__func_writehash}" ]
then
	export __func_hashdirpath=1

	function hashdirpath {
		hashid=$1

		dir=${hashid:0:2}
		subdir=${hashid:2:2}
		dirpath=${HASHES}/${dir}/${subdir}
		mkdir -p ${dirpath}
		echo ${dirpath}
	}
	export hashdirpath
fi # if [-z "${__func_writehash}" ]

mkdir -p ${TMPDIR}
if [ ! -d ${HASHES} ]
then
	sudo mkdir -p ${HASHES}
	sudo chmod 777 ${HASHES}
fi
if [ $# -lt 1 ]
then
	echo $LINENO working on "$1"
	exit 0
fi
DIRLIST=${TMPDIR}/directories
if [ ! -d "$1" ]
then
	echo "Not a directory $1"
	exit 0
fi
find "$1" -type d -a \( -name hashes -o -name tmp \) -prune \
	-o -type d -print  > ${DIRLIST}
cat ${DIRLIST}
ls -l ${DIRLIST}
wc -l ${DIRLIST}
# split -C 2048 ${DIRLIST} ${TMPDIR}/dirfile
# ls -l ${TMPDIR}/dirfile*
# wc -l ${TMPDIR}/dirfile*

manifest[1]="ACCESS\t%a\n"
manifest[2]="DEVICE\t%D\n"
manifest[3]="FILETYPE\t%F\n"
manifest[4]="GID\t%g\n"
manifest[5]="GNAME\t%G\n"
manifest[6]="BYTESIZE\t%s\n"
manifest[7]="UID\t%u\n"
manifest[8]="UNAME\t%U\n"
manifest[9]="LASTACCESS\t%x\n"
manifest[10]="LASTMODIFIED\t%y\n"
manifest[11]="LASTCHANGE\t%z\n"
manifestfmt=""
for i in $(seq 1 11)
do
	Manifeststring="${manifestfmt}${manifest[$i]}"
done

declare -A allhashes
echo $(date '+%T')
while read -r dirname
do
	#find "$dirname" -maxdepth 1 -type f  > ${TMPDIR}/thislist
	# ls -l ${TMPDIR}/thislist
	# echo "Number of Files in ${dirname} is $(wc -l ${TMPDIR}/thislist)"
	if [ ! -d "$dirname" ]
	then
		echo "${0##*/} $LINENO dirname=${dirname} is not a directory"
		exit -1
	fi
	b2sum "$dirname"/* 2> /dev/null >/${TMPDIR}/thislist
	# cat ${TMPDIR}/thislist
	while read -r hashline
	do
		if [ "${hashline:0:5}" == "Failed" ]
		then
			continue
		fi
		chid=${hashline:0:127}
		filename=${hashline:130}
		allhashes[$hashonly]="$filename"
		if [ ! -f "${filename}" ]
		then
			echo "filename=${filename} is not a file"
			exit 0
		fi
		((HASHCNT++))
		# b2hash=$(b2sum "${filename}" 2>/dev/null)
		# echo "b2hash of ${filename}=${b2hash}"
		# hashonly=$(echo ${b2hash} | cut -d ' ' -f 1)

		namehash=$(echo ${filename} | b2sum)
		nhid=${namehash:0:127}
		p_nhid=$(hashdirpath ${nhid})
		mnid=${nhid}.MANIFEST
		manid=${p_nhid}/${mnid}
		fullnhid=${p_nhid}/${nhid}.NHID
		if [ -r ${fullnhid} ]
		then
			prevmnidhash=$(b2sum ${manid})
			prevmnid=${prevmnidhash:0:127}
			p_mnid=$(hashdirpath ${prevmnid})
			pmanid=${p_mnid}/${prevmnid}

			mv ${manid} ${pmanid}
			echo -e "PREVMANIFEST\t${prevmnid}" >${manid}
		else
			echo -e "PREVMANIVFEST\t0" > ${manid}
		fi
		stat --print="${manifestfmt}" "${filename}" >> ${manid}

		echo -e "CHID\t${chid}\n" >> ${p_nhid}/${nhid}.NHID
		echo -e "NAME\t${filename}" >> ${p_nhid}/${nhid}.NHID

		p_chid=$(hashdirpath ${chid})
		mkdir -p ${chidhashdir}
		echo -e "NAME\t${filename}" >> ${p_chid}/${chid}.CHID


		[ $(expr ${HASHCNT} % 100) -eq 0 ] && echo -n "."
		[ $(expr ${HASHCNT} % 7000) -eq 0 ] && { \
			echo ""; echo "$(date '+%T') ${HASHCNT}"
		}
	done < ${TMPDIR}/thislist
	wait
done  < ${DIRLIST}
