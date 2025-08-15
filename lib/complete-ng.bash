# complete-ng : bash completion nextgen
# Author : Franck Jouvanceau

declare -F selector >/dev/null 2>&1 || . "$(\cd "${BASH_SOURCE%/*}";pwd)/lib/selector"

#unalias complete 2>/dev/null
#alias complete=complete-ng

_complete-ng_navigate() {
  local dir=$1 IFS="$IFS"
  [[ "$dir" = \~/* ]] && dir="$HOME/"${dir#\~/}
  [ -d "$dir" ] || return 1
  dir=$(\cd "$dir" >/dev/null 2>&1 && pwd) || return 1
  [[ $dir = $PWD* ]] && dir="${dir#$PWD}" && dir="${dir#/}"
  [ "$dir" ] && dir="${dir%/}/"
  [[ "$dir" = $HOME/* ]] && dir="~/${dir#$HOME/}"
  IFS='\n' _items=( "$(compgen -f -- "$dir"|sort -u)" ) IFS=$' \t\n'
  [ "$_items" ] || _items="${dir%/}/"
  _items_ori="$_items"
  return 0
}

_complete-ng_key() {
  local k="$1" item="${_aitems[$_nsel]}"
  [[ "$item" = \~* ]] && item="$(IFS=;eval printf %s '~'$(printf %q ${item#\~}))"
  [[ "$item" = \$[A-Za-z0-9_]* ]] && item="$(IFS=;eval printf %s '$'$(printf %q ${item#\$}))"
  case "$k" in
    $'\t') # tab
      selected="$item"
      return 1
    ;;
    '[C'|OC) # right
      _complete-ng_navigate "$item" || return 3
      return 0
    ;;
    '[D'|OD) # left
      [ -e "$item" ] || return 3
      [[ "$item" = */* ]] && item="${item%/*}" || item=.
      _complete-ng_navigate "$item/.." || return 3
      return 0
    ;;
    '²')
      _items=$(printf "%s\n" "${_aitems[@]}"|egrep -v '^\.[^/]|/\.')
      [ "$_items" ] || return 1
      return 0
    ;;
    'OR') # F3
      _force_nsel=$_nsel
      [ -r "$item" ] && [ -f "$item" ] || return 0
      ${PAGER:-less -+EX} "$item"
      tput civis
      return 0
    ;;
    'OS') # F4
      _force_nsel=$_nsel
      [ -r "$item" ] && [ -f "$item" ] || return 0
      ${EDITOR:-vi} "$item"
      tput civis
      return 0
    ;;
  esac
  return 2
}

