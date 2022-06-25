#!/bin/bash
if [ -z "${__yfunc_put_nhid}" ]
then
	source yfunc.global
	source func.errecho
	source func.insufficient
	export __func_put_nhid=1

	function put_nhid {
		[ $# -lt 5 ] && insufficient 5 $@
		filename="$1"
		yesfsdir="$2"
		timestamp="$3"
		chunklog="$4"
    cryptoid="$5"
		
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~
# Change all usage of b2sum and its lengh to functions of the 
# Associative arrays
#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~#~

    ####################################################################
    # First we compute the hash of the full name of the file.  This
    # must include the complete YesFS path from the root of the
    # YesFS filesystem (YesFS_HASH) to the current file.  This means
    # that we need the context of the YesFS tenant, the path name
    # within the tenant space and the name of the file itself.  To do
    # this we need YesFS versions of pwd, i.e. ypwd as well.  There
    # are also files which are part of the YesFS configuration which 
    # belong to the tenant __YesFS and are found in __YesFS/etc files
    # as the data tables that manage the file system.  In terms of
    # passed parameters, we will assume for simplicity that the
    # filename passed to this function includes all of the correct
    # elements in the filename path.
    ####################################################################
    # The num2bin array contains the mapping from the CryptoID number
    # to the local system's executable file which will take stdin
    # piped input of a file/string and return a non-canonical hash
    # code "  -" as the name of the hashed data.
    ####################################################################
		nhidhash="$(echo "${filename}" | ${num2bin[${cryptoID}]})"

    ####################################################################
    # We take the hex encoded hash string and prefix it with the
    # cryptoID of the hash program, a colon and then the number of
    # character encoded hex characters representing the hash encoding
    ####################################################################
    nhid="${cryptoid}:${nhidhash:0:${num2hexdigits[${cryptoid}]}}"
    p_nhid=$(hashdirpath ${nhid})
		f_nhid="${p_nhid}/${nhid}"

    NHID["chunktype"]="nhid"
    NHID["fullname"]=$(echo $filename)
    MANI["chunktype"]="manifest"
    MANI["prevmani"]=""
    BACKR["chunktype"]="backreference"
    BACKR["name"]=${f_nhid}
    BACKR["ctime"]="$(date -U -Ins)"
    BACKR["speculative"]="TRUE"
    BACKR["next"]=""
    BACKR["prev"]=""
    MANI["back"]=$(put_backr ${cryptoid})
    MANI["objlen"]=$(stat -c "%s" ${filename})
    MANI["ctime"]="$(date -u -Ins)"
    chunkhash=$(${num2bin[${cryptoid}]} $filename)
    chid="${cryptoid}:${chunkhash:0:${num2hexdigits[${cryptoid}]}}"
    p_chid=$(hashdirpath ${chid})
    f_chid="${p_chid}/${chid}"
    cp ${filename} ${f_chid}
    MANI["hash0"]="${chid}"
    MANI["off0"]=0
    for i in $(sed 1 7)
    do
      MANI["hash${i}"]=0
      MANI["off${i}"]=0
    done
    NHID["objmani"]=$(put_mani ${cryptoid})
    NAMEMETA["chunktype"]="namemeta"
    NAMEMETA["ownerid"]="$(stat -c "%u" ${filename})"
    NAMEMETA["groupid"]="$(stat -c "$g" ${filename})"
    NAMEMETA["perm"]="$(stat -c "%A" ${filename})"
    NAMEMETA["next"]=""
    NHID["namemeta"]="$(put_namemeta ${cryptoid})"
    echo "${nhid}"
	}
	export put_nhid
fi # if [-z "${__yfunc_put_nhid}" ]
