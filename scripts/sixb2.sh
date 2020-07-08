#!/bin/bash
source yfunc.hashdirpath
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
topdir=$1
if [ $# -ge 2 ]
then
	yesfsdir=$2
fi
set -x
TMPDIR=/tmp/${yesfsdir##*/}.$$.dir
mkdir -p ${TMPDIR}
if [ ! -d ${yesfsdir} ]
then
	HASHES=${yesfsdir}/.hash
	sudo mkdir -p ${HASHES}
	sudo chmod 777 ${HASHES}
fi
DIRLIST=${TMPDIR}/directories
CHUNKLOG=${yesfsdir}/.chunklog
if [ ! -d "${topdir}" ]
then
	echo "Not a directory ${topdir}"
	exit 0
fi
set +x
####################
# Find all of the directories in the current path and put the list
# of directories in a file.  We will process the files one directory
# at a time.
####################
find "${topdir}" -type d -a \( -name hashes -o -name tmp \) -prune \
	-o -type d -print  > ${DIRLIST}

if [ ${debug} -eq 1 ]
then
	cat ${DIRLIST}
	ls -l ${DIRLIST}
	wc -l ${DIRLIST}
fi

####################
# These are the pieces of information that come from stat
# to add to the Manifest.  See man 1 stat
####################
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
	manifestfmt="${manifestfmt}${manifest[$i]}"
done

[ ${verbose} -eq 1 ] && echo $(date '+%T')
while read -r dirname
do
	if [ ! -d "$dirname" ]
	then
		echo "${0##*/} $LINENO dirname=${dirname} is not a directory"
		exit -1
	fi

	b2sum "$dirname"/* 2> /dev/null >/${TMPDIR}/thislist

	while read -r hashline
	do
		####################
		# A line beginning with "Failed" is a directory or
		# other special file.  Ignore
		####################
		if [ "${hashline:0:5}" == "Failed" ]
		then
			continue
		fi

		####################	
		# Get the content hash ID of the file: CHID
		# and the filename
		####################	
		chid=${hashline:0:128}
		p_chid=$(hashdirpath ${chid})
		f_chid="${p_chid}/${chid}"

		filename=${hashline:130}
		if [ ! -f "${filename}" ]
		then
			echo "filename=${filename} is not a file"
			exit 0
		fi

		((FILECOUNT++))

		####################	
		# Get the name hash ID of the file: NHID
		####################	
		namehash=$(echo ${filename} | b2sum)
		nhid=${namehash:0:128}

		####################	
		# This timestamp will create a new time stamp each
		# time it is referenced.  It creates two fields:
		# YYYYMMDD_HHMMSS
		# seconds_since_epoch.current_nanoseconds
		#
		# By removing the '\' at the beginning of the string
		# this would become a single timestamp for all elements
		# of the object creation, which may be desirable.
		####################	
		timestamp="\$(date -u '+%Y%m%d_%T\t%s.%N')"

		####################	
		# This next step should be the process that breaks
		# the file into multiple chunks and ties each of those
		# chunks back to the nhid as they are created, building
		# the basis for the chunk list that is at the end of
		# the manifest for the object.  For now we simplify
		# by turning the object into a single chunk.
		####################	
		
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
		for i in $(seq 0 3)
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
done  < ${DIRLIST}
