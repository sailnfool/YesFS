#!/bin/bash
################################################################################
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
# Directory name use 2 bytes of the ASCII encoding of the hash name,
# starting at the most significant bits of the hash name string.
#
# File systems with less than 65,536 files (256^2) will have one level of
# directories.  File systems with less than 16,777,216 files will have
# two levels of directories.  Files systems with less than 4,294,967,296
# files (256^4) with have three levels of directories... and so on.
#
# At the time that a chunk is created, the name, the type and the name
# of the cryptographic hash function are logged in the CHUNKLOG
#
################################################################################
YESFS=/YesFS
HASHES=${YESFS}/.hash
CHUNKLOG=${YESFS}/.chunklog

################################################################################
# Suffixes
################################################################################
NHID	# Name Hash ID
META	# Meta data affiliated with a chunk
CHID	# Chunk Hash ID, normally elided, absence implies this
BACK	# A back reference for a chunk.  These are speculative or confirmed

################################################################################
# Descriptive names within YesFS metadata structures
################################################################################
