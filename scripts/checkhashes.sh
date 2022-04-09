#!/bin/bash
scriptname=${0##*/}
####################
# Copyright (c) 2019 Sea2Cloud Storage, Inc.  All Rights Reserved
# Modesto, CA 95356
#
# checkhashes - Given a list of hash function names check for the
#               existence of programs to perform the hash function.
# Author - Robert E. Novak aka REN
#	sailnfool@gmail.com
#	skype:sailnfool.ren
# License CC by Sea2Cloud Storage, Inc.
# see https://creativecommons.org/licenses/by/4.0/legalcode
# for a complete copy of the Creative Commons Attribution license
#_____________________________________________________________________
# 1.0 | REN |04/08/2022| Initial Release
#_____________________________________________________________________
#
########################################################################
# This script takes a CSV file which has in the second column a list
# of hash function names.  It checks to see if the hash function is 
# installed on the machine.  If it is not, it checks the APT repository
# to see if there is a package that contains the program.  If there is
# then it installs the program on the local machine, verifies the
# default length of a generated binary hash
#

source func.debug
source func.errecho
source func.insufficient

USAGE="\r\n${scriptname} [-[h]] [-v <#>] <file.csv>\r\n
\t\tReads the second column of <file.csv>\r\n
\t-h\t\tPrint this message\r\n
\t-v\t<#>\tturn on verbose mode for this script\r\n
"

optionargs="hv:"
NUMARGS=1
FUNC_DEBUG="0"
export FUNC_DEBUG

while getopts ${optionargs} name
do
	case ${name} in
	h)
#		errecho "-e" ${USAGE}
		echo -e ${USAGE}
		exit 0
		;;
	v)
		FUNC_DEBUG="${OPTARG}"
		;;
	\?)
		errecho "-e" "invalid option: -$OPTARG"
		errecho "-e" ${USAGE}
		exit 1
		;;
	esac
done

########################################################################
# Skip over the option arguments
########################################################################
shift "$((OPTIND -1 ))"

