#!/bin/bash
########################################################################
# Author: Robert E. Novak
# email: sailnfool@gmail.com
# Copyright (C) 2022 Sea2Cloud Storage, Inc. All Rights Reserved
# Modesto, CA 95356
#
# Create a backreference from the global associative array BACKR using
# the cryptoID passed as a parameter.  Return the backrID.
#
########################################################################
#_____________________________________________________________________
# Rev.|Aut| Date     | Notes
#_____________________________________________________________________
# 1.0 |REN|05/01/2022| original version
#_____________________________________________________________________

if [[ -z "${__yfunc_put_backr}" ]]
then
  source yfunc.global
  source func.insufficient

  function put_backr {

    local cryptoID
    local backrhash
    local backrID
    local p_backrID
    local f_backrID

    [[ $# -lt 1 ]] && insufficient 5 $@
    cryptoID="$1"

	  ####################################################################
	  # When we are invoked there is an instance of BACKR associative
	  # array with all of the fields filled in.  First we will output
	  # the key/value form of the array to a temp file, compute the 
	  # hash value of that temp file, and then move it into the YesFS
	  # hash storage under the name <hash_value>.BACKR
	  ####################################################################
	  for i in "${BACKR[@]}"
	  do
	    echo -e "$i\t${BACKR[${i}]}" > /tmp/backr.$$
	  done
	  backrhash=$($[num2bin[${cryptoID}]} /tmp/backr.$$)
	  backrID="${cryptoID}:${backrhash:0:$((${num2hexdigits[${cryptoID}]}}
	  p_backrID=$(hashdirpath ${backrID})
	  f_backrID=${p_backrID}/${backrID}.BACK
	  mv /tmp/backr.$$ ${f_backrID}
	  echo ${backrID}
	}
  export put_backr
fi # if [[ -z "${__yfunc_put_backr}" ]]

