#!/bin/bash

function notify() {
  # $WC_NOTIFY will be replace by the command by Heat SofwareConfig str_replace
  $WC_NOTIFY --data-binary "{\"status\":\"$1\", \"reason\":\"$2\", \"data\":\"$3\"}"
}

function notify_success() {
  notify SUCCESS "$1" "$2"
  exit 0
}

function notify_failure() {
  notify FAILURE "$1" "$2"
  exit 1
}

function trap_failure() {
        LAST_RETURN_CODE=$?
        if [ $LAST_RETURN_CODE -ne 0 ]; then
	        notify_failure "Error in $0"
	fi
}
