#!/usr/bin/env bash
# ls+ - enhanced ls with icons and colors
# author: joknarf
# usage: ls+ [-T] [ls options]
#

usage() {
    printf "%s\n" "usage: ls+ [-T [TREEOPTION]...] [LSOPTION]... [FILE]... 
ls+: ls/tree decorator
ls+ takes same arguments as ls command (with few limitations)
Additional parameters:
    --P=<pattern> limit files matching pattern (eg. --P=*.py or --P='*.c|*.h')
    --I=<patern> hide files matching pattern (eg. --I=*.tmp)
    --find=<pattern> display full path files matching pattern
    -L <maxlevel> limit tree depth for tree view (needs -T)
    -f full file path in tree (needs -T)
    --noprune when -I or -P show directories without matching entries (needs -T)
Environment var:
    LSI_HIDE_TREE=<pattern> : can be set to default hide dir/files matching pattern in tree
    eg.: export LSI_HIDE_TREE='__pycache__|venv'

"
    $ls --help
    exit 0
}
ls="ls"
type gls >/dev/null 2>&1 && ls="gls"
type gnuls >/dev/null 2>&1 && ls="gnuls"
awk=awk
type gawk >/dev/null 2>&1 && awk="gawk"
USER_GROUPS=$(id -Gn 2>/dev/null)
USER_ID=$(id -un 2>/dev/null)
COLOR=''
ARGSLS=("$@")
ARGS=("-lFQ" "--color" "--time-style=+%y-%m-%d %H:%M")
ARGSTR=(-pugsDFQ --du --timefmt='%y-%m-%d %H:%M' -C)
FLAGS=()
TREE=false
get_args() {
    args=()
    _flags=()
    while [ "$1" ];do
      case "$1" in
      --) args+=("$@");break;;
      --?=*) args+=("${1:1:2}" "${1:4}");_flags+=("${1:1:2}");;
      --*) args+=("$1");_flags+=("${1%%=*}");;
      -?) args+=("$1");_flags+=("$1");;
      -*) a="${1#-}"; while [ "$a" ] ;do args+=("-${a:0:1}"); _flags+=("-${a:0:1}");a="${a:1}";done;;
      *) args+=("$1");;
      esac
      shift
    done
}
is_flag() {
    re=" ($1) "
    [[ " ${_flags[@]} " =~ $re  ]]
}
get_args "$@"
set -- "${args[@]}"
is_flag '-T|--tree|--find' && {
    TREE=true
    is_flag -P && ! is_flag --noprune && ARGSTR+=(--prune)
    [ "$LSI_HIDE_TREE" ] && ! is_flag -I && ARGSTR+=(-I "$LSI_HIDE_TREE")
}
shopt -s extglob
while [ "$1" ];do
    case "$1" in
        --help|--version) usage "$1";;
        --) break ;;
        -T|--tree) shift;continue ;;
        -l|--format=long) FLAGS+=(l) ;;
        -1|--format=single-column) FLAGS+=(1) ;;
        -t|-c) ARGSTR+=("$1");$TREE && ! is_flag -r && ARGSTR+=(-r);;
        -r) $TREE && ! is_flag '-t|-c' && ARGSTR+=(-r);;
        -h|--human-readable) ARGSTR+=(-h);;
        -a|--all) ARGSTR+=(-a);;
        -d|--directory) ARGSTR+=(-d);;
        --format=*) shift;continue;;
        --color*always|--color|-C) COLOR=true; shift;continue ;;
        --color*never) COLOR=false; shift;continue ;;
        --color=*|-w|--width*|--zero|-b) shift;continue;;
        --indicator-style*|-m|-N|-p) shift;continue;;
        --time-style*|--quoting-style*|--width*) shift;continue;;
        -g) FLAGS+=(g);shift;continue;;
        -G|--no-group) FLAGS+=(G);shift;continue;;
        -o) FLAGS+=(l G);shift;continue;;
        -Z|--context) FLAGS+=(Z) ;;
        -U|-v|-L|--si) ARGSTR+=("$1");;
        -P) ARGSTR+=("$1" "$2");FLAGS+=(P);PATTERN="$2";shift 2;continue;;
        -I) ARGS+=("$1" "$2");ARGSTR+=("$1" "$2${LSI_HIDE_TREE:+|$LSI_HIDE_TREE}");shift 2;continue;;
        -f|--prune) ARGSTR+=("$1");shift;continue;;
        -i|--inode) FLAGS+=(i);ARGSTR+=(--inodes) ;;
        --dereference-command-line-symlink-to-dir) ARGSTR+=(-l);;
        --group-directories-first) ARGSTR+=(--dirsfirst);;
        -S) ARGSTR+=(--sort=size);;
        --ignore=*|--hide=*) ARGSTR+=(-I "${1#*=}");;
        --sort=time) ARGSTR+=(-t);_flags+=(-t);! is_flag -r && ARGSTR+=(-r);;
        --sort=none) ARGSTR+=(-U);;
        --sort=!(extension|width)) ARGSTR+=("$1");;
        -s|--size) FLAGS+=(s) ;;
        -n|--numeric-uid-gid) $TREE || { USER_GROUPS=$(id -G); USER_ID=$(id -u); };;
        -z|--zeroindent) ARGSTR+=(-i);shift;continue;;
        --find=*) PATTERN="${1#*=}";ARGSTR+=(-ifP "$PATTERN");FLAGS+=(P F);shift;continue;;
        [!-]*) ARGSTR+=("$1");;
    esac
    ARGS+=("$1")
    shift
