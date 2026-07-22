#!/usr/bin/env bash
# Claude Code status line — requires jq
# Colors: Gruvbox Dark (matching starship theme)

input=$(cat)

# Gruvbox bright ANSI escape colors (matches starship rendered look)
yellow='\033[38;2;250;189;47m'    # #fabd2f — directory
aqua='\033[38;2;142;192;124m'     # #8ec07c — git branch
blue='\033[38;2;69;133;136m'      # #458588 — model
orange='\033[38;2;254;128;25m'    # #fe8019 — cost
green='\033[38;2;184;187;38m'     # #b8bb26 — context ok
red='\033[38;2;251;73;52m'        # #fb4934 — context high
purple='\033[38;2;155;89;182m'    # #9b59b6 — violet
fg='\033[38;2;235;219;178m'       # #ebdbb2 — default text
grey='\033[38;2;168;153;132m'     # #a89984 — bar fill (light grey)
dim='\033[38;2;146;131;116m'      # #928374 — separators
reset='\033[0m'

# JSON field extraction helpers (uses jq for reliability with nested objects)
jq_str() { echo "$input" | jq -r "$1 // empty" 2>/dev/null; }
jq_num() { echo "$input" | jq -r "$1 // empty" 2>/dev/null; }

# Current working directory (shorten $HOME to ~)
cwd=$(jq_str '.cwd')
[ -z "$cwd" ] && cwd=$(jq_str '.workspace.current_dir')
[ -z "$cwd" ] && cwd=$(pwd)
# Shorten path: ~/code/projects/lagrange -> ~/c/p/lagrange
short_cwd="${cwd/#$HOME/~}"
short_cwd=$(echo "$short_cwd" | awk -F'/' '{
  n = NF
  for (i = 1; i < n; i++) {
    seg = $i
    if (seg == "~") printf "~/"
    else printf "%s/", substr(seg, 1, 1)
  }
  printf "%s", $n
}')

# Git branch (skip optional locks to avoid stalling)
git_branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    # Dirty status
    dirty=""
    if ! git -C "$cwd" -c gc.auto=0 diff --quiet HEAD -- 2>/dev/null; then
      dirty="*"
    fi

    # Ahead/behind
    ab=""
    counts=$(git -C "$cwd" -c gc.auto=0 rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
    if [ -n "$counts" ]; then
      ahead=$(echo "$counts" | awk '{print $1}')
      behind=$(echo "$counts" | awk '{print $2}')
      [ "$ahead" -gt 0 ] 2>/dev/null && ab="${ab}↑${ahead}"
      [ "$behind" -gt 0 ] 2>/dev/null && ab="${ab}↓${behind}"
      [ -n "$ab" ] && ab=" ${ab}"
    fi

    git_branch=" (${branch}${dirty}${ab})"

    # Stash count
    stash_count=$(git -C "$cwd" -c gc.auto=0 stash list 2>/dev/null | wc -l | tr -d ' ')
    [ "${stash_count:-0}" -gt 0 ] 2>/dev/null && git_branch="${git_branch} ⚑${stash_count}"
  fi
fi

# Model name — shorten "Claude Sonnet 4.6 (200k context)" → "Sonnet 4.6"
model=$(jq_str '.model.display_name' | sed 's/^[Cc]laude //; s/ (.*$//' | xargs)

# Reasoning effort level — only emitted for models that expose it.
effort=$(jq_str '.effort.level')

# Fill gauge shared by the context and rate-limit segments: "$1"=percent,
# "$2"=color for the filled cells (▓); empty cells (░) are always dim grey.
# One cell is 25%, so a fill under 12.5% rounds to an empty gauge.
BAR_W=4
bar() {
  echo "$1 $BAR_W" | awk -v f="$2" -v d="$dim" '{
    filled = int($1 * $2 / 100 + 0.5)
    if (filled > $2) filled = $2
    printf "%s", f
    for (i = 0; i < filled; i++) printf "\xe2\x96\x93"      # ▓
    printf "%s", d
    for (i = filled; i < $2; i++) printf "\xe2\x96\x91"     # ░
  }'
}

# Token count → "70k", "432k", "1M", "1.5M".
fmt_tokens() {
  echo "$1" | awk '{
    if ($1 >= 1000000) { v = $1 / 1000000; if (v == int(v)) printf "%dM", v; else printf "%.1fM", v }
    else if ($1 >= 1000) printf "%dk", $1 / 1000
    else printf "%d", $1
  }'
}

# Context usage — fill gauge + used/window tokens. This gauge carries the
# green → yellow → orange → red ramp while the rate-limit gauges stay grey, so
# a colored bar always means the context is the thing filling up.
used_pct=$(jq_num '.context_window.used_percentage')
window_size=$(jq_num '.context_window.context_window_size')