########################################################################
# Make sure that we have the requisit number of arguments
########################################################################
if [ $# -lt ${NUMARGS} ]
then
	errecho "-e" ${USAGE}
	insufficient ${NUMARGS} $@
	exit -2
fi

########################################################################
# The name of the file is required as an argument
########################################################################
hashfile="$1"

########################################################################
# If the file doesn't exist, tell the user and quit
########################################################################
if [[ ! -f "${hashfile}" ]]
then
  errecho -e "Could not open ${hashfile}"
  errecho -e ${USAGE}
  exit 2
fi

########################################################################
# If the input file is tab delimited, change it to "|" delimited
########################################################################
if [[ $(grep '\t' ${hashfile}) ]]
then
  tr "\t" "|" < "${hashfile}" > /tmp/t$$
  mv /tmp/t$$ "${hashfile}"
fi

linesread=1
OLDIFS=$IFS
IFS="|"
declare -A hashindex

if [[ ! -f ${hashfile}.idx ]]
then
  while read -r index short bytes bits
  do
	  if [[ "$index" = "Index" ]]
    then
      continue
    fi
    hashindex[${short}]=${index}
    if [[ "${FUNC_DEBUG}" -gt 0 ]]
    then
      errecho "short=\'${short}\', index=\'${index}\'"
      errecho "hashindex[${short}]=${hashindex[${short}]}"
    fi
  done < ${hashfile}
  for key in "${!hashindex[@]}"
  do
    echo "${key}|${hashindex[${key}]}" >> ${hashfile}.idx
    if [[ "${FUNC_DEBUG}" -gt 0 ]]
    then
      errecho "${key}|${hashindex[${key}]}"
    fi
  done
fi
unset hashindex
while read -r short index
do
  hashindex[${short}]=${index}
done

########################################################################
# Read the input fields from the file created in a spreadsheet and
# then exported to a csv flat file with tab separators converted to "|"
########################################################################
while read -r index short bytes bits
do
  if [[ "${FUNC_DEBUG}" -gt ${DEBUGWAVAR} ]]
  then
    errecho "line Number ${linesread}"
    errecho -e "${index}|${short}|${bytes}|${bits}"
  fi

  ######################################################################
	# Handle the title line specially and add the new column that we will
  # generate that contains the index of the hashfunction followed by
  # a colon, followed by the "native" hash of the function name
  ######################################################################
	if [[ "$index" = "Index" ]]
  then
    echo -n "${index}|${short}|${bytes}|${bits}"
    echo "|Ubuntu Binary|Ubuntu path|PREFIX:NATIVE_SUM|b2sumprefix:b2sum"
    continue
  fi

  ######################################################################
  # At this point we have a valid input line.  ${short} is the short
  # name of the hash function.
  ######################################################################
	if [[ "${FUNC_DEBUG}" -gt ${DEBUGWAVAR} ]]
	then
	  errecho -e "Looking for ${index} ${short}"
	fi

  ######################################################################
  # If the function does not exist on this machine, see if we can 
  # find it in the apt-get database.  There is a known bug with 
  # finding and installing the sha3sum
  ######################################################################
	if [[ ! $(which ${short}) ]]
	then
	  if [[ "${FUNC_DEBUG}" -gt ${DEBUGWAVAR} ]]
	  then
	    errecho -e "Could not find ${index} ${short} $(which ${short})"
	  fi
    ####################################################################
    # First we have to make sure that the database for Debian packages
    # which is used to locate the package that contains a binary.
    ####################################################################
	  if [[ ! $(which apt-file) ]]
	  then
      errecho "We need sudo privileges to get the apt-file " \
        "package database"
	    sudo apt-get install apt-file
	    sudo apt-get update
	  fi
	  if [[ "${FUNC_DEBUG}" -gt ${DEBUGWAVAR} ]]
	  then
	    errecho -e "Looking for ${index} ${short}"
	  fi

    ####################################################################
    # Use a regular expression search of the apt-file package to make
    # sure we are only looking for bin (executable) packages
    ####################################################################
    apt_file_result=/tmp/apt_file_result_$$
	  $(apt-file search --regexp "bin/${short}\$") > ${apt_file_result}

    ####################################################################
    # Read in the package name and the install path of the executable
    ####################################################################
	  while IFS=": " read -r package install
	  do
	    errecho -e "Installing ${package} need sudo permission"
	    sudo apt-get install ${package}
	  done < ${apt_file_result}

    ####################################################################
    # Clean up the temporary file
    ####################################################################
	  rm -f ${apt_file_result}
	fi
  
  ######################################################################
  # At this point if the package install was successful, the executable
  # should be installed, but we have to double-check since it may not
  # have been available
  ######################################################################
	if [[ ! $(which ${short}) ]]
	then

    ####################################################################
    # Since there is no binary available, fill the fields with N/A
    ####################################################################
	  echo -n "${index}|${short}|${bytes##\ *}|${bits}|\"N/A\"|\"N/A\""
    echo "||"${hashindex[\"b2sum\"]}:$(echo ${short} | b2sum | cut -d ' ' -f 1)
	  if [[ "${FUNC_DEBUG}" -gt ${DEBUGWAVAR} ]]
	  then
	    errecho -e "Could not find ${index} ${short} $(which ${short})"
	  fi
	else
	  if [[ "${FUNC_DEBUG}" -gt ${DEBUGWAVAR} ]]
	  then
	    errecho -e "Found ${index} ${short}"
	  fi

    ####################################################################
    # At this point we know we have an executable
    # Note that ${app_path##*/} == $(basename ${app_path})    and
    # ${app_path%/*} == $(dirname ${app_path})
    # see https://wiki.bash-hackers.org/syntax/pe#substring_removal
    # for a full explanation.  The built-in syntax is faster than
    # calling an external routine.
    ####################################################################
	  app_path=$(which ${short})
	  if [[ "${FUNC_DEBUG}" -gt ${DEBUGWAVAR} ]]
	  then
	    errecho "app_path = \"${app_path}\""
	    errecho "${index}|${short}|${bytes##\ *}|${bits}" \
        "|${app_path##*/}|${app_path%/*}"
	  fi

    ####################################################################
    # Compute the hash of the program name using the program
    ####################################################################
	  hashname=$(echo ${app_path##*/} | ${app_path} | \
      cut -d ' ' -f 1)
	  hashlength=${#hashname}
	  if [[ "${FUNC_DEBUG}" -gt 0 ]]
	  then
	    errecho "hashlength=${hashlength} ${#hashname}"
	  fi

    ####################################################################
    # Each hex digit output by the hash program represnts 4 bits of
    # generated hash and the hash will occupy 1/8 that number of bytes
    ####################################################################
	  realhashlengthbits=$((hashlength*4))
	  realhashlengthbytes=$((realhashlengthbits/8))

    ####################################################################
    # Compare the computed length of the hash against the length that
    # was specified in the input table and issue an error message if
    # there is a discrepancy.
    ####################################################################
	  if [[ "${realhashlengthbits}" -ne "${bits}" ]]
	  then
	    errecho "For \'${short}\' Table bits ${bits} not equal measured bits ${realhashlengthbits}"
	  fi
	  echo -n "${index}|${short}|${realhashlengthbytes}|"
    echo -n "${realhashlengthbits}|${app_path##*/}|"
    echo -n "${app_path%/*}|${index}:${hashname:-1}|"
    echo "${hashindex["b2sum"]}:$(echo ${app_path##*/} | b2sum | cut -d ' ' -f 1)"
	fi
	((++linesread))
done < ${hashfile}
IFS=$OLDIFS
