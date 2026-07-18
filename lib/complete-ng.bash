# complete-ng : bash completion nextgen
# Author : Franck Jouvanceau

. "$(\cd "${BASH_SOURCE%/*}";pwd)/comphelp"
declare -F selector >/dev/null 2>&1 || . "$(\cd "${BASH_SOURCE%/*}";pwd)/lib/selector"

#unalias complete 2>/dev/null
#alias complete=complete-ng

_arrayread() {
    local IFS=$'\n'
    set -f; eval "$1"'=($(cat))'; set +f
}

_complete-ng_key() {
  case "$key" in
    '[19~'|$'\x04'|'[3~') # F8 Ctl-D Del
      [ "$COMP_DELFUNC" ] && $COMP_DELFUNC "$item"
    ;;
    'alt-i') ((COMPLETE_NG_CASEI)) && COMPLETE_NG_CASEI=0 || COMPLETE_NG_CASEI=1;;
  esac
  return 2
}

_complete-ng() {
  local cmd="${COMP_WORDS[O]#\\}" fn IFS="$IFS" opt="-f" word="" selopt=(-o filenames) longword sortcmd=(sort -u) COMP_SORT=1 COMP_DELFUNC='' row col selected compgen_opt='-f'
  ((${#COMP_WORDS[@]} > 0)) && word="${COMP_WORDS[$COMP_CWORD]}"
  ((COMP_CWORD==0)) && opt="-c" && [[ $cmd != [./]* ]] && selopt=() # complete command
  fn=$(eval printf '%s' '$'_compfunc_"${cmd//[^a-zA-Z0-9_]/_}")
  [ "$fn" ] || { cmd="${cmd##*/}"; fn=$(eval printf '%s' '$'_compfunc_"${cmd//[^a-zA-Z0-9_]/_}"); }
  [ "$fn" ] || {
    [ "$_compfunc__D" ] && {
        $_compfunc__D "$@" # _completion_loader
        fn=$(eval printf '%s' '$'_compfunc_"${cmd//[^a-zA-Z0-9_]/_}")
    }
  }
  declare -F "__${cmd}_format_comp_descriptions" >/dev/null && eval "__${cmd}_format_comp_descriptions"'() { :; }'
  [ "$cmd" = 'cd' ] && compgen_opt='-d' && selopt=(-o dirnames)
  [ "$fn" ] && $fn "$@"
  ((${#COMPREPLY[@]} > 0)) || {
    type "compopt" >/dev/null 2>&1 && compopt -o filenames 2>/dev/null || \
        compgen -f /non-existing-dir/ >/dev/null
    _arrayread COMPREPLY < <(compgen $opt -- "$word")
  }
  [ "${#COMPREPLY[@]}" = 1 ] && COMPREPLY=("${COMPREPLY%%$'\t'*}") && return
  [ "$COMP_SORT" ] || sortcmd=(cat)
  IFS='[;' read -rsd R -p $'\e[6n' _ row col
  printf "\n" >&2
  [ ! "$COMPREPLY" ] && {
    [ "$fn" ] && {
      type "compopt" >/dev/null 2>&1 && compopt -o filenames 2>/dev/null || \
          compgen -f /non-existing-dir/ >/dev/null
      _arrayread COMPREPLY < <(compgen -f -- "$word")
    }
    [ ! "$COMPREPLY" ] && {
      printf 'Not found !\r' >&2
      sleep "0.2"
      _sel_tput "el" >&2
      _sel_tput "cuu1" >&2
      _sel_tput "cuf" "$((col-1))" >&2
      return 1
    }
  }
  type "compopt" &>/dev/null && { [[ $(compopt) = *-o\ filename* ]] || selopt=(); }
  ((COMP_CWORD==-1)) && compopt +o filenames # -1 empty command
  # longest common prefix
  longword="$(printf "%s\n" "${COMPREPLY[@]}"|sed -e 's/\t.*//' -e '$!{N;s/^\(.*\).*\n\1.*$/\1\n\1/;D;}')"
  [ "$longword" ] || longword="$word"
  comphelp
  SELECTOR_CASEI="$COMPLETE_NG_CASEI" selector -q -m 10 -k _complete-ng_key "${selopt[@]}" -F "$longword" -f <(printf "%s\n" "${COMPREPLY[@]}"|"${sortcmd[@]}") && COMPREPLY=("$selected") || COMPREPLY=()
  #kill -WINCH $$ # force redraw prompt
  _sel_tput "cuu1" >&2
  _sel_tput "cuf" "$((col-1))" >&2
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
  bind -v |grep -q 'completion-ignore-case on' && COMPLETE_NG_CASEI=1 || COMPLETE_NG_CASEI=0
  if cat <(:) 2>/dev/null && [ "${BASH_VERSION%%.*}" -ge 4 ];then
    source <(builtin complete |sed -n -e '/-F _complete-ng /d' -e '/-F/p')
  else # process substitution not working (ish/bash 3.2)
    builtin complete |sed -n -e '/-F _complete-ng /d' -e '/-F/p' >/tmp/.complete-ng.tmp.$$
    source /tmp/.complete-ng.tmp.$$
    \rm -f /tmp/.complete-ng.tmp.$$
  fi
  builtin complete -D -F _complete-ng 2>/dev/null
  builtin complete -I -F _complete-ng 2>/dev/null
  builtin complete -E -F _complete-ng 2>/dev/null
  builtin complete -F _complete-ng ''
}

: "${COMPLETE_NG_EXCLUDE:=_cdhist_cd}"
#type cdcomplete >/dev/null 2>&1 && cdcomplete
_complete-ng_init