done
ARGS+=("$@");ARGSTR+=("$@")
[ ! "$COLOR" ] && [ ! -t 1 ] && COLOR=false || COLOR=true
! $COLOR && ! $TREE && exec $ls "${ARGSLS[@]}"
[ -r ~/.config/ls+/icons ] && ICON_FILE=~/.config/ls+/icons
[ -r ~/.config/ls+/colors ] && COLOR_FILE=~/.config/ls+/colors
[ -r ~/.config/ls+/theme ] && THEME_FILE=~/.config/ls+/theme
LSI=$(readlink -f $0);LSI=${LSI%/*}
: "${ICON_FILE:=$LSI/ls+.icons}"
: "${COLOR_FILE:=$LSI/ls+.colors}"
: "${THEME_FILE:=$LSI/ls+.theme}"
read _ TERM_COLS <<<$(stty size 2>/dev/null)
: ${TERM_COLS:=80}
# ls/tree is missing an indicator for broken symlink, use color to get it
set -o pipefail
if $TREE ;then
    export LS_COLORS="rs=0:di=0:ln=0:mh=0:pi=0:so=0:do=0:bd=0:cd=0:or=1:mi=0:su=0:sg=0:ca=0:tw=0:ow=0:st=0:ex=0:"
    export TREE_COLORS="$LS_COLORS"
    tree "${ARGSTR[@]}" |$awk -v TERMW="$TERM_COLS" -v FLAGS="${FLAGS[*]}" -v iconfile="$ICON_FILE" -v colorfile="$COLOR_FILE" \
        -v themefile="$THEME_FILE" -v USER="$USER_ID" -v GROUPS="$USER_GROUPS" -v PATTERN="$PATTERN" -f "$LSI/ls+.com.awk" -f "$LSI/ls+.tree.awk"
else
    export LS_COLORS="rs=:di=:ln=:mh=:pi=:so=:do=:bd=:cd=:or=:mi=1:su=:sg=:ca=:tw=:ow=:st=:ex=:"
    $ls -1 "${ARGS[@]}" 2>&1 | $awk -v TERMW="$TERM_COLS" -v FLAGS="${FLAGS[*]}" -v iconfile="$ICON_FILE" -v colorfile="$COLOR_FILE" \
        -v themefile="$THEME_FILE" -v USER="$USER_ID" -v GROUPS="$USER_GROUPS" -v PATTERN="$PATTERN" -f "$LSI/ls+.com.awk" -f "$LSI/ls+.awk"
fi
