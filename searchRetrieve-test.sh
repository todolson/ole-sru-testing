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

    tmp_file=${TMP_DIR}/srutest-version-required-$$.xml
    add_tmp_file $tmp_file

    if ! curl -s -S --write-out '<!-- http_code=%{http_code} -->' $URL > $tmp_file
    then
        fatal "Failed to retrieve $URL"
	return
    fi

    #
    # validate according to reported version
    #
    local response_version="$(xsltproc xslt/get_sru_version.xslt $tmp_file)"
    echo "Response version: $response_version"
    if ! set_sru_schema "${response_version}"
    then
	failure "Unrecognized SRU version"
	return
    fi
    if ! xmllint --noout --schema ${SRU_SCHEMA} $tmp_file
    then
	failure "search response failed to validate"
	return
    fi

    #
    # Check content errors:
    #

    local -a content_errors

    #
    # Fatal diagnostic requires number of results = 0
    #
    local numRecs
    numRecs=$(xsltproc xslt/get_num_records.xslt $tmp_file)
    status=$?
    if [ $status -ne 0 ]
    then
	failure "Could not get number of records, check URL response content"
    elif [ $numRecs -ne 0 ]
    then
	content_errors[0]="Fatal diagnostic: numberOfRecords should be 0, but was $numRecs"
    fi
    #
    # Check diagnostic content
    #
    local diag_uri='info:srw/diagnostic/1/7'
    local diag_details='version'
    local diag_message='Mandatory parameter is missing'
    #
    # Leverage format of output text to set local variables
    #
    . <(xsltproc xslt/get_diagnostic_as_test.xslt $tmp_file |  sed -n '/^[A-Z_a-z]*=/s/^/local my_/p')
    
    if [ "$my_uri" != "$diag_uri"]
    then
	content_errors[1]="Diagnostic uri: expected '$diag_uri'"
    fi
    if [ "$my_details" != "$diag_details"]
    then
	content_errors[2]="Diagnostic details: expected '$diag_details'"
    fi
    if [ "$my_message" != "$diag_message"]
    then
	content_errors[3]="Diagnostic message: expected '$diag_message'"
    fi
    if [ ${#content_errors[@]} -ne 0 ]
    then
	local msg=$(printf "%s\n" "Content problems:" ${content_errors[*]})
	failure "$msg"
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
# Check for schema conformance
# Takes different arguments, checks both response container and recordData contents
#
SCHEMA_CONFORMANCE_COUNTER=${SCHEMA_CONFORMANCE_COUNTER:=0}
test_schema_conformance() {
    local q="$1"
    local record_schema="$2"

    test_env_init
    QUERY=$(rawurlencode "$q")
    RECORD_SCHEMA=${record_schema}
    sru_url
    echo "query: $q; in record schema $RECORD_SCHEMA"
    echo "URL = $URL"
    
    tmp_file=${TMP_DIR}/schema_conformance_${SCHEMA_CONFORMANCE_COUNTER}_$$.xml
    #add_tmp_file $tmp_file
    SCHEMA_CONFORMANCE_COUNTER=$((${SCHEMA_CONFORMANCE_COUNTER} + 1))

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

    # xmllint only takes one schema argument at a time (last --schema wins),
    # so must take this apart by steps

    if ! xmllint --noout --schema ${SRU_SCHEMA} $tmp_file
    then
	failure "Error validating SRU response"
	return
    fi

    local tmp_file_record_data="$(dirname $tmp_file)/$(basename -s .xml $tmp_file)_record_data.xml"
    local status
    xsltproc xslt/get_record_data.xslt $tmp_file > $tmp_file_record_data
    status=$?
    #add_tmp_file $tmp_file_record_data
    echo $tmp_file_record_data
    if [ $status -eq 10 ]
    then
	failure "XSLT fatal message"
	cat $tmp_file_record_data
	return
    fi
    
    local record_schema_xsd=""
    case "$record_schema" in
	OPAC)
	    record_schema_xsd=xsd/opacxml.xsd;;
	marcxml)
	    record_schema_xsd=xsd/MARC21slim.xsd;;
	*)
	    dryrot "unknown record schema: $record_schema";;
    esac
    if ! xmllint --noout --schema ${record_schema_xsd} $tmp_file_record_data
    then
	failure "Error validating record data in SRU response: ${record_schema}"
    fi
    
}


