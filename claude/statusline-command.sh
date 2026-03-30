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

# Context usage — progress bar + remaining tokens
used_pct=$(jq_num '.context_window.used_percentage')
window_size=$(jq_num '.context_window.context_window_size')

ctx_str=""
if [ -n "$used_pct" ]; then
  # Build 10-segment progress bar
  pct_int=$(echo "$used_pct" | awk '{ printf "%.0f", $1 }')
  filled=$(( pct_int * 6 / 100 ))
  empty=$(( 6 - filled ))
  bar=""
  i=0; while [ "$i" -lt "$filled" ]; do bar="${bar}█"; i=$((i + 1)); done
  i=0; while [ "$i" -lt "$empty" ]; do bar="${bar}░"; i=$((i + 1)); done

  # Color bar by usage level
  if [ "$pct_int" -ge 75 ]; then
    bar_color="$red"
  elif [ "$pct_int" -ge 50 ]; then
    bar_color="$orange"
  else
    bar_color="$green"
  fi

  # Used tokens
  remaining=""
  if [ -n "$window_size" ] && [ "$window_size" -gt 0 ]; then
    used_tokens=$(echo "$used_pct $window_size" | awk '{ printf "%.0f", $2 * $1 / 100 }')
    if [ "$used_tokens" -ge 1000000 ]; then
      used_fmt=$(echo "$used_tokens" | awk '{ printf "%.1fM", $1/1000000 }')
    elif [ "$used_tokens" -ge 1000 ]; then
      used_fmt=$(echo "$used_tokens" | awk '{ printf "%dk", $1/1000 }')
    else
      used_fmt="$used_tokens"
    fi
    # Format window size
    if [ "$window_size" -ge 1000000 ]; then
      win_fmt=$(echo "$window_size" | awk '{ printf "%.1fM", $1/1000000 }')
    elif [ "$window_size" -ge 1000 ]; then
      win_fmt=$(echo "$window_size" | awk '{ printf "%dk", $1/1000 }')
    else
      win_fmt="$window_size"
    fi
    # Strip trailing ".0" from window (1.0M -> 1M)
    win_short=$(echo "$win_fmt" | sed 's/\.0M$/M/')
    remaining=" ${used_fmt}/${win_short}"
  fi

  ctx_str="${dim}${bar}${reset} ${bar_color}${remaining}${reset}"
else
  ctx_str="${dim}[------] --${reset}"
fi

# 5-hour rate limit window
rl_used=$(jq_num '.rate_limits.five_hour.used_percentage')
rl_resets=$(jq_num '.rate_limits.five_hour.resets_at')

rl_str=""
if [ -n "$rl_used" ]; then
  rl_pct_int=$(echo "$rl_used" | awk '{ printf "%.0f", $1 }')
  rl_filled=$(( rl_pct_int * 6 / 100 ))
  rl_empty=$(( 6 - rl_filled ))
  rl_bar=""
  i=0; while [ "$i" -lt "$rl_filled" ]; do rl_bar="${rl_bar}█"; i=$((i + 1)); done
  i=0; while [ "$i" -lt "$rl_empty" ]; do rl_bar="${rl_bar}░"; i=$((i + 1)); done
  rl_str="${rl_bar}"
  if [ -n "$rl_resets" ]; then
    now_s=$(date +%s)
    if [ "$rl_resets" -gt "$now_s" ] 2>/dev/null; then
      diff=$(( rl_resets - now_s ))
      hrs=$(( diff / 3600 ))
      mins=$(( (diff % 3600) / 60 ))
      rl_str="${rl_str} ${hrs}h${mins}m"
    fi
  fi
fi

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
out+=" "
[ -n "$model" ] && out+="${blue}${model}${reset} "
out+="${ctx_str}"
[ -n "$rl_str" ] && out+=" ${purple}⏱ ${rl_str}${reset}"

printf '%b' "$out"
