#!/bin/bash
if [ -z "${__yfunc_global}" ]
then
	export __yfunc_global=1

	source func.regex
	source func.hex2dec

########################################################################
# Global Strings used in YesFS data structures
#
# In this first implementation system data structures are represented
# files in the form of <hashname>.<suffix> where hashname is the
# cryptographic hash of the chunk with which metadata is defined.
# Suffix is the abbreviation for the metadata structure which holds
# information about the chunk. A file that is simply <hashname> is
# the entire actual file without splitting it into chunks.
#
# Given that we have adopted the canonical representation of the
# cryptographic hash codes, the ASCII HEX encoded name of each
# hash is <CANONICAL_HASH_NUMBER><HEX Encoded Cryptographic Hash>
# Where:
#       <CANONICAL_HASH_NUMER>:=[0-9a-fA-F]{3}
# Eventually the following files will be looked up as objects in the
# YesFS file system.  The human readable names and descriptions of the
# files are as follows:
#
# ${YesFS}/num2hash.csv     The list of canonical codes and the
#                           canonical short name of the cryptographic
#                           hash
# ${YesFS}/num2bits.csv     The list of the number of bits created by
#                           using the canonical hash
# ${YesFS}/hash2num.csv     The inverse list of num2hash sorted by
#                           the short hash name
# ${YesFS}/hostname/num2bin.csv  The list of locations on the hostname
#                           where the executable copies of canonical
#                           cryptographic codes are found.  If there
#                           is no entry, then there is no available
#                           executable
# ${YesFS}/num2hexdigits.csv This list of the number of hex digits
#                           based on the num2bit.csv.  Saves doint the
#                           math each time.
#
# The file system information is stored in a directory similar to the
# "tank" of ZFS.  The default root is a named root and is YesFS if not
# otherwise specified.
#
# Directory name uses the most significant 4 bytes of the ASCII
# encoding of the hash name.
# These directories will be present on the local file system as
# caches of the files that were created from this host.  Each of these
# directories corresponds to a "Flexhash" row which may be replicated
# by 3 or more servers (a single server may support more than one
# hash row).
#
# At the time that a chunk is created, the name, the type and the name
# of the cryptographic hash function are logged in the CHUNKLOG
#
########################################################################
export YesFS=/home/rnovak/Dropbox/YesFS
export HASHES=${YESFS}/.hash
export CHUNKLOG=${YESFS}/.chunklog
export FAILEDTOHASH_string="Failed to hash \`"

export FILECOUNT_lock="${YESFS}/FILECOUNT.lock"
export FILECOUNT_file="${YESFS}/FILECOUNT.file"

########################################################################
# This timestamp will create a new time stamp each
# time it is referenced.  The Time stamp is represented
# in the format of the ISO 8601-2:2019 interchange format
# as specified in "man date" the ISO format with nanosecond resolution
# is requested.
#
# Not sure what I had in mind when I wrote the following three lines?
# By removing the '\' at the beginning of the string
# this would become a single timestamp for all elements
# of the object creation, which may be desirable.
#
# This should be in the format of the AWS S3 timestamp
########################################################################
timestamp="\$(date -u -Ins)"

########################################################################
# Create the associative arrays which will hold the canonical index
# of each known and support cryptographic hash type.
#
# The files used to create these arrays are documented in
# yfunc.create_canonical.sh
########################################################################
declare -A num2hash
declare -A hash2num
declare -A num2bin
declare -A num2bits

########################################################################
# hashoffset is the offset in the hashid array after the 4 character
# canonical hash ID
########################################################################
export hashoffset=4
export flexhashrows=$(($(func_hex2dec "FFFF") + 1 ))
export flexdirchars=$((${hashoffset}+4 ))

########################################################################
# Initialize the arrays
########################################################################
#$(yfunc.create_canonical)

########################################################################
# Select the default cryptographic hash used and the backup hash
########################################################################
# default_hash=sha256sum
# hashid=${hash2num[${default_hash}]}
# hashbin=${hash2bin[${default_hash}]}
# hashbits=${num2bits[${hashid}]}

declare -A NHID
NHID["chunktype"]="nhid" # The name of this chunk type
NHID["objmani"]="" # Hash of the object manifest that the name refers
	                 # to
NHID["namemeta"]="" # HashiD of the name-affiliated metadata (e.g.,
	                  # owner, group, permissions
NHID["fullname"]="" # Full pathname of the object as a NUL terminated
	                  # string
NHID["back"]="" # Pointer to the first back reference to the name
	              # Typically the pointer to the object which is the
	              # hierarchical directry that contains the name.
declare -A NAMEMETA
NAMEMETA["chunktype"]="namemeta" #The name of this chunk type
NAMEMETA["ownerid"]="" # Owner UserID# typically > 2000 for
	                     # unprivileged users
NAMEMETA["groupid"]="" # Owner GroupID# typically > 2000 for
	                     # unprivileged users
NAMEMETA["perm"]="" # SetUserID, Set GroupID, Owner, Group, World
	                  # RWX permissions
NAMEMETA["next"]="" # Hash to the next name-affiliated metadata chunk
declare -A BACKR
BACKR["chunktype"]="backreference"
BACKR["name"]="" # Name HashID of the first name that refers to this
	               # object
BACKR["ctime"]="" # Time Stamp When Backreference was created in
	                # seconds since Epoch
BACKR["speculative"] # Speculative Back Reference
BACKR["next"] # Hash of the next back reference
BACKR["prev"] # Hash of the previous back reference
declare -A CHUNKACC
CHUNKACC["chunktype"]="chunkacc" # The name of this chunk type
CHUNKACC["prev"]="" # The hash of the previous access time record for
	                  # the chunk
CHUNKACC["atime"]="" # Most recent access time for the chunk
CHUNKACC["ownerid"]="" # Owner UserID# typically > 2000 for
	                     # unprivileged users
CHUNKACC["groupid"]="" # Owner GroupID# typically > 2000 for
	                     # unprivileged users
CHUNKACC["perm"]="" # SetUserID, Set GroupID, Owner, Group, World
	                  # RWX permissions
declare -A MANI
MANI["chunktype"]="manifest" # The name of this type of chunk
MANI["prevmani"]="" # The hash of the previous Manifest for this object
MANI["back"]="" # The hash of the back reference chain
MANI["objlen"]="" # The length (in bytes) of the object, 128 bit integer
MANI["ctime"]="" # The creation time of the object (hash of the
	               # metadata?)
MANI["hash0"]="" # The hash of the first chunk of the object
MANI["off0"]="" # the offset of the first chunk (may be non-zero for
	               # sparse data)
MANI["hash1"]="" # The hash of the first chunk of the object
MANI["off1"]="" # the offset of the first chunk (may be non-zero for
	               # sparse data)
MANI["hash2"]="" # The hash of the first chunk of the object
MANI["off2"]="" # the offset of the first chunk (may be non-zero for
	               # sparse data)
MANI["hash3"]="" # The hash of the first chunk of the object
MANI["off3"]="" # the offset of the first chunk (may be non-zero for
	               # sparse data)
MANI["hash4"]="" # The hash of the first chunk of the object
MANI["off4"]="" # the offset of the first chunk (may be non-zero for
	               # sparse data)
MANI["hash5"]="" # The hash of the first chunk of the object
MANI["off5"]="" # the offset of the first chunk (may be non-zero for
	               # sparse data)
MANI["hash6"]="" # The hash of the first chunk of the object
MANI["off6"]="" # the offset of the first chunk (may be non-zero for
	               # sparse data)
MANI["hash7"]="" # The hash of the first chunk of the object
MANI["off7"]="" # the offset of the first chunk (may be non-zero for
	               # sparse data)
declare -A CHUNKMETA
CHUNKMETA["chunktype"]="chunkmeta" # The name of this type of object
CHUNKMETA["atime"]="" # The most recent chunk access time
CHUNKMETA["next"]="" # The hash of the previous access time chunkmeta
	                   # chunkmeta chunk
CHUNKMETA["meta"]="" # hash to other chunk affiliated metadata as of
	                   # this time
declare -A CHID
CHID["chunktype"]="chid" # The name of this type of object
CHID["back"]="" # The chunk ID of the first backreference
CHID["size"]="" # The size in bytes of the chunk

########################################################################
# The number of bits encoded by a hex digit
########################################################################
hexbits=4

########################################################################
# Suffixes
########################################################################
	# Chunk Hash ID, normally elided, absence implies this
export sufCHID=1
	# Name Hash ID
export sufNHID=2
	# Meta data affiliated with a chunk
export sufMETA=3
	# A back reference for a chunk.  These are speculative or confirmed
export sufBACK=4
	# A Manifest for an object
export sufMANI=5
	# Chunk Meta data
export sufCHUNKMETA=6
	# Chunk Access data
export sufCHUNKACCESS=7
	# Chunk Manifest
export sufCHUNKMANI=8
	# Name metadata
export NAMEMETA=9

