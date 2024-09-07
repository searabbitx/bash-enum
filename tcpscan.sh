#!/bin/bash

function usage() {
  echo "Usage: ./tcptest_port.sh [options] ip ports"
  echo ""
  echo "OPTIONS:"
  echo "  -t, --threads      number of concurrent processes (default: 0)"
  echo "                     set to '0' to tell xargs to run as many processes as possible at a time"
  echo "                     (this is used as xargs -P option)"
  echo "  -w, --timeout      number of seconds to wait for a port (default: 1)"
  echo "                     (this is used as nc -w option)"
  echo "  -h, --help         print this help message and exit"
  echo ""
  echo "EXAMPLE:"
  echo "  ./tcptest_port.sh -t 5 -w 2 10.10.10.10 '21-25,80,8000-9000,3306'"
}

POSITIONAL_ARGS=()
THREADS=0
TIMEOUT=1

while [[ $# -gt 0 ]]; do
  case $1 in
    -t|--threads)
      THREADS="$2"
      shift
      shift
      ;;
    -w|--timeout)
      TIMEOUT="$2"
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

if [ "${#POSITIONAL_ARGS[@]}" != "2" ]; then
  echo "invalid amount of positional args"
  echo ""
  usage
  exit 1
fi

IP=${POSITIONAL_ARGS[0]}
PORTS=${POSITIONAL_ARGS[1]}

# logging helper
function info() {
  echo "[+] $@"
}
export -f info

# the function that tests a single port
function test_port {
  if nc -nv -w $TIMEOUT -z $IP $1 2>&1 | grep -E 'open|succeeded' >/dev/null; then
    info "Port $1 open"
  fi
}
export -f test_port

function explode_ports() {
  for entry in $(echo $1 | tr ',' "\n"); do
    if echo $entry | grep '-' >/dev/null; then
      from=$(echo $entry | cut -d'-' -f1)
      to=$(echo $entry | cut -d'-' -f2)
      seq $from $to
    else
      echo $entry
    fi
  done
}

info "Testing ports $PORTS on $IP..."
explode_ports $PORTS | IP=$IP TIMEOUT=$TIMEOUT xargs -P $THREADS -I {} bash -c 'test_port "$@"' _ {}

info "Done"