#!/usr/bin/env bash
CONC_MAX=${CONC_MAX:-20}

conc() {
  local procs=(`jobs -p`)
  local proc_count=${#procs[*]}

  # Block until there is an open slot
  if ((proc_count >= CONC_MAX)); then
      wait
  fi

  # Start our task
  (eval "$@") &
}
