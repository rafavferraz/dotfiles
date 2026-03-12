#!/bin/sh
input=$(cat)

# --- Extract fields ---
cwd=$(echo "$input" | jq -r '.cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

[ -z "$cwd" ] && cwd="$PWD"

# --- ANSI codes ---
RST='\033[0m'
BLUE='\033[1;34m'
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
CYAN='\033[36m'
MAGENTA='\033[35m'
DIM='\033[38;5;245m'

# --- Shorten path: ~/code/projects/lagrange → ~/c/p/lagrange ---
home="$HOME"
case "$cwd" in
  "$home"*) short_path="~${cwd#"$home"}" ;;
  *) short_path="$cwd" ;;
esac
short_path=$(echo "$short_path" | awk -F/ '{
  if (NF <= 2) { print; next }
  out = ""
  for (i = 1; i < NF; i++) {
    part = $i
    if (part == "~") out = out "~"
    else if (part == "") continue
    else { if (out != "" && out != "~") out = out "/"; out = out substr(part, 1, 1) }
  }
  if (out != "" && out != "~") out = out "/"
  print out $NF
}')

# --- Git info ---
git_info=""
if git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_dirty=""
  if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    git_dirty="*"
  fi
  git_info=" ${YELLOW} ${git_branch}${git_dirty}${RST}"
fi

# --- Context bar ---
ctx_bar=""
if [ -n "$used" ]; then
  filled=$((used / 10))
  empty=$((10 - filled))
  bar=""
  i=0; while [ "$i" -lt "$filled" ]; do bar="${bar}█"; i=$((i + 1)); done
  i=0; while [ "$i" -lt "$empty" ]; do bar="${bar}░"; i=$((i + 1)); done
  if [ "$used" -ge 80 ]; then
    bar_color="$RED"
  elif [ "$used" -ge 50 ]; then
    bar_color="$YELLOW"
  else
    bar_color="$GREEN"
  fi
  ctx_bar=" ${bar_color}${bar} ${used}%%${RST}"
fi

# --- Tokens: format as K ---
format_tokens() {
  tok=$1
  if [ "$tok" -ge 1000 ]; then
    printf '%d.%dk' $((tok / 1000)) $(( (tok % 1000) / 100 ))
  else
    printf '%d' "$tok"
  fi
}
tok_in=$(format_tokens "$total_input")
tok_out=$(format_tokens "$total_output")
tokens=" ${CYAN}↑${tok_in} ↓${tok_out}${RST}"

# --- Cost ---
cost_str=""
if [ "$(echo "$cost > 0" | bc 2>/dev/null)" = "1" ]; then
  cost_fmt=$(printf '$%.2f' "$cost")
  cost_str=" ${MAGENTA}${cost_fmt}${RST}"
fi

# --- Model ---
model_str=""
[ -n "$model" ] && model_str=" ${DIM}${model}${RST}"

# --- Compose (use %b to interpret escape sequences) ---
printf '%b' "${BLUE}${short_path}${RST}${git_info}${model_str} │${ctx_bar} │${tokens}${cost_str}"
