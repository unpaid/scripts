# Scripts

### [apachefilter.sh](apachefilter.sh)
Filter Apache access logs

Command line options are as follows:
```
[--domain] <domain name>            (Filter by domain name)
[--ip] <IP address>                 (Filter by IP address)
[--date] <dd/MMM/yyyy:HH:mm:ss>     (Filter by date and/or time)
[--method] <HTTP verb>              (Filter by request method)
[--file] <path>                     (Filter by requested resource)
[--status] <code>                   (Filter by response status code)
[--user-agent] <User-Agent>         (Filter by User-Agent)
[--keep-query]                      (Keep URL query parameters in output)
[--threshold] <count>               (Filter output by number of requests)
```

##### Example Usage
Filter output to requests equal to or above 10 on today's date with a method of 'POST' and a status code of '200' to either 'xmlrpc' or 'wp-login':
```
./apachefilter.sh --date $(date '+%d/%b/%Y') --method POST --file xmlrpc|wp-login --status 200 --threshold 10
```

Filter output by requests from Google's 66.249.64.0/19 netblock:
```
./apachefilter.sh --ip '^66.249.(6[4-9]|[78][0-9]|9[0-5])\\.'
```

Filter output by all '404' status codes from Googlebot this month:
```
./apachefilter.sh --date $(date '+%b/%Y') --status 404 --user-agent 'Googlebot'
```

##### Notes
- Checks for all access logs under `/home/*/access-logs/*`
- Relies on a specific Apache access log format
- Output is strictly in the following format: `Count, IP Address, Method, Status Code, URL`
- Output is sorted by amount of requests
- Output is limited to the 20 highest requests made
- File filtering is applied to the full filepath, regardless of if `--keep-query` is false or not
- Probably horribly inefficient for investigating high load in real-time
- No "help" function
---
