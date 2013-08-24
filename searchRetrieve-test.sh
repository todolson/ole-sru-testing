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
SRU_BASE="${SRU_HOST}/sru"
echo "TEMPORARY hack: use SRU 1.1 until development switched namespaces - TAO 2013-08-23"
SRU_VERSION_DFLT=1.1
#SRU_VERSION_DFLT=1.2

SRU_1_1_SCHEMA=xsd/srw/srw-types.xsd
SRU_1_2_SCHEMA=xsd/search-ws/sruResponse.xsd

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

prereqs mktemp curl xmllint xsltproc perl

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

#
# Test support functions
#

NUM_FAILED=0

failure () {
   NUM_FAILED=$(($NUM_FAILED + 1))
   echo "FAILED: $*" 1>&2
   echo 1>&2
}

#
# Set up some basic environement for any test
#
test_env_init() {
    SRU_VERSION=$SRU_VERSION_DFLT
    OPERATION=searchRetrieve
    RECORD_SCHEMA=marcxml
    unset URL
    unset MAX_RECS
    unset START_REC
    unset QUERY
}

#
# Construct an SRU URL based on environemt variables
#
sru_url() {
URL="${SRU_BASE}?operation=${OPERATION}"
if [ ! -z "$SRU_VERSION" ]
then
    URL="${URL}&version=${SRU_VERSION}"
fi
if [ ! -z "$MAX_RECS" ]
then
    URL="${URL}&maximumRecords=${MAX_RECS}"
fi
if [ ! -z "$START_REC" ]
then
    URL="${URL}&startRecord=${START_REC}"
fi
if [ ! -z "$QUERY" ]
then
    URL="${URL}&query=${QUERY}"
fi
if [ ! -z "$RECORD_SCHEMA" ]
then
    URL="${URL}&recordSchema=${RECORD_SCHEMA}"
fi
}

#
# echo the schema file to use for validation
#
get_sru_schema() {
    local sru_version=""
    case "$1" in
	"1.1" )
	    sru_schema="$SRU_1_1_SCHEMA";;
	"1.2" )
	    sru_schema="$SRU_1_2_SCHEMA";;
    esac
    echo ${sru_schema}
}

#
# set $SRU_SCHEMA the schema file to use for validation
#
set_sru_schema() {
    case "$1" in
	"1.1" )
	    SRU_SCHEMA="$SRU_1_1_SCHEMA";;
	"1.2" )
	    SRU_SCHEMA="$SRU_1_2_SCHEMA";;
	*)
	    SRU_SCHEMA=""
	    return 1;;
    esac
    return 0
}

#
# URL-encode first argument
#
# Taken from 
# http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script
#
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
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
    test_env_init
    QUERY=history
    START_REC=0
    sru_url
    echo "URL = $URL"
    
    local tmp_file=${TMP_DIR}/srutest-startRecord_0_$$.xml
    add_tmp_file $tmp_file

    if curl -s -S --write-out '<!-- http_code=%{http_code} -->' $URL > $tmp_file
    then
        if grep '<[a-zA-Z]*:numberOfRecords>' $tmp_file >/dev/null
        then
            failure "startRecord = 0 should return a diagnotic"
        else
            return
        fi
    else
        failure "Failed to retrieve URL"
    fi
}

#
# Test that startRecord = 1 really gets the first record
# Use a query that should return one record startRecord = 1
#
# DANGER: depends on set of test records
#

test_startRecord_1 () {
    test_env_init
    # query for record wbm-13 (001 in general keyword) should have
    # exactly 1 result
    QUERY=wbm-13
    START_REC=1
    sru_url
    echo "URL = $URL"

    local tmp_file=${TMP_DIR}/srutest-startRecord_1_$$.xml
    add_tmp_file $tmp_file

    if curl -s -S --write-out '<!-- http_code=%{http_code} -->' $URL > $tmp_file
    then
        if grep '<diagnostic>' $tmp_file >/dev/null
        then
            failure "startRecord = 1 does not return first record; diagnostic: " $(sed -n -e '/<diagnostic>/,/<\/diagnostic>/p' $tmp_file)
        else
            return
        fi
    else
        fatal "Failed to retrieve $URL"
    fi
}

#
# Check that a missing version parameter triggers an appropriate message
#
test_version_missing () {
    test_env_init
    unset SRU_VERSION
    QUERY=history
    MAX_RECS=0
    sru_url
    echo "URL = $URL"

#    URL=${SRU_HOST}'/sru?operation=searchRetrieve&query=history&startRecord=1&maximumRecords=0&recordSchema=marcxml'

    tmp_file=${TMP_DIR}/srutest-version-required-$$.xml
    add_tmp_file $tmp_file

    if ! curl -s -S --write-out '<!-- http_code=%{http_code} -->' $URL > $tmp_file
    then
        fatal "Failed to retrieve $URL"
	return
    fi

    if ! grep '<[a-zA-Z]*:diagnostics>' $tmp_file >/dev/null
    then
        failure "missing version parameter should return a diagnotic"
    elif ! grep 'Mandatory parameter not supplied' $tmp_file >/dev/null
    then 
	failure "missing version parameter should trigger diagnostic info:srw/diagnostic/1/7, 'Mandatory parameter not supplied'"
    fi
}