_complete-ng() {
  local cmd="${COMP_WORDS[O]}" fn IFS="$IFS" opt="-f" word="" selopt='-o filenames' longword
  [ "${#COMP_WORDS[@]}" -gt 0 ] && word="${COMP_WORDS[$COMP_CWORD]}"
  fn=$(eval printf '%s' '$'_compfunc_"${cmd//[^a-zA-Z0-9_]/_}")
  [ "$fn" ] || { cmd="${cmd##*/}"; fn=$(eval printf '%s' '$'_compfunc_"${cmd//[^a-zA-Z0-9_]/_}"); }
  [ "$fn" ] || {
    [ "$_compfunc__D" ] && {
        $_compfunc__D "$@" # _completion_loader
        fn=$(eval printf '%s' '$'_compfunc_"${cmd//[^a-zA-Z0-9_]/_}")
    }
  }
  [ "$fn" ] && { $fn "$@"; } || {
    type "compopt" >/dev/null 2>&1 && compopt -o filenames 2>/dev/null || \
        compgen -f /non-existing-dir/ >/dev/null
    [ "$COMP_CWORD" -le 0 ] && [ "$word" ] && opt="-c"
    set -f
    : ${word:=./}
    IFS=$'\n' COMPREPLY=( $(compgen $opt -- "$word") ) IFS=$' \t\n'
    set +f
  }
  [ "${#COMPREPLY[@]}" = 1 ] && return
  IFS='[;' read -rsd R -p $'\e[6n' _ row col
  printf "\n" >&2
  [ "${#COMPREPLY[@]}" = 0 ] && {
    [ "$fn" ] && {
      type "compopt" >/dev/null 2>&1 && compopt -o filenames 2>/dev/null || \                                                                                         compgen -f /non-existing-dir/ >/dev/null
      set -f
      IFS=$'\n' COMPREPLY=( $(compgen -f -- "$word") ) IFS=$' \t\n'
      set +f
    }
    [ "${#COMPREPLY[@]}" = 0 ] && {
      printf 'Not found !\r'
      sleep "0.2"
      tput "el"
      tput "cuu1"
      tput "cuf" "$((col-1))" >&2
      return 1
    }
  }
  type "compopt" &>/dev/null && { [[ $(compopt) = *-o\ filename* ]] || selopt=''; }
  # longest common prefix
  longword="$(printf "%s\n" "${COMPREPLY[@]}"|sed -e '$!{N;s/^\(.*\).*\n\1.*$/\1\n\1/;D;}')"
  [ "$longword" ] || longword="$word"
  set -f
  COMPREPLY=( "$(SELECTOR_CASEI="$COMPLETE_NG_CASEI" selector -m 10 -k _complete-ng_key $selopt -i "$(printf "%s\n" "${COMPREPLY[@]}"|sort -u)" -F "$longword")" )
  set +f
  #kill -WINCH $$ # force redraw prompt
  tput "cuu1"
  tput "cuf" "$((col-1))" >&2
  [ ! "${COMPREPLY[0]}" ] && {
    compopt +o "filenames" -o "nospace" 2>/dev/null
    [ "$word" != "$longword" ] && COMPREPLY=( "$longword" ) && return 0
    # bash 5+ : COMPREPLY must be empty else next tab completion will be COMP_TYPE=63 and COMPREPLY will be ignored
    COMPREPLY=()
    [ "${BASH_VERSION%%.*}" -ge 5 ] && return 1
    # bash <5 : COMPREPLY must change else next tab completion will be COMP_TYPE=63 and COMPREPLY will be ignored
    [ "${BASH_VERSION%%.*}" = 4 ] && COMPREPLY=( " $word" ) || COMPREPLY=( "${COMP_WORDS[$COMP_CWORD]}%" )
    return 0
  }
  #COMPREPLY[0]="${COMPREPLY[0]//\\$/$}"
}

complete() {
  local fn func cmd exc="^(_complete-ng|${COMPLETE_NG_EXCLUDE// /|})$" _i
  for _i in "$@";do
    [ "$fn" ] && {
      unset fn
      ! [[ $1 =~ $exc ]] && { func="$1"; shift; set -- "$@" _complete-ng; continue; }
    }
    [ "$1" = -- ] || cmd+=("$1")
    [ "$1" = "-F" ] && fn=1 && cmd=()
    set -- "$@" "$1"
    shift
  done
  [[ "$*" =~ -F\ [^\ ]*$ ]] && set -- "$@" "''" && cmd=( "" )
  [ "$func" ] && {
    local c skip
    for c in "${cmd[@]}";do
      [ "$c" = -o ] && skip=1 && continue
      [ "$skip" ] && skip="" && continue
      eval "_compfunc_${c//[^a-zA-Z0-9_]/_}=$func"
    done
  }
  unset _compfunc_
  builtin complete "$@"
}

_complete-ng_init() {
  bind -v |grep -q 'completion-ignore-case on' && COMPLETE_NG_CASEI=true || COMPLETE_NG_CASEI=false
  if cat <(printf %s) 2>/dev/null && [ "${BASH_VERSION%%.*}" -ge 4 ];then
    source <(builtin complete |sed -n -e '/-F _complete-ng /d' -e '/-F/p')
  else # process substitution not working (ish/bash 3.2)
    builtin complete |sed -n -e '/-F _complete-ng /d' -e '/-F/p' >/tmp/.complete-ng.tmp.$$
    source /tmp/.complete-ng.tmp.$$
    \rm -f /tmp/.complete-ng.tmp.$$
  fi
  builtin complete -F _complete-ng -D 2>/dev/null
  builtin complete -F _complete-ng -I 2>/dev/null
  builtin complete -F _complete-ng -E 2>/dev/null
  builtin complete -F _complete-ng ''
}

: ${COMPLETE_NG_EXCLUDE:=_cdhist_cd}
type cdcomplete >/dev/null 2>&1 && cdcomplete
_complete-ng_init

