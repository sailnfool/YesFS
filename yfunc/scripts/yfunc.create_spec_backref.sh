#!/bin/bash
source yfunc.hashdirpath
if [ -z "${__func_create_spec_backref}" ]
then
	export __func_create_spec_backref=1

	function create_spec_backref {
		chid=$1
		nhid=$2
	}
fi #if [ -z "${__func_create_spec_backref}" ]