#
# Check what happens when we ask for version=1.1
#
test_version_1_1 () {
    test_env_init
    SRU_VERSION=1.1
    QUERY=history
    MAX_RECS=0
    sru_url
    echo "URL = $URL"
    
    tmp_file=${TMP_DIR}/srutest-version_1_1_$$.xml
    add_tmp_file $tmp_file

    if ! curl -s -S --write-out '<!-- http_code=%{http_code} -->' $URL > $tmp_file
    then
        fatal "Failed to retrieve $URL"
	return
    fi

    local response_version="$(xsltproc xslt/get_sru_version.xslt $tmp_file)"
    echo "Response version: $response_version"
    if ! set_sru_schema "${response_version}"
    then
	failure "Unrecognized SRU version"
	return
    fi

    #
    # TODO: check for diagnostic if version is not supported
    #
    # for example, see:
    # http://z3950.loc.gov:7090/voyager?version=1.2&operation=searchRetrieve&query=dinosaur

    if ! xmllint --noout --schema ${SRU_SCHEMA} $tmp_file
    then
	failure "search response failed to validate"
	return
    fi

}

#
# Check what happens when we ask for version=1.2
#
test_version_1_2 () {
    test_env_init
    SRU_VERSION=1.2
    QUERY=history
    MAX_RECS=0
    sru_url
    echo "URL = $URL"

    local tmp_file=${TMP_DIR}/srutest-version_1_2_$$.xml
    add_tmp_file $tmp_file

    if ! curl -s -S --write-out '<!-- http_code=%{http_code} -->' $URL > $tmp_file
    then
        fatal "Failed to retrieve $URL"
	return
    fi

    local response_version="$(xsltproc xslt/get_sru_version.xslt $tmp_file)"
    echo "Response version: $response_version"
    if ! set_sru_schema "${response_version}"
    then
	failure "Unrecognized SRU version"
	return
    fi

    #
    # TODO: check for diagnostic if version is not supported
    #
    # for example, see:
    # http://z3950.loc.gov:7090/voyager?version=1.2&operation=searchRetrieve&query=dinosaur

    if ! xmllint --noout --schema ${SRU_SCHEMA} $tmp_file
    then
	failure "search response failed to validate
  URL=$URL"
	return
    fi

}

#
# Test CQL Level 0 compliance
#
STQ_COUNTER=${STQ_COUNTER:=0}
test_cql_level_0_single_term_query () {
    local q="$1"
    test_env_init
    QUERY=$(rawurlencode "$q")
    MAX_RECS=0
    sru_url
    echo "URL = $URL"

    local tmp_file=${TMP_DIR}/cql_level_0_single_term_${STQ_COUNTER}_$$.xml
    add_tmp_file $tmp_file
    STQ_COUNTER=$((${STQ_COUNTER} + 1))

    if ! curl -s -S --write-out '<!-- http_code=%{http_code} -->' $URL > $tmp_file
    then
        fatal "Failed to retrieve $URL"
	return
    fi

    # NOTE: must get this sequence right, otherwise can alter $? before
    # before saving xsltproc status
    local numRecs
    local status
    numRecs=$(xsltproc xslt/get_num_records.xslt $tmp_file)
    status=$?
    if [ $status -ne 0 ]
    then
	failure "Could not handle query: $q"
    fi
}

UNSUP_Q_COUNTER=${UNSUP_Q_COUNTER:=0}
test_cql_level_0_unsupported_query () {
    local q="$1"
    test_env_init
    QUERY=$(rawurlencode "$q")
    MAX_RECS=0
    sru_url
    echo "URL = $URL"

    local tmp_file=${TMP_DIR}/cql_level_0_unsupported_${UNSUP_Q_COUNTER}_$$.xml
    add_tmp_file $tmp_file
    UNSUP_Q_COUNTER=$((${UNSUP_Q_COUNTER} + 1))

    if ! curl -s -S --write-out '<!-- http_code=%{http_code} -->' $URL > $tmp_file
    then
        fatal "Failed to retrieve $URL"
	return
    fi

    # NOTE: must get this sequence right, otherwise can alter $? before
    # before saving xsltproc status
    local numRecs
    local status
    numRecs=$(xsltproc xslt/get_num_records.xslt $tmp_file)
    status=$?
    if [ $status -ne 10 ]
    then
	failure "Query should have generated a message: $q"
    fi
}



# main

trap 'exit 3' 1 2 3 15
trap cleanup 0

if $TESTING
then PREFIX=TEST
else PREFIX=DATA
fi

echo
echo '### Testing SRU parameter startRecord'
echo
test_startRecord_0
test_startRecord_1
echo
echo '### Testing SRU parameter version'
echo
test_version_missing
test_version_1_1
test_version_1_2
echo
echo '### Testing CQL Level 0'
echo
single_term_query=(
    'history'
    'pirate'
    '"history"'
    '"death at the fair"'
    '"death fair"'
    '"\"death\" fair"'
    '"death mcnamara"'
)
for Q in "${single_term_query[@]}"
do
    test_cql_level_0_single_term_query "$Q"
done
unsupported_query=(
    '"death \"mcnamara"'
    '"death pirate" prox/unit=word'
    'dc.title any death prox/unit=word/distance>3 dc.title any pirate'
)
for Q in "${unsupported_query[@]}"
do
    test_cql_level_0_unsupported_query "$Q"
done

if [ $NUM_FAILED -gt 0 ]
then
    echo $NUM_FAILED tests failed
    exit 1
fi

# Local Variables:
# End:
