#!/bin/bash
source yfunc.global
source yfunc.hashdirpath
source yfunc.maketop
source yfunc.put_nhid
source func.errecho
source func.locker
source func.regex

USAGE="${0##*/} [-h] [-d] <directory> [ <rootpath> ]\r\n
\t<directory>\tThe directory that will be copies and converted\r\n
\t\t\tto a YesFS file system prototype using b2sum cryptographici\r\n
\t\t\thash.\r\n
\t<rootpath>\tThe directory where the YesFS file system will be\r\n
\t\t\tplaced.  Default is ~/.hashes. \r\n
\r\n
\t~!~!~!~!~!~! WARNING ~!~!~!~!~!~!\r\n
\tSTILL UNDER DEVELOPMENT - MAY BE BROKEN\r\n\r\n
\t-h\t\tPrint this help information.\r\n
\t-d\t\tPrint diagnostic information\r\n
\t\t\t(dump manifests as created).\r\n
\t-v\t\tPrints a '.' for every 100 files processed.\r\n
\t\t\tDefault is on.\r\n
\t\t\tToggles the default.  Prints a timestamp\r\n
\t\t\tevery 7000 files.\r\n
"
USAGE_VERBOSE="\t\t\tA \"normal\" looking file tree is located\r\n
\t\t\tat <rootpath>.  The contents of the filenames in this\r\n
\t\t\tdirectory tree will be the Name Hash ID (NHID) of the\r\n
\t\t\tnamed file.  This is only for the convenience of\r\n
\t\t\tdevelopers/debuggers to browse a normal tree in the\r\n
\t\t\tlocal file system.  The local file system will place the\r\n
\t\t\thash files in <rootpath>/.hash.  Using the PUT and\r\n
\t\t\tGET commands and library functions will allow the\r\n
\t\t\tretrieval of the file contents and/or metadata.\r\n
"

optionargs="hdv"
NUMARGS=2
debug=0
verbose=1
if [ ${EUID} -eq 9 ]
then
  export YesFSdir=${YesFSdir:=/hashes}
else
  export YesFSdir=${YesFSdir:=${HOME}/.hashes}
fi
func_putcounter "${FILECOUNT_lock}" "${FILECOUNT_file}" 0
export FILECOUNT=$(func_getcounter "${FILECOUNT_lock}" \
  "${FILECOUNT_file}")

while getopts ${optionargs} name
do
	case ${name} in
	h)
		echo -e ${USAGE}
    if [ "${verbose}" -eq 1 ]
    then
      echo -e ${USAGE_VERBOSE}
    fi
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
shift
if [ $# -gt 0 ]
then
  YesFSdir="$1"
fi

if [ ! -d "${topdir}" ]
then
	stderrecho "Not a directory ${topdir}"
	exit 0
fi

maketop "${YesFSdir}"

[ ${verbose} -eq 1 ] && echo $(date '+%T')

find . -type f -print | parallel yes1 {}
