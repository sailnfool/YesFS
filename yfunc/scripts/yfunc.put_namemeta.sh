#!/bin/bash
########################################################################
# Author: Robert E. Novak
# email: sailnfool@gmail.com
# Copyright (C) 2022 Sea2Cloud Storage, Inc. All Rights Reserved
# Modesto, CA 95356
#
# Create a manifest from the global associative array NAMEMETA using
# the cryptoID passed as a parameter.  Return the namemetaID.
#
########################################################################
#_____________________________________________________________________
# Rev.|Auth.| Date     | Notes
#_____________________________________________________________________
# 1.0 | REN |05/01/2022| original version
#_____________________________________________________________________

if [[ -z "${__yfunc_put_namemeta}" ]]
then
  source yfunc.global
  source func.insufficient

  function put_namemeta {
    [[ $# -lt 1 ]] && insufficient 5 $@
    cryptoID="$1"

	  ####################################################################
	  # When we are invoked there is an instance of NAMEMETA associative
	  # array with all of the fields filled in.  First we will output
	  # the key/value form of the array to a temp file, compute the 
	  # hash value of that temp file, and then move it into the YesFS
	  # hash storage under the name <hash_value>.BACKR
	  ####################################################################
	  for i in "${NAMEMETA[@]}"
	  do
	    echo -e "$i\t${NAMEMETA[${i}]}" > /tmp/namemeta.$$
	  done
	  namemetahash=$($[num2bin[${cryptoID}]} /tmp/namemeta.$$)
	  namemetaID="${cryptoID}:${namemetahash:0:$((${num2hexdigits[${cryptoID}]}}
	  p_namemetaID=$(hashdirpath ${namemetaID})
	  f_namemetaID=${p_namemetaID}/${namemetaID}.NAMEMETA
	  mv /tmp/namemeta.$$ ${f_namemetaID}
	  echo ${namemetaID}
	}
  export put_namemeta
fi # if [[ -z "${__yfunc_put_namemeta}" ]]

