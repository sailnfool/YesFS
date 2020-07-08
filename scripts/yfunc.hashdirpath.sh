if [ -z "${__func_writehash}" ]
then
	export __func_hashdirpath=1

	function hashdirpath {
		hashid=$1

		dir=${hashid:0:2}
		subdir=${hashid:2:2}
		dirpath=${HASHES}/${dir}/${subdir}
		if [ -z "${dirpath}" ]
		then
			echo $FUNCNAME $LINENNO Empty directory
			exit -1
		fi
		mkdir -p ${dirpath}
		echo ${dirpath}
	}
	export hashdirpath
fi # if [-z "${__func_writehash}" ]
