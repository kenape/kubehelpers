#!/usr/bin/env bash

# Functions below contain echos and if you put them directly in your bashrc they will break things like scp.
# So one way to avoid this is to first check if the session is interactive, maybe with something like this in your bashrc:
# # Check if shell is interactive in order to source things that would otherwise break scp, etc...
# if [[ $- == *i* ]]; then
#   . /path/to/helpers.sh
# fi

function restorePositionalParameters() {
  set -- "${positionalargs[@]}"
}
export -f restorePositionalParameters    # export it so it is visible to things like watch...

function usage-for-shownonreadypods() {
  echo "Usage: ${1} [OPTIONS] [namespace]
Watches for pods that are not 100% up yet.
A pod is considered not 100% up yet if status is not 'Running' or if all containers or not ready.
If no [namespace] is given then the default namespace is used.

OPTIONS:
  -h, --help           display this help and exit
"
}

function shownonreadypods() {
positionalargs=()    # init empty array

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage-for-shownonreadypods ${FUNCNAME[0]}
      return 0
      ;;
    -*|--*)
      echo "Unknown option $1" >&2
      usage-for-shownonreadypods ${FUNCNAME[0]}
      return 1
      ;;
    *)
      positionalargs+=("$1")    # add positional arg to the array
      shift # past argument
      ;;
  esac
done

if [[ ${#positionalargs[@]} -eq 1 ]]; then
  namespace="-n ${positionalargs[0]}"
elif [[ ${#positionalargs[@]} -eq 0 ]]; then
  namespace=""
else
  echo "Error: Wrong number of mandatory arguments supplied" >&2
  restorePositionalParameters
  usage-for-shownonreadypods ${FUNCNAME[0]}
  return 1
fi
restorePositionalParameters

# regex back references info: https://www.regular-expressions.info/backref.html
# regex explanation:
# [0-9][0-9]* : match a digit followed by 0 or more digits
# \([0-9][0-9]*\) : create a numbered capturing group, capturing group number 1
# \([0-9][0-9]*\)/ : after matching capturing group #1 also match a slash
# \([0-9][0-9]*\)/\1 : after matching capturing group #1 and the slash match capturing group #1 again (i.e. match two equal numbers with a / between them)
# \([0-9][0-9]*\)/\1 *Running : after matching capturing group #1 and a slash and capturing group #1 again match 0 or more space and Running
kubectl $namespace get pods | grep -v "\([0-9][0-9]*\)/*\1 *Running"

unset namespace
}
export -f shownonreadypods    # export it so it is visible to things like watch...
