#! /usr/bin/env bash

set -euo pipefail


# to include library to your script, use:
# UTILS_DIR=$(pwd)/$(dirname ${BASH_SOURCE[0]})
# source $UTILS_DIR/lib.sh


####### CLI default behaviour

USE_LIVE="\n    --no-op		Enables no-operation mode. Just print out command, that would have been executed."

APP_NAME=$(basename $0)
DEBUG=
LIVE=yes
VERSION=${VERSION:-$(cat VERSION 2>/dev/null)}
VERSION=${VERSION:-0.0.1}

function usage() {
	cat <<EOF
usage: ${APP_NAME} [--debug] [--help] $([[ $USE_LIVE ]] && echo -e "[--no-op]")

optional arguments:
	--debug    Debug mode
	--help	   Print this help and exit gracefully
	--version  Show version info and exit gracefully
EOF
	exit 0
}

function debug() {
	[[ $DEBUG ]] && echo "[DEBUG] $@"
}

function err() {
	echo -e "[ERROR] $@\n" >&2
}

function fail() {
	CODE=1
	if [[ "$1" =~ ^[0-9]+$ ]]; then
		CODE=$1
		shift
	fi
	echo "[FAIL] $@" >&2 && exit $CODE
}

function final() {
	echo "[DONE]  $@" && exit 0
}

function out() {
	echo "[INFO]  $@"
}

function run() {
	if [[ $LIVE ]] || [[ -z $USE_LIVE ]]; then
		[[ $DEBUG ]] && debug "$@"
		$@
	else
		(echo "[NOOP]  $@")
	fi
}

function is_terminal() {
	[[ -t 1 ]]
	return $?
}

# Parsing script parameters will not work when calling getopts from within a function,
# so copy this function's content to your script and modify according to your needs
function parse_params_example() {
	err "Do not call this, as getopts won't work on script params when called from function"

	optspec=":x:-:"
	while getopts "$optspec" optchar; do
		case "${optchar}" in
            # this parses long parameters
			-)
				case "${OPTARG}" in
					withValue=*)
						val=${OPTARG#*=}
						opt=${OPTARG%=$val}
						echo "Parsing option: '--${opt}', value: '${val}'" >&2
						;;
					*)
						# Do not exit, but show, that non-default param was recognized and not processed
						parse_default_long_params "${optchar}"
						if [[ $? -ne 0 ]]; then
							err "Unknown parameter -${OPTARG} or missing value"
							exit 1
						fi
						;;
				esac
				;;
			x)
				# Just example, how to do for short params
				YOUR_PARAM=${OPTARG}
				;;
			*)
				parse_params_unknown
				;;
		esac
	done
	shift $((OPTIND-1))

	POSITIONAL_ARGS=$@
}

# Call within getopts loop
function parse_default_long_params() {
	case "${OPTARG}" in
		debug)
			DEBUG=1
			;;
		help)
			usage
			exit 0
			;;
		no-op)
			[[ $USE_LIVE ]] && LIVE= || parse_params_unknown
			;;
		version)
			echo $VERSION
			exit 0
			;;
		*)
			# Do not exit, but show, that non-default param was recognized and not processed
			return 1
			;;
		# loglevel)
		# 	val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
		# 	echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
		# 	;;
		# loglevel=*)
		# 	val=${OPTARG#*=}
		# 	opt=${OPTARG%=$val}
		# 	echo "Parsing option: '--${opt}', value: '${val}'" >&2
		# 	;;
	esac

}

function parse_params_unknown() {
	if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
		err "You need to provide a valid option for argument: '-${OPTARG}'"
		return 1
	fi
}

function print_default_debug_info() {
	[[ $DEBUG ]] &&  (
		debug "Pay attention, that outputting debug information could break"
		debug "functionality of scripts using this tool."
		debug "------------------------------------------------------------"
		debug "APP NAME = ${APP_NAME}"
		[[ $0 =~ sh$ ]] && (debug "Script is sourced")
		# [[ $0 =~ sh$ ]] && (debug "Script is sourced" ; debug "by script = ${BASH_SOURCE[1]}") ; 
		debug "CURRENT_DIR = $(pwd)"
		debug "LIVE = ${LIVE:-no}"
		debug "VERSION = ${VERSION}"
	)
}

####### String manipulation

function trim() {
	RES=${@%%*( )}
	RES=${RES##*( )}
	echo "${RES}"
}
