#!/bin/bash
if [ $# -ne 1 ]
then
	echo ${0##*/} One argument is required
	exit -1
fi
echo $(getb2sum -f -s "$1")
exit 0
