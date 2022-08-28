#!/bin/bash

DOMAIN='.'
IP='.'
DATE='.'
METHOD='.'
FILE='.'
STATUS='.'
USER_AGENT='.'

KEEP_QUERY=0
THRESHOLD=0
LOGS='/home/*/access-logs/*'

# Parse arguments
ARGS=$(getopt --options '' --longoptions "domain:,ip:,date:,method:,file:,status:,user-agent:,keep-query,threshold:" -- "$@")
if [[ $? -gt 0 ]]; then
	exit 1
fi
eval set -- "$ARGS"
while true; do
	case "$1" in
	--domain)     DOMAIN="$2"     ;;
	--ip)         IP="$2"         ;;
	--date)       DATE="$2"       ;;
	--method)     METHOD="$2"     ;;
	--file)       FILE="$2"       ;;
	--status)     STATUS="$2"     ;;
	--user-agent) USER_AGENT="$2" ;;
	--keep-query) KEEP_QUERY=1    ;;
	--threshold)  THRESHOLD="$2"  ;;
	# End of 'getopt'
	--) break ;;
	esac
	shift
done

for LOG in $LOGS
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
	OUTPUT=$(echo "$INPUT" | sed 's/\/\///g' |
	awk -v OFS='|' -v FPAT='\\[[^]]*]|"[^"]*"|\\S+' -v IGNORECASE=1 -v ip=$IP -v date=$DATE -v method=$METHOD -v file=$FILE -v status=$STATUS -v ua=$USER_AGENT -v url=$URL -v kq=$KEEP_QUERY '{
		split($4, arrDateTime, " ");
		split(arrDateTime[1], arrDate, ":");
		split($5, arrRequest, " ");
		split(arrRequest[2], arrFile, "\\?[a-zA-Z0-9]");
		if ($1 ~ ip && arrDateTime[1] ~ date && arrRequest[1] ~ method && arrRequest[2] ~ file && $6 ~ status && $9 ~ ua) {
			# IP|Date|Method|URL|Status|User-Agent
			(kq) ? outFile = arrRequest[2] : outFile = arrFile[1];
			if (arrRequest[2] ~ /^https?:\/\//)
				print $1,arrDate[1],arrRequest[1],outFile,$6,$9;
			else
				print $1,arrDate[1],arrRequest[1],url outFile,$6,$9;
		}
	}')
	if [[ -n $OUTPUT ]]; then
		echo "$OUTPUT" | sed 's/\[//' | sed 's/"//'
	fi
done | awk -F '|' '{ print $1,$3,$5,$4 }' |
sort | uniq -c | awk -v threshold=$THRESHOLD '$1 >= threshold' |
(echo "Count IP Method Status URL"; sort -h | if [[ $THRESHOLD -lt 1 ]]; then tail -n 20; fi) | column -t;