if [ -n "$used_pct" ]; then
  pct_int=$(echo "$used_pct" | awk '{ printf "%.0f", $1 }')
  if   [ "$pct_int" -ge 85 ]; then ctx_color="$red"
  elif [ "$pct_int" -ge 70 ]; then ctx_color="$orange"
  elif [ "$pct_int" -ge 50 ]; then ctx_color="$yellow"
  else ctx_color="$green"
  fi
  ctx_str="$(bar "$pct_int" "$ctx_color")${reset}"
  if [ -n "$window_size" ] && [ "$window_size" -gt 0 ] 2>/dev/null; then
    used_tokens=$(echo "$used_pct $window_size" | awk '{ printf "%.0f", $2 * $1 / 100 }')
    ctx_str="${ctx_str} ${dim}$(fmt_tokens "$used_tokens")/$(fmt_tokens "$window_size")${reset}"
  fi
else
  ctx_str="$(bar 0 "$dim")${reset}"
fi

# Rate limit windows: 5-hour rolling + weekly (7-day, all-models limit; the
# Fable/Opus weekly sub-limit is not exposed to statusline scripts). Formats
# one window ("$1"=used_percentage, "$2"=resets_at, "$3"=optional label) into
# a "[gauge] H:MM" fragment; empty when the window is absent. The countdown is
# total hours, so a fresh week reads "163:44" rather than "6d 19h". These
# gauges stay grey — color is reserved for the context gauge.
now_s=$(date +%s)
rl_window() {
  local used="$1" resets="$2" label="$3"
  [ -z "$used" ] && return
  local pct_int frag diff
  pct_int=$(echo "$used" | awk '{ printf "%.0f", $1 }')
  frag="$(bar "$pct_int" "$grey")${reset}"
  [ -n "$label" ] && frag="${dim}${label}${reset} ${frag}"
  if [ -n "$resets" ] && [ "$resets" -gt "$now_s" ] 2>/dev/null; then
    diff=$(( resets - now_s ))
    frag="${frag} ${dim}$(( diff / 3600 )):$(printf '%02d' $(( (diff % 3600) / 60 )))${reset}"
  fi
  printf '%s' "$frag"
}

# Labels are dropped when both windows render: the order is fixed (5h then 7d)
# and the countdown magnitudes disambiguate. A window shown alone keeps its
# label, since position alone would be ambiguous.
u5=$(jq_num '.rate_limits.five_hour.used_percentage')
u7=$(jq_num '.rate_limits.seven_day.used_percentage')
lb5="" lb7=""
[ -z "$u7" ] && lb5="5h"
[ -z "$u5" ] && lb7="7d"

rl5=$(rl_window "$u5" "$(jq_num '.rate_limits.five_hour.resets_at')" "$lb5")
rl7=$(rl_window "$u7" "$(jq_num '.rate_limits.seven_day.resets_at')" "$lb7")

rl_str=""
[ -n "$rl5" ] && rl_str="$rl5"
[ -n "$rl7" ] && rl_str="${rl_str:+$rl_str }$rl7"

# Session cost (cumulative)
total_cost=$(jq_num '.cost.total_cost_usd')
cost_str=""
if [ -n "$total_cost" ]; then
  cost_str=$(echo "$total_cost" | awk '{
    if ($1 < 0.01)
      printf "$%.4f", $1
    else if ($1 < 1.00)
      printf "$%.3f", $1
    else
      printf "$%.2f", $1
  }')
else
  cost_str="--"
fi

# Session duration
duration_ms=$(jq_num '.cost.total_duration_ms')
dur_str=""
if [ -n "$duration_ms" ] && [ "$duration_ms" -gt 0 ] 2>/dev/null; then
  total_sec=$(( duration_ms / 1000 ))
  mins=$(( total_sec / 60 ))
  secs=$(( total_sec % 60 ))
  if [ "$mins" -gt 0 ]; then
    dur_str="${mins}m ${secs}s"
  else
    dur_str="${secs}s"
  fi
else
  dur_str="--"
fi

# Lines changed
lines_added=$(jq_num '.cost.total_lines_added')
lines_removed=$(jq_num '.cost.total_lines_removed')
lines_str=""
if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
  lines_str="+${lines_added:-0}/-${lines_removed:-0}"
else
  lines_str="--"
fi

# Assemble with Gruvbox colors
out=""
out+="${yellow}${short_cwd}${reset}"
out+="${aqua}${git_branch}${reset}"
[ -n "$model" ] && out+=" ${blue}${model}${reset}"
[ -n "$effort" ] && out+=" ${dim}${effort}${reset}"
out+=" ${ctx_str}"
[ -n "$rl_str" ] && out+=" ${purple}⏱${reset} ${rl_str}"
[ -n "$cost_str" ] && out+="  ${orange}${cost_str}${reset}"
[ -n "$lines_str" ] && out+="  ${green}${lines_str}${reset}"
[ -n "$dur_str" ] && out+="  ${dim}${dur_str}${reset}"

printf '%b' "$out"
