#!/bin/bash

# OLE SRU test:
# searchRetrieve parameter startRecord conforms to spec
# https://jira.kuali.org/browse/OLETS-953

ME=`basename $0 .sh`
AUTHOR="Tod Olson"
# Much is stolen shamelessly from scripts by Keith Waclena
#WWW=http://www.lib.uchicago.edu/tod/
# NYI
#VERSION=VERSION		# replaced with mercurial version number by make

# START CONFIGURE
SRU_HOST=${SRU_HOST:-http://tst.docstore.ole.kuali.org}
TMP_DIR=${TMP_DIR:-/tmp}
# END CONFIGURE

USAGE="Usage: $ME [-t] ; -H for help"
HELP="This is $ME $VERSION by $AUTHOR <$WWW>

 -T test mode (developer only)"
TAB="$(echo -n x | tr x '\011')"

TESTING=false

# prerequisites

prereqs ()
{
   satisfied=
   missing=
   for p in $@
   do
	if type "$p" > /dev/null 2>&1
	then satisfied="$satisfied|  $p${TAB}$(which $p)"
	else
	    missing="$missing  $p"
	fi
   done
   if [ "$missing" != "" ]
   then
       (
	    echo "$ME: missing prerequisites:"
	    echo "$missing"
	    echo -n "$ME: satisfied prerequisites:"
	    echo "$satisfied" | tr \| '\012'
	) >&2
       exit 69
   else : ok
   fi
}

noreq ()
{
   fatal "DRYROT: missing prerequisite!"
}

choosereq ()
{
   for p in $@ noreq
   do
       if type "$p" > /dev/null 2>&1
	then echo "$p"; return 0
	else :
	fi
   done
}

prereqs mktemp curl

# handy functions

usage () {
   echo "$USAGE" 1>&2
   case "$1" in
   '') ;;
   0)  exit 0 ;;
   *)  exit "$1" ;;
   esac
}

nyi () {
   echo "$1: not yet implemented" 1>&2
   exit 2
}

warning () {
   echo "$*" 1>&2
}

fatal () {
   if expr "$1" : '[0-9][0-9]*$' > /dev/null
   then X=$1; shift
   else X=1
   fi
   echo "$*" 1>&2
   exit $X
}

prefix () {
   if $TESTING
   then echo "TEST$1"
   else echo "$1"
   fi
}

while true
do
   case "$1" in
   -H)     shift; usage 0 ;;
   -t)     shift; TESTING=true ;;
   --)     shift; break ;;
   -)      break ;;
   -*)     usage 1 ;;
   *)      break ;;
   esac
done


NUM_FAILED=0

failure () {
   NUM_FAILED=$(($NUM_FAILED + 1))
   echo "FAILED: $*" 1>&2
}

##
#
# Temp file helpers
#
# Is there a better way in the shell to deal with tmp files?
# Maybe create a temp dir that all tmp files go into an just
# clean up that directory

declare -a tmp_files

# Register a temp file for deletion when script ends
add_tmp_file () {
    tmp_files[${#tmp_files[@]}]=$1
}

# Remove all temp files
cleanup () {
    for f in "${tmp_files[@]}"
    do
        rm -f $f
    done
}


##
#
# TESTS
#

#
# Test that startRecord = 0 really gives an error
#
# DANGER: depends on set of test records
#

test_startRecord_0 () {
    # Direct URL for searching title=test and author="Keith Welch"
    # should have exactly 1 result
    URL=${SRU_HOST}'/sru?version=1.2&operation=searchRetrieve&query=history&startRecord=0&maximumRecords=0&recordSchema=marcxml'

    STARTRECORD_0_XML=${TMP_DIR}/srutest-startRecord_0_$$.xml
    add_tmp_file $STARTRECORD_0_XML

    if curl -s -S --write-out '<!-- http_code=%{http_code} -->' $URL > $STARTRECORD_0_XML
    then
        if grep '<[a-zA-Z]*:numberOfRecords>' $STARTRECORD_0_XML >/dev/null
        then
            failure "startRecord = 0 should return a diagnotic"
        else
            return
        fi
    else
        fatal "Failed to retrieve $URL"
    fi
}

#
# Test that startRecord = 1 really gets the first record
# Use a query that should return one record startRecord = 1
#
# DANGER: depends on set of test records
#

test_startRecord_1 () {
    # Direct URL for searching title=test and author="Keith Welch"
    # should have exactly 1 result
    URL=${SRU_HOST}'/sru?version=1.2&operation=searchRetrieve&query=title%3Dtest%20and%20author%3D%22Keith%20Welch%22&startRecord=1&maximumRecords=1&recordSchema=marcxml'

    STARTRECORD_1_XML=${TMP_DIR}/srutest-startRecord_1_$$.xml
    add_tmp_file $STARTRECORD_1_XML

    if curl -s -S --write-out '<!-- http_code=%{http_code} -->' $URL > $STARTRECORD_1_XML
    then
        if grep '<diagnostic>' $STARTRECORD_1_XML >/dev/null
        then
            failure "startRecord = 1 does not return first record; diagnostic: " $(sed -n -e '/<diagnostic>/,/<\/diagnostic>/p' $STARTRECORD_1_XML)
        else
            return
        fi
    else
        fatal "Failed to retrieve $URL"
    fi
}

# main

trap 'exit 3' 1 2 3 15
trap cleanup 0

if $TESTING
then PREFIX=TEST
else PREFIX=DATA
fi

test_startRecord_0
test_startRecord_1

if [ $NUM_FAILED -gt 0 ]
then
    echo $NUM_FAILED tests failed
    exit 1
fi

# Local Variables:
# End:
