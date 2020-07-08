#!/bin/bash
scriptname=${0##*/}
####################
#_____________________________________________________________________
# Rev.|Auth.| Date     | Notes
#_____________________________________________________________________
# 1.0 | REN |07/07/2020| Initial Release
#_____________________________________________________________________
#
####################
# Author Robert E. Novak
#
# This script uses b2sum to generate the first 8 characters of string
# which is arg1.
#
# These characters are used as sample characters in the explanation
# of the field description
#

source func.errecho

USAGE="\r\n${scriptname} [-h] [ -d # ] [-b] [ -s <string> ] <filename>\r\n
\t\treturn the b2sum hash of a string or a filename\r\n
\t-h\tPrint this message\r\n
\t-d #\tturn on diagnostics to level #\r\n
\t-b\tReturn the brief (last for hex digits) of the hash\r\n
\t-s <string>\treturn the b2sum hash of <string>\r\n"

optionargs="hd:fbs:"
NUMARGS=1
FUNC_DEBUG="0"
BRIEF=FALSE
FIRST=FALSE
export FUNC_DEBUG

while getopts ${optionargs} name
do
	case ${name} in
	h)
#		errecho "-e" ${USAGE}
		echo -e ${USAGE}
		exit 0
		;;
	s)
		string=${OPTARG}
		NUMARGS=0
		;;
	b)
		BRIEF=TRUE
		;;
	f)
		FIRST=TRUE
		;;
	d)
		FUNC_DEBUG=${OPTARG}
		export FUNC_DEBUG
		;;
	\?)
		errecho "-e" "invalid option: -$OPTARG"
		errecho "-e" ${USAGE}
		exit 0
		;;
	esac
done

if [ $# -lt ${NUMARGS} ]
then
	errecho "Insufficient Parameters: ${NUMARGS} required, $# supplied"
	errecho "-e" ${USAGE}
	exit -2
fi
shift "$(($OPTIND -1))"
# echo "Number of unparsed Parameters is $#"
if [ "${FUNC_DEBUG}" -gt 0 ]
then
	if [ $# -gt 0 ]
	then
		errecho "${filename}"
	else
		errecho "${string}"
	fi
fi
if [ $# -gt 0 ]
then
	filename=$1
	# b2sum ${filename} | awk '{print $1}'
	hashstring=$(b2sum ${filename})
else
	#echo ${string} | b2sum | awk '{print $1}'
	hashstring=$(echo ${string} | b2sum)
fi
if [ "$BRIEF" = "TRUE" ]
then
	briefhash=${hashstring:0:128}
	echo ${briefhash:(-4)}
else
	if [ "$FIRST" = "TRUE" ]
	then
		echo ${hashstring:0:8}
	else
		echo ${hashstring:0:128}
	fi
fi
# vim: set syntax=bash
