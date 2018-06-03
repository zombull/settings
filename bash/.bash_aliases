# Refresh bash terminal
alias rf='source ~/.bashrc'

# -----------------------------------------------------------------------------
# Floating Castle
# -----------------------------------------------------------------------------
alias ff='floating-castle'
alias fs='ff serve'
alias fs3='fs -p 3000'
alias fu='ff cache -u'
alias fm='ff moon'

function floating-castle-gulp() {
    pushd ~/Development/go/src/github.com/zombull/floating-castle/server > /dev/null
    gulp
    popd
}
alias fsg='floating-castle-gulp'

function floating-castle-restart() {
    pushd ~/Development/go/src/github.com/zombull/floating-castle > /dev/null
    set -o xtrace
    go install -v && cd server && gulp && systemctl restart fc
    set +o xtrace
    popd
}
alias fsr='floating-castle-restart'

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
    if [ $# -eq 0 ]; then
        git am -3 ~/mutt/*.patch
    else
        git am -3 $1/*.patch
    fi
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

function git-push() {
    local opts
    local response=y
    local branch=$(git rev-parse --abbrev-ref HEAD)
    local remote
    local upstream
    if [[ $# -eq 1 && $1 != "force" ]]; then
        remote=$1
        upstream=$branch
    else
        remote=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} | cut -f 1 -d /)
        if [[ $? -eq 0 ]]; then
             upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} | cut -f 2- -d /)
        else
            printf "No remote configured or specified\n"
            return 1
        fi
    fi

    local exists=$(git ls-remote --heads $remote $upstream | wc -l)
    if [[ $exists == "0" ]]; then
        printf "\e[1;7;35mCreate and track remote branch $remote/$upstream? "
        read -r -p "[Y/n] " response
    elif [[ $exists != "1" ]]; then
        printf "Found multiple ($exists) branches: $upstream\n"
        return 1
    elif [[ $1 == "force" ]]; then
        opts="-f"
        git status
        printf "\e[1;7;35mForce push $branch to $remote/$upstream? "
        read -r -p "[Y/n] " response
        printf "\e[0m"
    fi
    response=${response,,}    # tolower
    if [[ -z $response || $response =~ ^(yes|y)$ ]]; then
        git push $opts $remote $branch:$upstream
        git branch --set-upstream-to=$remote/$upstream
    fi
}

function git-get-branch() {
    if [[ $# -eq 1 ]]; then
        git checkout -b $1 origin/$1
    elif [[ $# -eq 2 ]]; then
        git checkout -b $1 $2
    else
        printf "git-get-branch <branch> [remote]\n"
        return 1
    fi
}

function git-get-prefixed-branch() {
    git checkout $1/$2
}

function git-url-patch() {
    # lynx -dump -nonumbers -hiddenlinks=liston $1 | grep -e "^http.*00(0[1-9]|1[0-7])\.patch" | xargs -n 1 curl -s | git am
    lynx -dump -nonumbers -hiddenlinks=liston $1 | grep -e "^http.*003[0-9].*\.patch" | xargs -n 1 curl -s | git am
}

. $SETTINGS/git/.git-completion.bash

# Add git completion to aliases
__git_complete g __git_main
__git_complete gb _git_branch
__git_complete ggb _git_branch

__git_complete gc _git_commit
__git_complete gd _git_diff
__git_complete ge _git_send_email
__git_complete gf _git_fetch
__git_complete gg _git_checkout
__git_complete gfp _git_format_patch
__git_complete gl _git_log
__git_complete glo _git_log
__git_complete gp _git_cherry_pick
__git_complete gr _git_reset
__git_complete gs _git_log

alias g='git'
alias ga='git add'
alias gb='git branch'
alias gbg='git branch -r | grep'
alias gbgo='git branch -r | grep origin'
alias gc='git commit'
alias gd='git-diff'
alias gdd='git diff'
alias gds='git diff --staged'
alias ge='git-email'
alias gf='git fetch'
alias gfo='git fetch origin'
alias gfp='nosend=1 git-email'
alias gft='git fetch --tags'
alias gg='git checkout'
alias ggb='git-get-branch'
alias ggd='gs | grep deleted: | cut -f 2 | tr -s " " | cut -f 2 -d " " | xargs git checkout'
alias gl='git log --decorate'
alias glo='git log --pretty=oneline --decorate'
alias gm="git status | grep modified | tr -d '\t' | tr -d ' ' | cut -f 2 -d :"
alias gw="git show -s --pretty='tformat:%h (%s, %ad)' --date=short"
alias gwp="git show -s --pretty='tformat:%h, %s, %ad' --date=short"
alias gpa='git-apply'
alias gpu='git-push'
alias gpo='git-push origin'
alias gpf='git-push force'
alias gp='git cherry-pick'
alias gpc='git cherry-pick --continue'
alias gpl='git-cherry-pick-log'
alias gps='git-cherry-pick-show'
alias gr='git reset'
alias grh='git reset HEAD'
alias grhh='git reset HEAD --hard'
alias grc='git rebase --continue'
alias gri='git rebase --interactive'
alias gu='git pull'
alias gs='git status'
alias gsa='git stash apply'
alias gsdd='git stash drop'
alias gsl='git stash list'
alias gso='git stash show'
alias gsop='git stash show -p'
alias gsp='git stash pop'
alias gss='git stash save'
alias gt='git-tree'
alias gv='git remote -vv'


# -----------------------------------------------------------------------------
# Go
# -----------------------------------------------------------------------------
# Run gofmt on all .go files from the HEAD commit
function git-gofmt() {
    git diff-tree --no-commit-id --name-only -r $(git rev-parse --verify HEAD) | grep \\\.go | xargs --no-run-if-empty gofmt -s -w
}

# Run go lint on all .go files from the HEAD commit
function git-golint() {
    git diff-tree --no-commit-id --name-only -r $(git rev-parse --verify HEAD) | grep \\\.go | xargs -L 1 --no-run-if-empty golint
}

alias goi='go install -v'
alias gou='go get -u -v ./...'
alias gof='git-gofmt'
# Ignore comment, caps, ID and URL warnings
alias gol='git-golint | grep -v -e "should have comment" -e ALL_CAPS -e Id -e Url'

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
alias ipa="ifconfig | grep 10.54 | tr -s ' ' | cut -f 3 -d ' ' | cut -f 2 -d :"
alias sk='sudo -sE'
alias sbn='sudo reboot now'
alias sbf='sudo reboot -f'
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
alias ard='apt-cache rdepends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances --installed --recurse'
alias ai='sudo apt install'
alias ad='sudo apt update'
alias ap='sudo apt purge'
alias au='sudo apt upgrade'

#
function dpkg-query-size {
    dpkg-query -Wf '${Installed-Size}\t${Package}\n'
}
alias dq='dpkg-query-size'
alias dqs='dq | sort -n'
alias dg='dq | grep'
alias di='sudo dpkg -i'
alias ds='dpkg -S'

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
alias ll='ls -lh'

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
alias zz='cd -P ~/Development/go/src/github.com/zombull'
alias se='cd -P ~/Development/go/src/github.com/zombull/settings'

# Direct navigation to misc directories
alias dl='cd -P ~/Downloads'

# Kernel grep and gdb commands
alias gk='readelf -s vmlinux | grep'

function gdb-disassemble() {
    gdb -batch -ex "file $1" -ex "disassemble $2"
}
alias dis='gdb-disassemble'

function gdb-kernel {
    gdb-disassemble vmlinux $1
}
alias dk='gdb-kernel'

alias mkdir='mkdir -p'
function mcd() {
    mkdir $1
    cd $1
}

function pushd() {
    command pushd "$@" > /dev/null
}

function popd() {
    command popd "$@" > /dev/null
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

function system-info() {
    printf "IP Address:\t       $(ipa)\n"
    printf "Kernel:\t\t       $(uname -r)\n"
}
alias si='system-info'

function system-info-verbose() {
    printf "IP Address:\t       $(ipa)\n"
    printf "Kernel:\t\t       $(uname -r)\n"
    printf "Date:\t\t       $(date)\n"
    printf "Uptime:\t\t      $(uptime)\n"
    lscpu | grep -v Architecture | grep -v "Byte Order" | grep -v op-mode | grep -v BogoMIPS | grep -v Virtualization | grep -v Flags | grep -v On-line
}
alias siv='system-info-verbose'
