#!/bin/bash
scriptname=${0##/*}
########################################################################
# Author: Robert E. Novak
# email: sailnfool@gmail.com
# Copyright (C) 2022 Sea2Cloud Storage, Inc. All Rights Reserved
# Modesto, CA 95356
#
# Create_canonical - Create the canonical hash lists
#                    Given an initial list of canonical numbers
#                    and short hash names, generate the following
#                    lists:
#                          number to short hash name
#                          short hash name to number
#                          number to executable (local)
#                          number to number of bits generated
#
#                    Given these lists, generate a function that
#                    will load these lists into Bash Associative
#                    arrays for use in a bash script.
#
########################################################################
#_____________________________________________________________________
# Rev.|Auth.| Date     | Notes
#_____________________________________________________________________
# 1.0 | REN |53/26/2022| original version
#_____________________________________________________________________

if [[ -z "${__yfunc_create_canonical}" ]]
then
  export __yfunc_create_canonical=1

	source yfunc.global
	source func.errecho
	source func.regex
	source func.debug
	source func.hex2dec
	
	canonical_source=${HOME}/github/YesFS/etc/export.csv
	canonical_dir=${canonical_source%/*}

  USAGE="${0##*/} [-[hv]] [-d <#>] <file>\n
\t\tThis command will create the canonical files for cryptographic\n
\t\tprograms.  The default file is:\n
\t\t${canonical_source}\n
\n
\t\tThe default files are:\n
\t\t\tnumber to short hash name\t\tnum2hash.csv\n
\t\t\tshort hash name to number\t\thash2num.csv\n
\t\t\tnumber to executable\t\tnum2bin\n
\t\t\tnumber to hash length in bits\t\tnum2bits\n
\t\t\tin the same directory as the source file,\n
\n
\t\t\tThen these files are loaded into the same directory as the file\n
\t-h\t\tPrint this help information.\n
\t-d\t<#>\tPrint diagnostic information. Use -v for Debug levels\n
\t\t\t(dump manifests as created).\n
\t-v\t\tUse '-vh' to display the debug levels\n
"

  VERBOSE_USAGE="\t\t\tDEBUGOFF 0\r\n
\t\t\tDEBUGWAVE 2 - print indented entry/exit to functions\r\n
\t\t\tDEBUGWAVAR 3 - print variable data from functions if enabled\r\n
\t\t\tDEBUGSTRACE 5 = prefix the executable with strace\r\n
\t\t\t                (if implement)\r\n
\t\t\tDEBUGNOEXECUTE or\t\n
\t\t\tDEBUGNOEX 6 - generate and display the command lines but don't\r\n
\t\t\t              execute the script\r\n
\t\t\tDEBUGSETX 9 - turn on set -x to debug\r\n
"
	######################################################################
	# environmental and script dependent variables.
	######################################################################
	optionargs="hdv"
	NUMARGS=1
	debug=0
	verbose="FALSE"
	
	######################################################################
	# default defined in yfunc.global (should be the same)
	######################################################################
	YesFS=${YesFS:-/home/rnovak/dropbox/YesFS}
	
	while getopts ${optionargs} name
	do
		case ${name} in
		h)
			echo -e ${USAGE}
	    if [[ "${verbose}" = "TRUE" ]]
	    then
	      echo -e ${VERBOSE_USAGE}
	    fi
			exit 0
			;;
		d)
	    if [[ "${OPTARG}" =~ $re_digit ]]
	    then
	      debug="${OPTARG}"
	    else
	      errecho -e "-d requires a single digit"
	      echo -e ${USAGE}
	      exit 1
	    fi
			;;
		v)
	    if [[ "${verbse}" = "FALSE" ]]
			then
	      verbose="TRUE"
	    else
	    	if [[ "${verbose}" = "TRUE" ]]
	      then
				  verbose="FALSE"
	      fi
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

  if [[ "$#" -ge 0 ]]
  then
	  filename="$1"
		if [ ! -f "${filename}" ]
		then
			echo "filename=${filename} is not a file"
			exit 1
		fi
  fi
	canonical_source=${filename}
	canonical_dir=${canonical_source%/*}
	
  for i in num2bin num2hash num2bits hash2num
  do
    if [[ -r ${canonical_dir}/${i}.csv ]]
    then
      rm -f ${canonical_dir}/${i}.csv
    fi
  done
	cut --fields=1-3 ${canonical_source} | \
    while read hashnumber hashshortname hashbits
	do
	
	  ####################################################################
	  # skip the title line
	  ####################################################################
	  if [[ "${hashnumber}" = "Index" ]]
	  then
	    continue
	  fi
	  num2hash[$(func_hex2dec ${hashnumber})]=${hashshortname}
	  hash2num[$"{hashshortname}"]=${hashnumber}
	  num2bits[$(func_hex2dec ${hashnumber})]=${hashbits}
	  if [[ "${verbose}" = "TRUE" ]]
	  then
	    echo -e "${hashnumber}\t${hashshortname}\t${hashbits}"
	  fi
	  if [[ $(which ${hashshortname}) ]]
	  then
	    num2bin[$(func_hex2dec ${hashnumber})]=$(which ${hashshortname})
      echo "${hashnumber}\t${hashshortname}" >> ${canonical_dir}/num2bin.csv
	    if [[ "${verbose}" = "TRUE" ]]
	    then
	      echo "Found ${hashshortname}"
	    fi
	  else
	    num2bin[$(func_hex2dec ${hashnumber})]=""
	  fi
    echo "${hashnumber}\t${hashshortname}" >> ${canonical_dir}/num2hash.csv
    echo "${hashshortname}\t${hashnumber}" >> ${canonical_dir}/hash2num.csv
    echo "${hashnumber}\t${hashbits}" >> ${canonical_dir}/num2bits.csv
	done

  for i in num2bin num2hash num2bits hash2num
  do
    if [[ -r ${canonical_dir}/${i}.csv ]]
    then
      sort ${canonical_dir}/${i}.csv >> /tmp/copy$$_${i}.csv
      mv /tmp/copy$$_${i}.csv ${canonical_dir}/${i}.csv
    fi
  done
  export num2hash
  export hash2num
  export num2bits
  export num2bin
fi #if [[ -z "${__yfunc_create_canonical}" ]]