declare -a SUFFIX
SUFFIX=( ${CHID} ${NHID} ${META} ${BACK} ${MANI} ${CHUNKMETA} \
	${CHUNKACCESS} ${CHUNKMANI} )
# CHID	# Chunk Hash ID, normally elided, absence implies this
# NHID	# Name Hash ID
# META	# Meta data affiliated with a chunk
# BACK	# A back reference for a chunk.  These are speculative or
# 	# confirmed
# MANI	# A Manifest for an object
# CHUNKMETA	# Chunk Meta data
# CHUNKACCESS	# Chunk Access data
# CHUNKMANI	# Chunk Manifest

########################################################################
# Descriptive names within YesFS metadata structures
########################################################################
# CHID Name Hash
########################################################################
SUFFIX[${CHID}]="CHID"
########################################################################
# META Name Hash
########################################################################
SUFFIX[${META}]="META"
########################################################################
# NHID Name Hash
########################################################################
SUFFIX[${NHID}]="NHID"
HASHTYPE="HASHTYPE"	# The internal identifier of this chunk as
			# meta-type
			# VALUE = "NHID"
LABELCHUNK="LABELCHUNK"	# The hash value of the chunk which holds the
			# string which is the object name
NAMECHUNK="NAMECHUNK"	# The hash of the object that the name refers
			# to.
MANIFEST="MANIFEST"	# Hash of the object manifest that the name
			# refers to
#NAMEMETA="NAMEMETA"	# Hash of the name-affiliated metadata (e.g.
			# owner,
			# group, permissions
########################################################################
# CHUNKMETA Metadata for a Chunk
########################################################################
SUFFIX[${sufCHUNKMETA}]="CHUNKMETA"
declare -A CHUNKMETA

CHUNKMETA[CHUNKMETAtime]=${timestamp}
CHUNKMETA[CHUNKMETAnext]=""
CHUNKMETA[CHUNKMETAmeta]="DUMMY"
SIZE="SIZE"		# The size of the chunk in bytes
BACKREF="BACKREF"	# The hashid of the most recent backreference
			# to the chunk
ACCESS="ACCESS"		# The hashid of the most recent access record
			# for the chunk
########################################################################
# CHUNKACCESS Metadata for a Chunk
########################################################################
SUFFIX[${CHUNKACCESS}]="CHUNKACCESS"
HASHTYPE="HASHTYPE"	# The internal identifier of this chunk as
			# meta-type VALUE = "CHUNKACCESS"
PREVIOUS="PREVIOUS"	# The hash of the previous access time record
			# for this chunk
ACCTIME="ACCTIME"	# The time stamp of the chunk in seconds since
			# the EPOCH
USERID="USERID"		# The user id on the system that accessed the
			# chunk
GROUPID="GROUPID"	# The group id on the system that accessed the
			# chunk
SYSTEMID="SYSTEMID"	# The system ID of the system that accessed the
			# chunk
########################################################################
# NAMEMETA Metadata for a NHID
########################################################################
SUFFIX[${NAMEMETA}]="NAMEMETA"
HASHTYPE="HASHTYPE"	# The internal identifier of this chunk as
			# meta-type VALUE = "NAMEMETA"
PREVIOUS="PREVIOUS"	# The has of the previous creation time record
			# for this name (necessary?)
PERMISSION="PERMISSION"	# The permissions in octal for the Read, Write,
			# eXecute permissions for trhe owner, group and
			# world access to the object this name refers
			# to.
USERID="USERID"		# The user id on the system that accessed the
			# chunk
GROUPID="GROUPID"	# The group id on the system that accessed the
			# chunk
SYSTEMID="SYSTEMID"	# The system ID of the system that accessed the
			# chunk
########################################################################
# BACKREF Metadata for a Chunk
########################################################################
SUFFIX[${BACK}]="BACK"
HASHTYPE="HASHTYPE"	# The internal identifier of this chunk as
			# meta-type VALUE = "BACK"
PREVIOUS="PREVIOUS"	# The hash of the previous backreference record
			# for this chunk
NEXT="NEXT"		# The hash of the next backreference record for
			# this chunk
NAMEHASH="NAMEHASH"	# The Name Hash ID of the first name that
			# refers to this object.
BACKTIME="BACKTIME"	# the time stamp of the creation of the
			# backreference record
SPEC="SPEC"		# Flag to indicate if this is a speculative
			# backref.  Initially set to TRUE, set to FALSE
			# upon completion of creating the Manifest for
			# this object.
########################################################################
# MANI Manifest Metadata for an object
########################################################################
SUFFIX[${MANI}]="MANI"
HASHTYPE="HASHTYPE"	# The internal identifier of this chunk as
			# meta-type VALUE = "MANI"
PREVIOUS="PREVIOUS"	# The hash of the previous manifest record
			# for this object
BACKREF="BACKREF"	# The hash of the back reference chain for this
			# object
VERSION="VERSION"	# The version number of the object (During a
			# Network partition, there may be duplicates of
			# this number created.  This requires scrub
			# auditing
MAJOR="MAJOR"		# The major version number of the manifest
			# format
MINOR="MINOR"		# The minor version number of the manifest
			# format For Major,Minor of {0,1} The max
			# count of internal
			# hashes is 8.  Subject to change over time
NAMECHUNK="NAMECHUNK"	# This is the hash of the entire object that
			# this manifest refers to.
SIZE="SIZE"		# The size of the object in bytes.  Note that
			# for # sparse objects this may be misleading.
CREATETIME="CREATETIME"	# The time that the manifest is created stored
			# as ISO 8601-2019:2 format
USEDHASHES="USEDHASHES"	# The number of hashes in use for this object.
			# If this value is set to zero, then the
			# remaining space in the manifest is used for
			# internal storage of a small object.
			# Given that OFFSETS are 64 bit numbers and
			# that in this human readable form, that is a
			# 20 digit decimal number, the internal space
			# available is 8*sizeof("OFFSET_0\t%20d\n") =
			# 240bytes plus 8*sizeof("HASH_0\t%128x\n")
			# =1088 + 240 = 1328 bytes of storage in
			# internal manifest storage

# Rethinking this entire section.  The in-memory version is an
# extensible array.  When written to storage, this is an array of
# size "USEDHASHES" that contains all of the pairs of offsets and
# chunk hashes.  This is on local store in the originating machine
# only.  As the manifest is prepared for "put" to other storage
# destinations, an isomorphic representation of this manifest may
# contain a tree of chunk manifests that can point to either other
# chunk manifests or at the leaves of the tree, the chunks that
# represent the object.
#
OFFSET_0=""		# Offset to the [0] chunk of the object
			# Note that in a sparse object, this may be
			# non-zero.  Since each of the chunks may be
			# Chunk Manifests, then there are no bounds on
			# the size of an object since an object may have
			# a tree of indefinite depth of chunk manifests
OFFSET_1=""		# Offset to the [1] chunk of the object
OFFSET_2=""		# Offset to the [2] chunk of the object
OFFSET_3=""		# Offset to the [3] chunk of the object
OFFSET_4=""		# Offset to the [4] chunk of the object
OFFSET_5=""		# Offset to the [5] chunk of the object
OFFSET_6=""		# Offset to the [6] chunk of the object
OFFSET_7=""		# Offset to the [7] chunk of the object
HASH_0=""		# HASH of the first [0] chunk of the object
HASH_1=""			# HASH of the [1] chunk of the object
HASH_2=""			# HASH of the [2] chunk of the object
HASH_3=""			# HASH of the [3] chunk of the object
HASH_4=""			# HASH of the [4] chunk of the object
HASH_5=""			# HASH of the [5] chunk of the object
HASH_6=""			# HASH of the [6] chunk of the object
HASH_7=""			# HASH of the [7] chunk of the object
########################################################################
# CHUNKMANI Manifest Metadata for an object
########################################################################
SUFFIX[${CHUNKMANI}]="CHUNKMANI"
HASHTYPE="HASHTYPE"	# The internal identifier of this chunk as
			# meta-type VALUE = "OBJMANI"
SIZE="SIZE"		# The size of the chunk in bytes
BACKREF="BACKREF"	# The hashid of the most recent backreference
			# to the chunk
ACCESS="ACCESS"		# The hashid of the most recent access record
			# for the chunk
MAJOR="MAJOR"		# The major version number of the object
			# manifest format
MINOR="MINOR"		# The minor version number of the object
			# manifest format. For Major,Minor of {0,1}
			# The count of internal hashes is 25.  Subject
			# to change over time
USEDHASHES="USEDHASHES"	# The number of hashes in use for this chunk
			# Manifest.
OFFSET_00=""		# Offset to the [00 chunk of the object
			# .
			# .
			# .
OFFSET_FF=""		# Offset to the [FF] chunk of the object
HASH_00=""		# HASH of the first [00] chunk of the object
			# .
			# .
			# .
HASH_FF=""		# HASH of the first [FF] chunk of the object

fi # if [ -z "${__yfunc_global}" ]
