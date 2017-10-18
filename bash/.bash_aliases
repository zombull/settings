# Refresh bash terminal
alias rf='source ~/.bashrc'

# -----------------------------------------------------------------------------
# Git
# -----------------------------------------------------------------------------
function git-show() {
    if [ $# -eq 0 ]
    then
        git log --format=%B -n 1 $(git rev-parse --verify HEAD)
        echo
        git diff --name-only -r $(git rev-parse --verify HEAD)
    else
        git log --format=%B -n 1 $1
        echo
        git diff --name-only $1^ $1
    fi
}

function git-diff() {
    if [ $# -eq 0 ]
    then
        git diff $(git rev-parse --verify HEAD^) $(git rev-parse --verify HEAD)
    else
        git diff $1^ $1
    fi
}

function git-tree() {
    if [ $# -eq 0 ]
    then
        git diff-tree --no-commit-id --name-only -r $(git rev-parse --verify HEAD)
    else
        git diff-tree --no-commit-id --name-only -r $1
    fi
}

function git-blob() {
    git rev-list --all |
    while read commit; do
        if git ls-tree -r $commit | grep -q $1; then
            echo $commit
        fi
    done
}

function git-apply() {
    git reset --hard $(printf "origin/$(git rev-parse --abbrev-ref HEAD)")
    git am --whitespace=fix ~/mutt/*.patch
}

function git-cherry-pick-ref() {
    git status | grep "currently cherry-picking commit" | grep -o -E "[0-9a-f]{12}\b"
}

function git-cherry-pick-log() {
    git log -1 $(git-cherry-pick-ref)
}

function git-cherry-pick-show() {
    git show $(git-cherry-pick-ref)
}

function git-push-origin() {
    local opts
    local response=y
    local branch=$(git rev-parse --abbrev-ref HEAD)
    local exists=$(git ls-remote --heads origin $branch | wc -l)
    if [[ $exists == "0" ]]; then
        printf "\e[1;7;35mCreate and track remote branch origin/$branch? "
        read -r -p "[Y/n] " response
    elif [[ $exists != "1" ]]; then
        printf "Found multiple ($exists) branches: $branch\n"
        return 1
    elif [[ $1 == "force" ]]; then
        opts="-f"
        git status
        printf "\e[1;7;35mForce push remote branch origin/$branch? "
        read -r -p "[Y/n] " response
        printf "\e[0m"
    fi
    response=${response,,}    # tolower
    if [[ -z $response || $response =~ ^(yes|y)$ ]]; then
        git push $opts origin $branch
        git branch --set-upstream-to=origin/$branch
    fi
}

function git-url-patch() {
    # lynx -dump -nonumbers -hiddenlinks=liston $1 | grep -e "^http.*00(0[1-9]|1[0-7])\.patch" | xargs -n 1 curl -s | git am
    lynx -dump -nonumbers -hiddenlinks=liston $1 | grep -e "^http.*003[0-9].*\.patch" | xargs -n 1 curl -s | git am
}

. $SETTINGS/git/.git-completion.bash

# Add git completion to aliases
__git_complete g __git_main
__git_complete gb _git_branch

__git_complete gc _git_commit
__git_complete gd _git_diff
__git_complete ge _git_send_email
__git_complete gf _git_fetch
__git_complete gg _git_checkout
__git_complete gk _git_format_patch
__git_complete gl _git_log
__git_complete glo _git_log
__git_complete gp _git_cherry_pick
__git_complete gr _git_reset
__git_complete gs _git_log

alias g='git'
alias ga='git-apply'
alias gb='git branch'
alias gc='git commit'
alias gd='git-diff'
alias gdd='git diff'
alias gds='git diff --staged'
alias ge='git send-email'
alias gf='git fetch'
alias gg='git checkout'
alias ggd='gs | grep deleted: | cut -f 2 | tr -s " " | cut -f 2 -d " " | xargs git checkout'
alias gk='git format-patch -o ~/patches/'
alias gl='git log'
alias glo='git log --pretty=oneline'
alias gm="git status | grep modified | tr -d '\t' | tr -d ' ' | cut -f 2 -d :"
alias gpo='git-push-origin'
alias gfpo='git-push-origin force'
alias gp='git cherry-pick'
alias gpc='git cherry-pick --continue'
alias gpl='git-cherry-pick-log'
alias gps='git-cherry-pick-show'
alias gr='git reset'
alias grh='git reset HEAD'
alias grhh='git reset HEAD --hard'
alias grc='git rebase --continue'
alias gri='git rebase --interactive'
alias gs='git status'
alias gsa='git stash apply'
alias gsl='git stash list'
alias gsp='git stash pop'
alias gss='git stash save'
alias gt='git-tree'
alias gu='git-url-patch'
alias gv='git remote -vv'


# Run gofmt on all .go files from the HEAD commit
function git-gofmt() {
    git diff-tree --no-commit-id --name-only -r $(git rev-parse --verify HEAD) | grep \\\.go | xargs --no-run-if-empty gofmt -s -w
}
alias gof=git-gofmt

# Run go lint on all .go files from the HEAD commit
function git-golint() {
    git diff-tree --no-commit-id --name-only -r $(git rev-parse --verify HEAD) | grep \\\.go | xargs -L 1 --no-run-if-empty golint
}
alias gol=git-golint

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
alias sk='sudo -sE'
alias time='/usr/bin/time'
alias ftime='time -f "REAL:\t\t%e\nSYSTEM\t\t%S\nUSER\t\t%U\nCPU:\t\t%P\nMAX_RSS:\t%M\nCTX_INV:\t%c\nCTX_VOL:\t%w\nIO_IN:\t\t%I\nIO_OUT:\t\t%O\nMAJ_PF:\t\t%F\nMIN_PF:\t\t%R\nSWAPS:\t\t%W"'

# Open the manual page for the last command you executed.
function lman {
    set -- $(fc -nl -1);
    while [ $# -gt 0 -a '(' "sudo" = "$1" -o "-" = "${1:0:1}" ')' ]; do
        shift;
    done;
    cmd="$(basename "$1")";
    man "$cmd" || help "$cmd";
}

alias term='gnome-terminal &'

# apt and dpkg
alias apt='sudo apt'
alias apt-get='sudo apt-get'
alias ard='apt-cache rdepends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances --installed --recurse'

#
function dpkg-query-size {
    dpkg-query -Wf '${Installed-Size}\t${Package}\n'
}
alias dq='dpkg-query-size'
alias dqs='dq | sort -n'
alias dg='dq | grep'
alias di='sudo dpkg -i'

function dpkg-purge {
    dpkg --list | grep "^rc" | cut -d " " -f 3 | xargs sudo dpkg --purge
}

# systemd
alias sys='sudo systemctl'
alias failed='sys list-units --state=failed'
alias services='sys list-unit-files --type=service'

# List all UDP/TCP ports
alias ports='netstat -tulanp'

# ls
alias ls='ls -aF --color=always'
alias ll='ls -l'

# clear
alias c='clear'
alias cls='c;ls'
alias cll='c;ll'

# dmesg
alias dm='dmesg'
alias dmc='sudo dmesg -c'

# disk usage
alias dus='df -hT'

# grep
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# find
alias rfind='sudo find / -name 2> /dev/null'

# ps
alias ps='ps -a --forest -o user,pid,ppid,%cpu,%mem,vsz,rss,cmd'
alias psm='ps -e | sort -nr -k 5 | head -10 | cut -c-$COLUMNS'
alias psc='ps -e | sort -nr -k 4 | head -10 | cut -c-$COLUMNS'
alias psg='ps -e | grep -v grep | grep -v -- --forest | expand | cut -c-$COLUMNS | grep -i -e VSZ -e'

# Show which commands are being used the most
alias bu='cut -f1 -d" " ~/.bash_history | sort | uniq -c | sort -nr | head -n 30'

# Shortcuts for moving up directories
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Typos
alias cd..="cd .."

# Direct navigation to go directories
alias so='cd -P ~/Development/go/src'
alias gh='cd -P ~/Development/go/src/github.com'

# Direct navigation to misc directories
alias dl='cd -P ~/Downloads'

alias mkdir='mkdir -p'
function mcd() {
    mkdir $1
    cd $1
}

function extract() {
    if [ -z "$1" ]; then
        # display usage if no parameters given
        echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
    else
        if [ -f $1 ] ; then
            FILE=$(readlink -f "$1")

            NAME=${1%.*}
            NAME=${NAME%.tar}
            mkdir $NAME && cd $NAME

            case $1 in
              *.tar.bz2)   tar xjf $FILE     ;;
              *.tar.gz)    tar xzf $FILE     ;;
              *.tar.xz)    tar xJf $FILE     ;;
              *.lzma)      unlzma $FILE      ;;
              *.bz2)       bunzip2 $FILE     ;;
              *.rar)       unrar x -ad $FILE ;;
              *.gz)        gunzip $FILE      ;;
              *.tar)       tar xf $FILE      ;;
              *.tbz2)      tar xjf $FILE     ;;
              *.tgz)       tar xzf $FILE     ;;
              *.zip)       unzip $FILE       ;;
              *.Z)         uncompress $FILE  ;;
              *.7z)        7z x $FILE        ;;
              *.xz)        unxz $FILE        ;;
              *.exe)       cabextract $FILE  ;;
              *)           echo "extract: '$1' - unknown archive method" ;;
            esac
        else
            echo "$1 - file does not exist"
        fi
    fi
}
