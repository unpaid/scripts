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
[--referer|--referrer] <referer>    (Filter by Referer)
[--user-agent] <User-Agent>         (Filter by User-Agent)
[--keep-query]                      (Keep URL query parameters in output)
[--threshold] <count>               (Filter output by number of requests)
[-r|--raw]                          (Output to stdout after filtering but before any formatting or sorting)
[-o|--outputs] <flags>              (Select columns to output)
```

#### Outputs
```
Count              0
IP Address         1  (1 << 0)
Date               2  (1 << 1)
Request Method     4  (1 << 2)
Status Code        8  (1 << 3)
URL                16 (1 << 4)
Referer            32 (1 << 5)
```

#### Example Usage
Filter output to requests equal to or above 10 on today's date with a method of 'POST' and a status code of '200' to either 'xmlrpc' or 'wp-login':
```
bash <(curl -s https://raw.githubusercontent.com/unpaid/scripts/master/apachefilter.sh) --date $(date '+%d/%b/%Y') --method POST --file 'xmlrpc|wp-login' --status 200 --threshold 10
```

Filter output by requests from Google's 66.249.64.0/19 netblock:
```
bash <(curl -s https://raw.githubusercontent.com/unpaid/scripts/master/apachefilter.sh) --ip '^66.249.(6[4-9]|[78][0-9]|9[0-5])\\.'
```

Filter output by all '404' status codes from Googlebot this month:
```
bash <(curl -s https://raw.githubusercontent.com/unpaid/scripts/master/apachefilter.sh) --date $(date '+%b/%Y') --status 404 --user-agent 'Googlebot'
```

Count total amount of requests to 'domain.com' on the 21st of September 2022:
```
bash <(curl -s https://raw.githubusercontent.com/unpaid/scripts/master/apachefilter.sh) --domain 'domain.com' --date '21/09/2022' --raw | wc -l
```

Filter output by all '403' status codes from each IP address, separated only by date:
```
bash <(curl -s https://raw.githubusercontent.com/unpaid/scripts/master/apachefilter.sh) --status 403 --output 11
```

#### Notes
- Checks for all access logs under `/home/*/access-logs/*`
- Relies on a specific Apache access log format
- When the `--raw` flag is present, the output will be in the following format: `IP Address|Date|Method|Status Code|URL|Referer|User-Agent`
- When the `--raw` flag and `--outputs` option is absent, the output will be in the following format: `Count, IP Address, Date, Method, Status Code, URL, Referer`
- Output is sorted by amount of requests
- Output is limited to the 20 highest requests made when `--threshold` isn't specified
- File filtering is applied to the full filepath, regardless of if `--keep-query` is false or not
- Probably horribly inefficient for investigating high load in real-time
- No "help" function
---
