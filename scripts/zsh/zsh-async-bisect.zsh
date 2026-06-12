#!/usr/bin/env zsh
source ./.zsh-async.zsh

async_init

# === The predicate function (runs in worker subprocess) ===
# Each job gets its OWN WORKTREE: parallel jobs sharing one working tree
# would trample each other's checkouts and produce garbage verdicts.
predicate_function() {
  local sha=$1
  local wt="/tmp/wt-$sha"
  git worktree add -f -q "$wt" "$sha" || { print "$sha"; return 125 }
  cd "$wt" || { print "$sha"; return 125 }
  print "$sha"   # stdout carries the sha back to the callback (see below)

  pnpm install --frozen-lockfile --prefer-offline >/dev/null 2>&1 || return 125
  pnpm build >/dev/null 2>&1 || return 125
  pnpm test --reporter=dot >/dev/null 2>&1
}

# === Result handler (runs in main process) ===
# zsh-async callbacks receive: $1 = job NAME (always "predicate_function"
# here — NOT the sha), $2 = return code, $3 = the job's STDOUT. Keying
# results on $1 would overwrite one entry forever and loop infinitely;
# recover the sha from stdout instead.
typeset -A RESULTS
collect_result() {
  local return_code=$2
  local sha=${${(f)3}[1]}          # first stdout line = the sha
  [[ -n $sha ]] && RESULTS[$sha]=$return_code
  print "Worker → $sha: $return_code"
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
zmodload zsh/zselect            # zsh-async does NOT load zselect for you
while (( ${#RESULTS} < ${#SHAS} )); do
  async_process_results bisect_worker
  zselect -t 50                 # poll every 500 ms
done

# === Bisect from results ===
for sha in $SHAS; do
  [[ "${RESULTS[$sha]}" == "1" ]] && { print "First bad: $sha"; break }
done

async_stop_worker bisect_worker
