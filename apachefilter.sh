#!/bin/bash

DOMAIN='.'
IP='.'
DATE='.'
METHOD='.'
FILE='.'
STATUS='.'
USER_AGENT='.'
REFERER='.'

KEEP_QUERY=0
THRESHOLD=0
LOGS='/home/*/access-logs/*'
RAW_OUTPUT=0
OUTPUTS=$(((1 << 16) - 1))

# Parse arguments
ARGS=$(getopt --options "ro:" --longoptions "domain:,ip:,date:,method:,file:,status:,user-agent:,keep-query,threshold:,raw,outputs:,referer:,referrer:" -- "$@")
if [[ $? -gt 0 ]]; then
	exit 1
fi
eval set -- "$ARGS"
while true; do
	case "$1" in
	--domain)             DOMAIN="$2"     ;;
	--ip)                 IP="$2"         ;;
	--date)               DATE="$2"       ;;
	--method)             METHOD="$2"     ;;
	--file)               FILE="$2"       ;;
	--status)             STATUS="$2"     ;;
	--referer|--referrer) REFERER="$2"    ;;
	--user-agent)         USER_AGENT="$2" ;;
	--keep-query)         KEEP_QUERY=1    ;;
	--threshold)          THRESHOLD="$2"  ;;
	-r|--raw)             RAW_OUTPUT=1    ;;
	-o|--outputs)         OUTPUTS="$2"    ;;
	# End of 'getopt'
	--) break ;;
	esac
	shift
done

OUTPUT=$(for LOG in $LOGS
do
	if [[ $LOG != *$DOMAIN* ]]; then
		continue
	fi

	# Get Domain / URL
	URL=$(ls $LOG | awk -F '/' '{ if ($NF ~ "ssl_log") print "https://"$NF; else print "http://"$NF }' | sed 's/-ssl_log//' | sed 's/-.*\.gz//')

	# Read LOG contents into INPUT variable
	if [[ $LOG == *.gz ]]; then
		INPUT=$(zcat $LOG)
	else
		INPUT=$(cat $LOG)
	fi
	
	# Extract data from INPUT and format into pipe-separated OUTPUT
	echo "$INPUT" |
	awk -v OFS='|' -v FPAT='\\[[^]]*]|"[^"]*"|\\S+' -v IGNORECASE=1 -v ip=$IP -v date=$DATE -v method=$METHOD -v file=$FILE -v status=$STATUS -v referer=$REFERER -v ua=$USER_AGENT -v url=$URL -v kq=$KEEP_QUERY '{
		split($4, arrDateTime, " ");
		split(arrDateTime[1], arrDate, ":");
		split($5, arrRequest, " ");
		gsub("^https?:\\/\\/", "", arrRequest[2]);
		split(arrRequest[2], arrFile, "\\?");
		if ($1 ~ ip && arrDateTime[1] ~ date && arrRequest[1] ~ method && arrRequest[2] ~ file && $6 ~ status && $8 ~ referer && $9 ~ ua) {
			# IP|Date|Method|Status|URL|Referer|User-Agent
			(kq) ? outFile = arrRequest[2] : outFile = arrFile[1];
			gsub("/+", "/", outFile);
			print $1,arrDate[1],arrRequest[1],$6,url outFile,$8,$9;
		}
	}' | sed 's/\[//' | sed 's/"//'
done)

if [[ RAW_OUTPUT -gt 0 ]]; then
	echo "$OUTPUT"
else
    HEADERS="Count"
    if ((($OUTPUTS & (1 << 0))) > 0); then HEADERS="$HEADERS IP"; fi
    if ((($OUTPUTS & (1 << 1))) > 0); then HEADERS="$HEADERS Date"; fi
    if ((($OUTPUTS & (1 << 2))) > 0); then HEADERS="$HEADERS Method"; fi
    if ((($OUTPUTS & (1 << 3))) > 0); then HEADERS="$HEADERS Status"; fi
    if ((($OUTPUTS & (1 << 4))) > 0); then HEADERS="$HEADERS URL"; fi
    if ((($OUTPUTS & (1 << 5))) > 0); then HEADERS="$HEADERS Referer"; fi
    
	echo "$OUTPUT" | awk -F '|' -v outputs=$OUTPUTS '{
        out="";
        if (and(outputs, lshift(1, 0)) > 0) { out=$1" "; }
        if (and(outputs, lshift(1, 1)) > 0) { out=out$2" "; }
        if (and(outputs, lshift(1, 2)) > 0) { out=out$3" "; }
        if (and(outputs, lshift(1, 3)) > 0) { out=out$4" "; }
        if (and(outputs, lshift(1, 4)) > 0) { out=out$5" "; }
        if (and(outputs, lshift(1, 5)) > 0) { out=out$6; }
        print out;
    }' |
	sort | uniq -c | awk -v threshold=$THRESHOLD '$1 >= threshold' |
	(echo "$HEADERS"; sort -h | if [[ $THRESHOLD -lt 1 ]]; then tail -n 20; else cat; fi) | column -t;
fi
