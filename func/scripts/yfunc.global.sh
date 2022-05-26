#!/bin/bash
if [ -z "${__yfunc_global}" ]
then
	export __yfunc_global=1

  source func.regex

########################################################################
# Global Strings used in YesFS data structures
#
# In this first implementation system data structures are represented
# files in the form of <hashname>.<suffix> where hashname is the
# cryptographic hash of the chunk with which metadata is defined.
# Suffix is the abbreviation for the metadata structure which holds
# information about the chunk. A file that is simply <hashname>, a 128
# ASCII HEX encoded name for a 256-bit {8 byte} cryptographic hash.
#
# The file system information is stored in a directory similar to the
# "tank" of ZFS.  The default root is a named root and is YesFS if not
# otherwise specified.
#
# In order to keep directories from growing too large, there is a
# directory tree which divides the files into directories so that no
# single directory will be more than ~100,000 files per directory
#
# Directory name uses 4 bytes of the ASCII encoding of the hash name,
# starting at the most significant bits of the hash name string.
#
# File systems with less than 65,536 files (256^2) will have one level
# of directories.  File systems with less than 16,777,216 files will
# have two levels of directories.  Files systems with less
# than 4,294,967,296 files (256^4) with have three levels of
# directories... and so on.
#
# At the time that a chunk is created, the name, the type and the name
# of the cryptographic hash function are logged in the CHUNKLOG
#
########################################################################
YESFS=/YesFS
HASHES=${YESFS}/.hash
CHUNKLOG=${YESFS}/.chunklog
FAILEDTOHASH_string="Failed to hash \`"

FILECOUNT_lock="${TESTDIR}/FILECOUNT.lock"
FILECOUNT_file="${TESTDIR}/FILECOUNT.file"

####################	
# This timestamp will create a new time stamp each
# time it is referenced.  The Time stamp is represented
# in the format of the ISO 8601-2:2019 interchange format
#
# By removing the '\' at the beginning of the string
# this would become a single timestamp for all elements
# of the object creation, which may be desirable.
#
# This should be in the format of the AWS S3 timestamp
####################	
timestamp="\$(date -u -Ins)"

b2len=128
b2file=130

########################################################################
# Suffixes
########################################################################
  # Chunk Hash ID, normally elided, absence implies this
CHID=1
  # Name Hash ID
NHID=2
  # Meta data affiliated with a chunk
META=3
  # A back reference for a chunk.  These are speculative or confirmed
BACK=4
  # A Manifest for an object
MANI=5
  # Chunk Meta data
CHUNKMETA=6
  # Chunk Access data
CHUNKACCESS=7
  # Chunk Manifest
CHUNKMANI=8
  # Name metadata
NAMEMETA=9

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
SUFFIX[${CHUNKMETA}]="CHUNKMETA"
HASHTYPE="HASHTYPE"	# The internal identifier of this chunk as
			# meta-type VALUE = "CHUNKMETA"
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
# size "USEDHASHES" that contains all fo the pairs of offsets and
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
			# These numbers are represented by up to 20
			# character decimal numbers
OFFSET_1		# Offset to the [1] chunk of the object
OFFSET_2		# Offset to the [2] chunk of the object
OFFSET_3		# Offset to the [3] chunk of the object
OFFSET_4		# Offset to the [4] chunk of the object
OFFSET_5		# Offset to the [5] chunk of the object
OFFSET_6		# Offset to the [6] chunk of the object
OFFSET_7		# Offset to the [7] chunk of the object
HASH_0=""		# HASH of the first [0] chunk of the object
HASH_1			# HASH of the [1] chunk of the object
HASH_2			# HASH of the [2] chunk of the object
HASH_3			# HASH of the [3] chunk of the object
HASH_4			# HASH of the [4] chunk of the object
HASH_5			# HASH of the [5] chunk of the object
HASH_6			# HASH of the [6] chunk of the object
HASH_7			# HASH of the [7] chunk of the object
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

