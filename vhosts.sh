#!/bin/bash

function usage() {
  echo "Usage: ./vhosts.sh [options] host"
  echo ""
  echo "OPTIONS:"
  echo "  -d, --domain       root domain"
  echo "  -w, --wordlist     wordlist file with subdomains"
  echo "  -f, --filter-text  text present in response of invalid subdomains"
  echo ""
  echo "EXAMPLES:"
  echo "  ./vhosts.sh -w ./subdomains.txt -d example.com -f 'Example Domain' http://example.com"
}

POSITIONAL_ARGS=()

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

function test_sub() {
  if curl -H "Host: $1.$DOMAIN" $HOST 2>/dev/null | grep "$FILTERTEXT" >/dev/null; then
    :;
  else
     echo "Found $1.$DOMAIN" 
  fi
}

function info() {
  echo "[+] $@"
}

# test connection
if curl -H "Host: $DOMAIN" $HOST 2>/dev/null 1>/dev/null; then
  info "Successfully connected to $DOMAIN at $HOST"
  info "Bruteforcing..."
else
  echo "Error! Could not connect to $HOST"
  echo ""
  echo "to see what happened try: "
  echo "    curl -H \"Host: $DOMAIN\" $HOST 2>/dev/null"
  echo ""
  exit 1
fi

# brute
while read sub; do
  test_sub $sub
done < $WORDLIST
