#!/bin/bash
# Catppuccin Mocha statusline for Claude Code
# Mirrors Starship prompt style: directory | git branch + status | character
input=$(cat)

# Parse JSON inputs
dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
[ -z "$dir" ] && dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
[ -z "$dir" ] && dir=$(pwd)

# Home directory substitution
home="$HOME"
dir_display="${dir/#$home/\~}"

# Truncate to last 4 components (matching Starship truncation_length=4)
IFS='/' read -ra parts <<< "$dir_display"
count=${#parts[@]}
if [ "$count" -gt 4 ]; then
    dir_display=".../${parts[$((count-4))]}/${parts[$((count-3))]}/${parts[$((count-2))]}/${parts[$((count-1))]}"
fi

# Catppuccin Mocha colors (truecolor ANSI)
teal='\033[38;2;148;226;213m'
lavender='\033[38;2;180;190;254m'
green='\033[38;2;166;227;161m'
yellow='\033[38;2;249;226;175m'
red='\033[38;2;243;139;168m'
peach='\033[38;2;250;179;135m'
mauve='\033[38;2;203;166;247m'
blue='\033[38;2;137;180;250m'
reset='\033[0m'

# Directory in teal: [ path ]
printf "${teal}[ ${dir_display} ]${reset}"

# Check if in a git repo
if git_dir=$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" rev-parse --show-toplevel 2>/dev/null); then
    # Get branch name (or short SHA if detached)
    branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
        branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" rev-parse --short HEAD 2>/dev/null)
        [ -z "$branch" ] && branch="(detached)"
    fi

    # Branch with worktree indicator if applicable
    if [ -n "$worktree" ]; then
        printf " ${lavender}⛓ ${branch}${reset}"
    else
        printf " ${lavender} ${branch}${reset}"
    fi

    # Fetch git status
    status=$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" status --porcelain -b 2>/dev/null)

    ahead=0; behind=0
    staged=0; modified=0; renamed=0; deleted=0
    untracked=0; conflicted=0
    stashed=$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" stash list 2>/dev/null | wc -l)
    stashed=$((stashed))

    # Parse branch line for ahead/behind
    branch_line=$(echo "$status" | head -1)
    ahead=$(echo "$branch_line" | sed -n 's/.*ahead \([0-9]*\).*/\1/p')
    behind=$(echo "$branch_line" | sed -n 's/.*behind \([0-9]*\).*/\1/p')
    [ -z "$ahead" ] && ahead=0
    [ -z "$behind" ] && behind=0

    # Parse file status lines (skip branch line)
    rest=$(echo "$status" | tail -n +2)
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        x="${line:0:1}"
        y="${line:1:1}"

        # Conflicted (unmerged)
        if [ "$x" = "U" ] || [ "$y" = "U" ] || { [ "$x" = "A" ] && [ "$y" = "A" ]; } || { [ "$x" = "D" ] && [ "$y" = "D" ]; }; then
            conflicted=$((conflicted + 1))
            continue
        fi

        # Untracked
        if [ "$x" = "?" ] && [ "$y" = "?" ]; then
            untracked=$((untracked + 1))
            continue
        fi

        # Staged changes (non-empty staging column, not ! or .)
        [ "$x" != " " ] && [ "$x" != "!" ] && staged=$((staged + 1))

        # Modified in working tree
        [ "$y" != " " ] && [ "$y" != "!" ] && modified=$((modified + 1))

        # Renamed
        [ "$x" = "R" ] || [ "$y" = "R" ] && renamed=$((renamed + 1))

        # Deleted
        [ "$x" = "D" ] || [ "$y" = "D" ] && deleted=$((deleted + 1))
    done <<< "$rest"

    # Print status indicators (matching Starship git_status style)
    [ "$staged" -gt 0 ]     && printf " ${green}+${staged}${reset}"
    [ "$modified" -gt 0 ]   && printf " ${yellow}!${modified}${reset}"
    [ "$renamed" -gt 0 ]    && printf " ${blue}»${renamed}${reset}"
    [ "$deleted" -gt 0 ]    && printf " ${red}-${deleted}${reset}"
    [ "$untracked" -gt 0 ]  && printf " ${red}?${untracked}${reset}"
    [ "$stashed" -gt 0 ]    && printf " ${lavender}≡${stashed}${reset}"
    [ "$conflicted" -gt 0 ] && printf " ${red}✖${conflicted}${reset}"

    # Ahead/behind/diverged
    if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
        printf " ${mauve}⇕⇡${ahead}⇣${behind}${reset}"
    elif [ "$ahead" -gt 0 ]; then
        printf " ${teal}⇡${ahead}${reset}"
    elif [ "$behind" -gt 0 ]; then
        printf " ${peach}⇣${behind}${reset}"
    fi
fi

# Character symbol at the end (green on success)
printf " ${green}${reset}"
printf "\n"
