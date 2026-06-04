#!/usr/bin/env zsh
source ./.zsh-async.zsh

async_init

# === The predicate function (runs in worker subprocess) ===
predicate_function() {
  local sha=$1
  git checkout -q "$sha" || return 125
  pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || return 125
  pnpm build >/dev/null 2>&1 || return 125

  # exercise + observe + exit
  local result
  result=$(pnpm test 2>&1)
  [[ "$result" == *"PASS"* ]] && return 0 || return 1
}

# === Result handler (runs in main process) ===
typeset -A RESULTS
collect_result() {
  local job_name=$1
  local return_code=$2
  RESULTS[$job_name]=$return_code
  print "Worker → $job_name: $return_code"
}

# === Setup worker pool ===
async_start_worker bisect_worker -n
async_register_callback bisect_worker collect_result

# === Dispatch ===
SHAS=( ${(f)"$(git rev-list --reverse last-good..HEAD)"} )
for sha in $SHAS; do
  async_job bisect_worker predicate_function "$sha"
done

# === Wait for completion ===
while (( ${#RESULTS} < ${#SHAS} )); do
  async_process_results bisect_worker
  zselect -t 50    # poll every 500 ms
done

# === Bisect from results ===
for sha in $SHAS; do
  [[ "${RESULTS[$sha]}" == "1" ]] && { print "First bad: $sha"; break }
done

async_stop_worker bisect_worker
