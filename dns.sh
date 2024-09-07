#!/bin/bash

function usage() {
  echo "Usage: ./dns.sh [options] domains_file"
  echo ""
  echo "OPTIONS:"
  echo "  -s, --server       dns server to use"
  echo "  -t, --threads      number of concurrent processes (default: 0)"
  echo "                     set to '0' to tell xargs to run as many processes as possible at a time"
  echo "                     (this is used as xargs -P option)"
  echo "  -h, --help         print this help message and exit"
  echo ""
  echo "EXAMPLE:"
  echo "  ./dns.sh -t 5 -s 10.10.10.11 ./domains.txt"
}

POSITIONAL_ARGS=()
THREADS=0

while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--server)
      DNSSERVER="$2"
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
  echo "domains file argument missing"
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

DOMAINS_FILE=${POSITIONAL_ARGS[0]}

if [ -f "$DOMAINS_FILE" ]; then
  :
else
  echo "$DOMAINS_FILE does not exist or is not a file."
  echo ""
  usage
  exit 1
fi

# logging helper
function info() {
  echo "[+] $@"
}
export -f info

# the function that tests a single subdomain
function test_dom() {
  if [ -z "$DNSSERVER" ]; then
    cmd="dig +noall +answer $1"
  else
    cmd="dig @$DNSSERVER +noall +answer $1"
  fi

  result=$(eval $cmd)

  if [ -z "$result" ]; then
    :;
  else
     info "Found $1" 
  fi
}
export -f test_dom


cat $DOMAINS_FILE | DNSSERVER=$DNSSERVER xargs -n 1 -P $THREADS -I {} bash -c 'test_dom "$@"' _ {}

info "Done"