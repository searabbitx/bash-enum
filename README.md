# bash-enum

A collection of bash scripts to enumerate / bruteforce various services.

Those scripts are meant to use only the tools that are present on most linux distros

## Scripts

### `vhosts.sh`

Brute force vhosts (uses `curl` and `xargs`)

```
Usage: ./vhosts.sh [options] host

OPTIONS:
  -d, --domain       root domain
  -w, --wordlist     wordlist file with subdomains
  -f, --filter-text  text present in response of invalid subdomains
  -t, --threads      number of concurrent processes (default: 0)
                     set to '0' to tell xargs to run as many processes as possible at a time
                     (this is used as xargs -P option)
  --curl-opts        additional arguments to pass to curl
  -h, --help         print this help message and exit

EXAMPLE:
  ./vhosts.sh -t 5 -w ./subdomains.txt \
      -d example.com -f 'Example Domain' \
      --curl-opts '--user-agent SomeAgent -H "X-Auth: foo"' \
      http://example.com
```

### `tcpscan.sh`

tcp port scan (uses `nc` and `xargs`)

```
Usage: ./tcpscan.sh [options] ip ports

OPTIONS:
  -t, --threads      number of concurrent processes (default: 0)
                     set to '0' to tell xargs to run as many processes as possible at a time
                     (this is used as xargs -P option)
  -w, --timeout      number of seconds to wait for a port (default: 1)
                     (this is used as nc -w option)
  -h, --help         print this help message and exit

EXAMPLE:
  ./tcpscan.sh -t 5 -w 2 10.10.10.10 '21-25,80,8000-9000,3306'
```