#!/bin/bash
########################################################################
# Author: Robert E. Novak
# email: sailnfool@gmail.com
# Copyright (C) 2022 Sea2Cloud Storage, Inc. All Rights Reserved
# Modesto, CA 95356
#
# Create a manifest from the global associative array MANI using
# the cryptoID passed as a parameter.  Return the backrID.
#
########################################################################
#_____________________________________________________________________
# Rev.|Auth.| Date     | Notes
#_____________________________________________________________________
# 1.0 | REN |05/01/2022| original version
#_____________________________________________________________________

if [[ -z "${__yfunc_put_mani}" ]]
then
  source yfunc.global
  source func.insufficient

  function put_mani {
    [[ $# -lt 1 ]] && insufficient 5 $@
    cryptoID="$1"

	  ####################################################################
	  # When we are invoked there is an instance of MANI associative
	  # array with all of the fields filled in.  First we will output
	  # the key/value form of the array to a temp file, compute the 
	  # hash value of that temp file, and then move it into the YesFS
	  # hash storage under the name <hash_value>.MANI
	  ####################################################################
	  for i in "${MANI[@]}"
	  do
	    echo -e "$i\t${MANI[${i}]}" > /tmp/mani.$$
	  done
	  manihash=$($[num2bin[${cryptoID}]} /tmp/mani.$$)
	  maniID="${cryptoID}:${manihash:0:$((${num2hexdigits[${cryptoID}]}}
	  p_maniID=$(hashdirpath ${maniID})
	  f_maniID=${p_maniID}/${maniID}.MANI
	  mv /tmp/mani.$$ ${f_maniID}
	  echo ${maniID}
	}
  export put_backr
fi # if [[ -z "${__yfunc_put_mani}" ]]

