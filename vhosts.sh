#!/bin/bash

function usage() {
  echo "Usage: ./vhosts.sh [options] host"
  echo ""
  echo "OPTIONS:"
  echo "  -d, --domain       root domain"
  echo "  -w, --wordlist     wordlist file with subdomains"
  echo "  -f, --filter-text  text present in response of invalid subdomains"
  echo "  -t, --threads      number of concurrent processes (default: 10)"
  echo "                     (this is used as xargs -P option)"
  echo "                     set to '0' to tell xargs to run as many processes as possible at a time"
  echo "  -h, --help         print this help message and exit"
  echo ""
  echo "EXAMPLE:"
  echo "  ./vhosts.sh -t 5 -w ./subdomains.txt \\"
  echo "      -d example.com -f 'Example Domain' \\"
  echo "      http://example.com"
}

POSITIONAL_ARGS=()
THREADS=10

while [[ $# -gt 0 ]]; do
  case $1 in
    -w|--wordlist)
      WORDLIST="$2"
      shift
      shift
      ;;
    -d|--domain)
      DOMAIN="$2"
      shift
      shift
      ;;
    -f|--filter-text)
      FILTERTEXT="$2"
      shift
      shift
      ;;
    -t|--threads)
      THREADS="$2"
      shift
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*|--*)
      echo "Unknown option $1"
      echo ""
      usage
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

if [ "${#POSITIONAL_ARGS[@]}" == "0" ]; then
  echo "host argument missing"
  echo ""
  usage
  exit 1
fi

if [ "${#POSITIONAL_ARGS[@]}" != "1" ]; then
  echo "Too many positional arguments"
  echo ""
  usage
  exit 1
fi

HOST=${POSITIONAL_ARGS[0]}

# logging helper
function info() {
  echo "[+] $@"
}
export -f info

# the function that tests a single subdomain
function test_sub() {
  if curl -H "Host: $1.$DOMAIN" $HOST 2>/dev/null | grep "$FILTERTEXT" >/dev/null; then
    :;
  else
     info "Found $1.$DOMAIN" 
  fi
}
export -f test_sub

# test connection
if curl --parallel -H "Host: $DOMAIN" $HOST 2>/dev/null 1>/dev/null; then
  info "Successfully connected to $DOMAIN at $HOST"
  info "Bruteforcing $DOMAIN with wordlist $WORDLIST and $THREADS threads..."
else
  echo "Error! Could not connect to $HOST"
  echo ""
  echo "to see what happened try: "
  echo "    curl -H \"Host: $DOMAIN\" $HOST 2>/dev/null"
  echo ""
  exit 1
fi

cat $WORDLIST | DOMAIN=$DOMAIN HOST=$HOST FILTERTEXT=$FILTERTEXT xargs -n 1 -P $THREADS -I {} bash -c 'test_sub "$@"' _ {}