#
# Check for OPAC contents
#
OPAC_COUNTER=${OPAC_COUNTER:=0}
test_opac_barcode() {
    local q="$1"
    local barcode_expected="$2"

    test_env_init
    QUERY=$(rawurlencode "$q")
    sru_url
    echo "query: $q"
    echo "URL = $URL"
    
    tmp_file=${TMP_DIR}/opac_barcode_${OPAC_COUNTER}_$$.xml
    #add_tmp_file $tmp_file
    OPAC_COUNTER=$((${OPAC_COUNTER} + 1))

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

    local barcode_returned
    barcode_returned=$(xsltproc xslt/get_barcode.xslt $tmp_file)
    if [ -z "$barcode_returned" ]
    then
	failure "Barcode not found in query $q"
    elif [ "$barcode_returned" != "$barcode_expected"]
    then
	failure "Barcode returned != Barcode expected: $barcode_returned != $barcode_expected"
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
    #MAX_RECS=0
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
    echo "q = $q"
    echo "QUERY = $QUERY"
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

#
# Generic search test expecting success
#
test_search_success () {
    return
}


LOCAL_ID_COUNTER=${LOCAL_ID_COUNTER:=0}
test_localId_success () {
    local localId="$1"
    local title="$2"
    local q="localId=${localId}"

    test_env_init
    QUERY=$(rawurlencode "$q")
    sru_url
    echo "q = $q"
    echo "QUERY = $QUERY"
    echo "URL = $URL"

    local tmp_file=${TMP_DIR}/local_id_${LOCAL_ID_COUNTER}_$$.xml
    add_tmp_file $tmp_file
    LOCAL_ID_COUNTER=$((${LOCAL_ID_COUNTER} + 1))

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
    elif [ $numRecs -eq 0 ]
    then
	failure "no matches for query $q"
    elif [ $numRecs -gt 1 ]
    then
	failure "$numRecs matches, expected 1 for query $q"
    else
	local ret001=$(xsltproc xslt/get_001.xslt $tmp_file)
	if [ $ret001 != $localId ]
	then
	    failure "Returned record does not match requested record: $ret001 != $localId"
	fi
    fi

}

#
# Test local Id queries that should fail
#
test_localId_fail () {
    local localId="$1"
    local q="localId=${localId}"

    test_env_init
    QUERY=$(rawurlencode "$q")
    sru_url
    echo "q = $q"
    echo "QUERY = $QUERY"
    echo "URL = $URL"

    local tmp_file=${TMP_DIR}/local_id_${LOCAL_ID_COUNTER}_$$.xml
    add_tmp_file $tmp_file
    UNSUP_Q_COUNTER=$((${LOCAL_ID_COUNTER} + 1))

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
	failure "Could not parse response for query: $q"
    elif [ -n "$numRecs" && "$numRecs" != 0 ]
    then
	failure "expected no results for query $q, found $numRecs matches"
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
echo '### Testing schema conformance'
echo
test_schema_conformance 'localId=16' marcxml
test_schema_conformance 'localId=16' OPAC
echo
echo '### Testing OPAC contents'
echo
test_opac_barcode 'localId=wbm-121' 'mq6641488'
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
echo
echo '### Testing search by localId'
echo
test_localId_success '121' 'Death of a pirate :'
test_localId_success '16' 'PIRATE HUNTING : THE FIGHT AGAINST PIRATES, PRIVATEERS, AND SEA RAIDERS FROM ANTIQUITY TO THE PRESENT'
test_localId_success '114' 'The cultures of Maimonideanism :'
test_localId_success '109' 'Death at the fair /'
test_localId_success 'wbm-123' 'Cornelii Jansenii Episcopi gandavensis Paraphrasis in omnes Psalmos Davidicos, cum argumentis et annotationibus :'
test_localId_fail '11234124312431214243'
test_localId_fail '112-12'
test_localId_fail '11*12'
test_localId_fail '123'


if [ $NUM_FAILED -gt 0 ]
then
    echo $NUM_FAILED tests failed
    exit 1
fi

# Local Variables:
# End:
