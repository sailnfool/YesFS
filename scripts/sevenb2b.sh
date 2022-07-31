#!/bin/bash
source yfunc.global
source yfunc.hashdirpath
source yfunc.maketop
source yfunc.put_nhid
source func.errecho
USAGE="${0##*/} [-h] [-d] <directory> [ <rootpath> ]\n
\t<directory>\tThe directory that will be converted to a YesFS\n
\t\t\tfile system prototype using b2sum cryptographic hash.\n
\t<rootpath>\tThe directory where the YesFS file system will be\n
\t\t\tplaced.  Default is /hashes. Requests SU privileges\n
\t\t\tto create.  A \"normal\" looking file tree is located\n
\t\t\tat <rootpath>.  The contents of the filenames in this\n
\t\t\tdirectory tree will be the Name Hash ID (NHID) of the\n
\t\t\tnamed file.  This is only for the convenience of\n
\t\t\tdevelopers/debuggers to browse a normal tree in the\n
\t\t\tlocal file system.  The local file system will place the\n
\t\t\thash files in <rootpath>/.hash.  Using the PUT and\n
\t\t\tGET commands and library functions will allow the\n
\t\t\tretrieval of the file contents and/or metadata.\n
\n\t~!~!~!~!~!~! WARNING ~!~!~!~!~!~!\n
\tSTILL UNDER DEVELOPMENT - MAY BE BROKEN\n\n
\t-h\t\tPrint this help information.\n
\t-d\t\tPrint diagnostic information\n
\t\t\t(dump manifests as created).\n
\t-v\t\tPrints a '.' for every 100 files processed.\n
\t\t\tDefault is on.\n
\t\t\tToggles the default.  Prints a timestamp\n
\t\t\tevery 7000 files.\n
"

optionargs="hdv"
NUMARGS=1
debug=0
verbose=1
yesfsdir=/hashes
FILECOUNT=0
re_hexnumber='^[0-9a-f][0-9a-f]*$'

while getopts ${optionargs} name
do
	case ${name} in
	h)
		echo -e ${USAGE}
		exit 0
		;;
	d)
		debug=1
		;;
	v)
		if [ ${verbose} -eq 1 ]
		then
			verbose=0
		fi
		;;
	\?)
		echo "${0##*/}: invalid option: -${OPTARG}"
		echo -e "${USAGE}"
		exit 0
		;;
	esac
done
shift "$(($OPTIND - 1))"
[ $# -lt $NUMARGS ] && { echo -e ${USAGE}; exit -1; }

topdir="$1"
yesfsdir="$2"


if [ ! -d "${topdir}" ]
then
	stderrecho "Not a directory ${topdir}"
	exit 0
fi

maketop "${yesfsdir}"

[ ${verbose} -eq 1 ] && echo $(date '+%T')

b2sum "$dirname"/* 2> /dev/null >/${TMPDIR}/thislist

while read -r hashline
do
	####################
	# A line beginning with "Failed" is a directory or
	# other special file.  Ignore
	####################
	if [ "${hashline:0:${#FAILEDTO_HASH_string}}" == "${FAILEDTO_HASH_string}" ]
	then
		####################
		# Not sure why this is two steps, but it works.
		####################
		dirstring="${hashline:${#FAILEDTO_HASH_string}}"
		subdirname="${dirstring:0:${#dirstring}-1}"
		
		####################
		# Recursively descend.
		# Later, this can be made a background process.
		####################
		sevenb2b "${dirname}/${subdirname}" "$2"
	fi

	filename=${hashline:130}
	if [ ! -f "${filename}" ]
	then
		echo "filename=${filename} is not a file"
		exit 0
	fi

	####################	
	# nhid   is the name hash ID of the file: NHID Daka $nhid
	# p_nhid represents the directory path in the local file
	#        system where we will place the NHID object.
	# f_nhid is the full path ${p_nhid}/${nhid}
	#
	# Note that for the moment we are "punting" on the notion of
	# creating directories that make up the "$(dirname ${filename})"
	# In order to do this properly, we not only have to insure that
	# the objects exist in the full path, but add appropriate sub
	# directories and at the last element add the filename as a
	# member of the leaf/edge directory.
	####################	
	nhid=$(put_nhid "${filename}" "${yesfsdir}" "${timestamp}" \
	    "${CHUNKLOG}")


	((FILECOUNT++))
	p_nhid=$(hashdirpath ${nhid})
	f_nhid="${p_nhid}/${nhid}"
	((FILECOUNT++))

	####################	
	# Get the content hash ID of the file: CHID
	# and the filename
	####################	
	chid=${hashline:0:128}
	p_chid=$(hashdirpath ${chid})
	f_chid="${p_chid}/${chid}"

	bhid=$(put_firstbackref ${nhid})
	if [ -f "${f_chid}" ]
	then
		previous_chid=""
	fi
	####################	
	# This next step should be the process that breaks
	# the file into multiple chunks and ties each of those
	# chunks back to the nhid as they are created, building
	# the basis for the chunk list that is at the end of
	# the manifest for the object.  For now we simplify
	# by turning the object into a single chunk.
	####################
	chunk_mani[0]=echo -e "${HASHTYPE}\t${SUFFIX[MANI]}"
	chunk_mani[1]=echo -e "${PREVIOUS}\t0"
	chunk_mani[2]=echo -e "${BACKREF}\t${bhid}"

	
	CHUNKID="${f_chid}.CHID"
	METAID="${f_chid}.METACHUNK"
	METAACCESSID="${f_chid}.METACHUNKACCESS"
	if [ -f "${CHUNKID}" ]
		echo -e "${chid}\tCHID\tB2\tACCESS\t${timestamp}" >> ${CHUNKLOG}
		if [ ! -f ${METAACCESSID} ]
		then
			stderrecho "${METAID} not found"
			exit 1
		fi
		while read metaline
		do
			ATR_string="ACCESS_TIME_RECORDS"
			if [ "${metaline:0:${#ATR_string}}" = "${ATR_string}" ]
			then
				meta_access_id="${metaline:$((${#ATR_string}+1))}"
			fi
		done < ${METAACCESSID}
		meta_accessid[0]="PREVIOUS_ACCESS_METACHUNKACCESS\t${meta_access_id}"
		meta_accessid[1]="TIME\t${timestamp}"
		meta_accessid[2]="USERID\t$(uid -u)"
		meta_accessid[3]="GROUPID\t$(uid -g)"
		
	else
		cp "${filename}" ${p_chid}/${chid}.CHID
		echo -e "${chid}\tCHID\tB2\tCREATE\t${timestamp}" >> ${CHUNKLOG}
		meta_accessid[0]="PREVIOUS_ID\t0"
		meta_accessid[1]="TIME\t${timestamp}"
		meta_accessid[2]="USERID\t$(uid -u)"
		meta_accessid[3]="GROUPID\t$(uid -g)"
	fi
	for i in { 0 3 }
	do
		echo -e ${meta_accessid[$i]} >> ${METAACESSID}
	done
	fi

	####################	
	# Create the speculative backreference that ties the
	# name to the chunk.
	####################	
	create_spec_back_ref ${chid} ${nhid}

	####################	
	# See hashdirpath to see how the directories
	# are setup as prefixes for the hash names
	# Set the Path for the NHID
	# The Manifest has the suffix .MANIFEST
	# The object containing the file name has the suffix .NHID
	####################
	p_nhid=$(hashdirpath ${nhid})
	manid=${p_nhid}/${nhid}.MANIFEST
	fullnhid=${p_nhid}/${nhid}.NHID
	ldir="${filename%/*}"
	mkdir -p "${yesfsdir}/${ldir}"
	echo "${nhid}" >> "${yesfsdir}/${filename}"

	####################
	# If the NHID already exists it means we have a prior
	# version of this name.
	####################
	if [ -r ${fullnhid} ]
	then

		####################
		# A prior NHID means a prior MANIFEST  a safety
		# check here would be a good idea.
		# Take the hash of the prior manifest.  This
		# hash will be placed in the new MANIFEST.
		# Retrieve the version number of the object
		# from the prior manifest
		####################
		prevmnidhash=$(b2sum ${manid})
		prevmnid=${prevmnidhash:0:128}
		p_mnid=$(hashdirpath ${prevmnid})
		pmanid=${p_mnid}/${prevmnid}
		prev_objid=$(awk -F'\t' '/OBJECTVERSION/{print $2}' < ${manid})
		((object_version=prev_objid + 1))
		mv ${manid} ${pmanid}
		echo -e "PREVMANIFEST\t${prevmnid}" >${manid}
	else

		####################
		# First Manifest for the object, set the 
		# PREVMANIFEST to NULL and the object version
		# to Zero
		####################
		echo -e "PREVMANIFEST\t0" > ${manid}
		object_version=0
	fi

	####################
	# Fill the Manifest.  This is currently missing the 
	# chunks for the file contents which belongs here.
	####################
	echo -e "OBJECTVERSION\t${object_version}" >> ${manid}
	echo -e "MANIFESTVERSIONMAJOR\t0" >> ${manid}
	echo -e "MANIFESTVERSIONMINOR\t1" >> ${manid}
	echo -e "NHID\t${chid}\n" >> ${manid}
	echo -e "NAME\t${filename}" >> ${manid}
	[ ${debug} -eq 1 ] && cat ${manid}

	####################
	# Create the NHID with the name and the CHID of the 
	# object contents.
	####################
	echo -e "NHID\t${chid}\n" >> ${p_nhid}/${nhid}.NHID
	echo -e "NAME\t${filename}" >> ${p_nhid}/${nhid}.NHID

	####################
	# Create a chunk ID for the content chunk that points
	# pack to the name.  This is not correct as instantiated
	# and probably should be dropped as redundant.  Multiple
	# identical files will successively wipe this out.
	# An alternate implementation would be to create a 
	# linked list like the manifests.
	####################
	p_chid=$(hashdirpath ${chid})
	echo -e "NAME\t${filename}" >> ${p_chid}/${chid}.CHID


	[[ ${verbose} -eq 1 && \
		$(expr ${FILECOUNT} % 100) -eq 0 ]] && \
		echo -n "."
	[[ ${verbose} -eq 1 && \
		$(expr ${FILECOUNT} % 7000) -eq 0 ]] && \
		{ \
			echo ""; echo "$(date '+%T') ${FILECOUNT}"
		}
done < ${TMPDIR}/thislist
wait
