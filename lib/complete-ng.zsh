# set ft=zsh
[ "${ZSH_VERSION%%.*}" -lt 5 ] && return
type selector >/dev/null 2>&1 || . "$(cd "${0%/*}";pwd)/lib/selector"
# Based on https://github.com/lincheney/fzf-tab-completion
# use a whitespace char or anchors don't work
_COMPLETE_NG_SEP=$'\u00a0'
_COMPLETE_NG_SPACE_SEP=$'\v'
_COMPLETE_NG_NONSPACE=$'\u00ad'
_COMPLETE_NG_FLAGS=( a k f q Q e n U l 1 2 C )
_comps[cdpush]=_cd

zmodload zsh/zselect
zmodload zsh/system

_complete_ng_awk="$( builtin command -v gawk &>/dev/null && echo gawk || echo awk )"
_complete_ng_grep="$( builtin command -v ggrep &>/dev/null && echo ggrep || echo grep )"

repeat-complete-ng() {
    __repeat=1
    __query="$1"
}

complete_ng() {
    local __repeat=1 __code= __action= __query=
    while (( __repeat )); do
        __code=
        __repeat=0
        __action=
        # run the actual completion widget
        zle _complete_ng

        if [[ -n "$__action" ]]; then
            eval "$__action"
            zle reset-prompt
        fi
    done
}

_complete_ng() {
    emulate -LR zsh +o ALIASES
    setopt interactivecomments
    local __value= __stderr=
    local __compadd_args=()

    __code=
    __stderr=
    if zstyle -t ':completion:' show-completer; then
        zle -R 'Loading matches ...'
    fi

    eval "$(
    local _com_sentinel1=b5a0da60-3378-4afd-ba00-bc1c269bef68
    local _com_sentinel2=257539ae-7100-4cd8-b822-a1ef35335e88
    (
        # set -o pipefail
        # hacks
        __override_compadd() { compadd() { _complete_ng_compadd "$@"; }; }
        __override_compadd
        # some completions change zstyle so need to propagate that out
        zstyle() { _complete_ng_zstyle "$@"; }

        # massive hack
        # _approximate also overrides _compadd, so we have to override their one
        __override_approximate() {
            functions[_approximate]="unfunction compadd; { ${functions[_approximate]//builtin compadd /_complete_ng_compadd } } always { __override_compadd }"
        }

        if [[ "$functions[_approximate]" == 'builtin autoload'* ]]; then
            _approximate() {
                unfunction _approximate
                printf %s\\n "builtin autoload +XUz _approximate" >&"${__evaled}"
                builtin autoload +XUz _approximate
                __override_approximate
                _approximate "$@"
            }
        else
            __override_approximate
        fi

        # all except autoload functions
        local __full_variables="$(typeset -p)"
        local __full_functions="$(functions + | "$_complete_ng_grep" -F -vx -e "$(functions -u +)")"
        local __autoload_variables="$(typeset + | "$_complete_ng_grep" -F -e 'undefined ' | "$_complete_ng_awk" '{print $NF}')"

        # do not allow grouping, it stuffs up display strings
        builtin zstyle ":completion:*:*" list-grouped no

        local curcontext="${curcontext:-}"
        local _COMPLETE_NG_CONTEXT
        _COMPLETE_NG_CONTEXT="${compstate[context]//_/-}"
        _COMPLETE_NG_CONTEXT="${_COMPLETE_NG_CONTEXT:+-$_COMPLETE_NG_CONTEXT-}"

        if [[ "$_COMPLETE_NG_CONTEXT" = -value- ]]; then
            _COMPLETE_NG_CONTEXT="${_COMPLETE_NG_CONTEXT:-*}:${compstate[parameter]}:"
        else
            if [[ "$_COMPLETE_NG_CONTEXT" == -command- && "$CURRENT" > 1 ]]; then
                _COMPLETE_NG_CONTEXT="${words[1]}"
            fi
            _COMPLETE_NG_CONTEXT="${_COMPLETE_NG_CONTEXT:-*}::${(j-,-)words[@]}"
        fi
        _COMPLETE_NG_CONTEXT=":completion:${curcontext}:complete:$_COMPLETE_NG_CONTEXT"

        set -o monitor +o notify
        exec {__evaled}>&1
        trap '' INT
        coproc (
            (
                local __comp_index=0 __autoloaded=()
                exec {__stdout}>&1
                __stderr="$(
                    _complete_ng_preexit() {
                        trap -
                        functions + | "$_complete_ng_grep"  -F -vx -e "$(functions -u +)" -e "$__full_functions" | while read -r f; do which -- "$f"; done >&"${__evaled}"
                        # skip local and autoload vars
                        { typeset -p -- $(typeset + | "$_complete_ng_grep" -vF -e 'local ' -e 'undefined ' | "$_complete_ng_awk" '{print $NF}' | "$_complete_ng_grep" -vFx -e "$__autoload_variables") | "$_complete_ng_grep" -xvFf <(printf %s "$__full_variables") >&"${__evaled}" } 2>/dev/null
                    }
                    trap _complete_ng_preexit EXIT TERM

                    # Attempt shell expansion on the current word.  If that fails, attempt completion.
                    if [[ -z "${words[CURRENT]}" ]] || (
                        # produce only one big expansion (instead of individual entries)
                        builtin zstyle ':completion:*' tag-order all-expansions
                        # manually invoke _expand here
                        _expand 2>&1
                        (( compstate[nmatches] == 0 ))
                    ); then
                        _main_complete 2>&1
                    fi

                )"
                printf "__stderr='%s'\\n" "${__stderr//'/'\''}" >&"${__evaled}"
                # if a process forks and it holds onto the stdout handles, we may end up blocking waiting for it to close it
                # instead, the sed q below will quit as soon as it gets a blank line without waiting
                printf '%s\n' "$_COMPLETE_NG_SEP$_com_sentinel1$_com_sentinel2"
            # need to get awk to be unbuffered either by using -W interactive or system("")
            ) | sed -un "/$_com_sentinel1$_com_sentinel2/q; p" \
              | "$_complete_ng_awk" -W interactive -F"$_COMPLETE_NG_SEP" '/^$/{exit}; $1!="" && !x[$1]++ { print $0; system("") }' 2>/dev/null
        )
        coproc_pid="$!"
        __value="$(_complete_ng_selector "$__code" <&p)"
        __code="$?"
        kill -- -"$coproc_pid" 2>/dev/null && wait "$coproc_pid"

        printf "__code='%s'; __value='%s'\\n" "${__code//'/'\''}" "${__value//'/'\''}"
        printf '%s\n' ": $_com_sentinel1$_com_sentinel2"
    ) | sed -un "/$_com_sentinel1$_com_sentinel2/q; p"
    )" 2>/dev/null

    compstate[insert]=unambiguous
    case "$__code" in
        0)
            local opts= index= value o=()
            while IFS="$_COMPLETE_NG_SEP" read -r -A value; do
                if (( !__code && ${#value[@]} >= 3 )); then
                    index="${value[3]}"
                    PREFIX=""
                    eval "opts=( ${__compadd_args[$index]} )"
                    for ((i = 1; i <= $#opts; i++)); do
                        [[ "${opts[$i]}" = (-s|-S|-J|-F|-M) ]] && o+=( "${opts[$i]}" "${opts[$i+1]}" ) && continue
                        [[ "${opts[$i]}" = (-f|-q|-Qf|-l|-U) ]] && o+=( "${opts[$i]}" ) && continue
                        [[ "${opts[$i]}" = (-W) ]] && o+=( "-S" "") && continue
                    done
                    value=( "${value[2]}" )
                    SUFFIX= ISUFFIX= compadd "${o[@]}" -a value
                    #value=( "${(Q)value[2]}" )
                    # eval "$opts -a value"
                fi
            done <<<"$__value"
            # insert everything added by fzf
            compstate[insert]=all
            ;;
        1)
            # run all compadds with no matches, in case any messages to display
            eval "${(j.;.)__compadd_args:-true} --"
            if (( ! ${#__compadd_args[@]} )) && zstyle -s :completion:::::warnings format msg; then
                compadd -x "$msg"
            fi
            compadd -x "$__stderr"
            __stderr=
            ;;
    esac

    # reset-prompt doesn't work in completion widgets
    # so call it after this function returns
    eval "TRAPEXIT() {
        zle reset-prompt
        _complete_ng_post ${(q)__stderr} ${(q)__code}
    }"
}

_complete_ng_post() {
    local stderr="$1" code="$2"
    if [ -n "$stderr" ]; then
        zle -M -- "$stderr"
    elif (( code == 1 )); then
        zle -R ' '
    else
        zle -R ' ' ' '
    fi
}

_complete_ng_selector() {
    local lines=() reply REPLY
    exec {tty}</dev/tty

    while (( ${#lines[@]} < 2 )); do
        zselect -r 0 "$tty"
        if (( reply[2] == 0 )); then
            if IFS= read -r; then
                lines+=( "$REPLY" )
            elif (( ${#lines[@]} == 1 )); then # only one input
                #printf %s\\n "${lines[1]}" && return
                break
            else # no input
                return 1
            fi
        else
            sysread -c 5 -t0.05 <&"$tty"
            [ "$REPLY" = $'\x1b' ] && return 130 # escape pressed
            __query+="$REPLY"
        fi
    done


    local all_lines items longword selected s nbitems
    all_lines=$( (( ${#lines[@]} )) && printf %s\\n "${lines[@]}"; cat)
    items="$(printf %s "$all_lines"|sed -e "s/$_COMPLETE_NG_SEP.*//")" # -e "s/[\\']//g")"
    set -f
    eval "items=( $items )"
    set +f
    nbitems="${#items[@]}"
    items="${(F)items[@]}" # separated by newlines
    if (( nbitems > 1 )); then
        tput cud1 >/dev/tty
        longword="$(printf "%s\n" "${items}"|sed -e '$!{N;s/^\(.*\).*\n\1.*$/\1\n\1/;D;}')"
        selected="$(SELECTOR_CASEI="$COMPLETE_NG_CASEI" selector -m 10 -k _complete-ng_key -i "$items" -o filenames -F "$longword")"
        code="$?"
        tput cuu1 >/dev/tty
    else
       selected="$items"
       code="0"
    fi
    [ ! "$selected" ] && [ "$longword" != "$PREFIX" ] && code="0" && selected="$longword"
    s="${selected}"
    #[[ "$PREFIX" != ..* ]] && s="${selected#${PREFIX%/*}/}"
    # s="${s%/}"
    #s="$(printf '%q' "$(printf '%q' "$s")")"
    s="$(printf '%q' "$s")"
    # s="${s/#\\\\~\//~/}"
    s="${s/#\\~\//~/}"	
    selected="$(printf '%q' "$selected")"
    [ "$selected" ] && printf '%s\n' "$selected$_COMPLETE_NG_SEP$s${_COMPLETE_NG_SEP}1$_COMPLETE_NG_SEP$selected$_COMPLETE_NG_SPACE_SEP"
    return "$code"
}
_complete-ng_navigate() {
  local dir="$1" IFS="$IFS"
  [[ "$dir" = \~/* ]] && dir="$HOME/${dir#\~/}"
  [ -d "$dir" ] || return 1
  dir=$(\cd "$dir" >/dev/null 2>&1 && pwd) || return 1
  [[ $dir = $PWD* ]] && dir="${dir#$PWD}" && dir="${dir#/}"
  [ "$dir" ] && dir="${dir%/}/"
  _items="$(setopt NULL_GLOB; print -rl -- $~dir*|sort -u|sed -e "s#^$HOME/#~/#")"
  [ "$_items" ] || _items="${dir%/}"
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
      less -+EX "$item"
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
_complete_ng_zstyle() {
    if [[ "$1" != -* ]]; then
        { printf 'zstyle %q ' "$@"; printf \\n } >&"${__evaled}"
    fi
    builtin zstyle "$@"
}

_complete_ng_compadd() {
    local __flags=()
    local __OAD=()
    local __disp __hits __ipre __apre __hpre __hsuf __asuf __isuf __opts __optskv
    zparseopts -D -a __opts -A __optskv -- "${^_COMPLETE_NG_FLAGS[@]}+=__flags" F+: P:=__apre S:=__asuf o+:: p:=__hpre s:=__hsuf i:=__ipre I:=__isuf W+: d:=__disp J+: V+: X+: x+: r+: R+: D+: O+: A+: E+: M+:
    local __filenames="${__flags[(r)-f]}"
    local __noquote="${__flags[(r)-Q]}"
    local __is_param="${__flags[(r)-e]}"
    local __no_matching="${__flags[(r)-U]}"

    if [ -n "${__optskv[(i)-A]}${__optskv[(i)-O]}${__optskv[(i)-D]}" ]; then
        # handle -O -A -D
        builtin compadd "${__flags[@]}" "${__opts[@]}" "${__ipre[@]}" "${__hpre[@]}" -- "$@"
        return "$?"
    fi

    if [[ "${__disp[2]}" =~ '^\(((\\.|[^)])*)\)' ]]; then
        IFS=$' \t\n\0' read -A __disp <<<"${match[1]}"
    else
        __disp=( "${(@P)__disp[2]}" )
    fi
    builtin compadd -Q -A __hits -D __disp "${__flags[@]}" "${__opts[@]}" "${__ipre[@]}" "${__apre[@]}" "${__hpre[@]}" "${__hsuf[@]}" "${__asuf[@]}" "${__isuf[@]}" -- "$@"
    # have to run it for real as some completion functions check compstate[nmatches]
    builtin compadd $__no_matching -a __hits
    local __code="$?"
    __flags="${(j..)__flags//[ak-]}"
    if [ -z "${__optskv[(i)-U]}" ] && [[ -n "$__filenames" ]]; then
        # -U ignores $IPREFIX so add it to -i
        # FJO only filenames / set PREFIX to get full path
        # __ipre[2]="${IPREFIX}${__ipre[2]}"
        # __ipre=( -i "${__ipre[2]}" )
        PREFIX="${__optskv[-W]:-.}"
        # IPREFIX=
    fi
    local compadd_args="$(printf '%q ' PREFIX="$PREFIX" IPREFIX="$IPREFIX" SUFFIX="$SUFFIX" ISUFFIX="$ISUFFIX" compadd ${__flags:+-$__flags} "${__opts[@]}" "${__ipre[@]}" "${__apre[@]}" "${__hpre[@]}" "${__hsuf[@]}" "${__asuf[@]}" "${__isuf[@]}" -U)"
    printf "__compadd_args+=( '%s' )\n" "${compadd_args//'/'\\''}" >&"${__evaled}"
    (( __comp_index++ ))

    local file_prefix="${__optskv[-W]:-.}"
    local __disp_str __hit_str __show_str __real_str __suffix

    local prefix="${IPREFIX}${__ipre[2]}${__apre[2]}${__hpre[2]}"
    # FJO no suffix 
    local suffix="${__hsuf[2]}${__asuf[2]}${__isuf[2]}"
    # if [ -n "$__is_param" -a "$prefix" = '${' -a -z "$suffix" ]; then
    #     suffix+=}
    # fi
    suffix=""
    local i
    for ((i = 1; i <= $#__hits; i++)); do
        # actual match
        __hit_str="${__hits[$i]}"
        # full display string
        __disp_str="${__disp[$i]}"
        __suffix="$suffix"

        # part of display string containing match
        if [ -n "$__noquote" ]; then
            __show_str="${(Q)__hit_str}"
        else
            __show_str="${__hit_str}"
        fi
        __real_str="${__show_str}"

        if [[ -n "$__filenames" && -n "$__show_str" && -d "${file_prefix}/${__show_str}" ]]; then
            __show_str+=/
            __suffix+=/
            # prefix="${file_prefix}"
        fi

        # if [[ -z "$__disp_str" || "$__disp_str" == "$__show_str"* ]]; then
        #     # remove prefix from display string
        #     __disp_str="${__disp_str:${#__show_str}}"
        # else
        #     # display string does not match, clear it
        #     __show_str=
        # fi

        if [[ "$__show_str" =~ [^[:print:]] ]]; then
            __show_str="${(q)__show_str}"
        fi
        if [[ "$__disp_str" =~ [^[:print:]] ]]; then
            __disp_str="${(q)__disp_str}"
        fi
        # use display as fallback
        if [[ -z "$__show_str" ]]; then
            __show_str="$__disp_str"
            __disp_str=
        elif (( ! _COMPLETE_NG_SEARCH_DISPLAY )); then
            __disp_str="$__disp_str"$'\x1b[0m'
        fi

        if [[ "$__show_str" == "$PREFIX"* ]]; then
            __show_str="${__show_str:${#PREFIX}}${_COMPLETE_NG_SPACE_SEP}${PREFIX}"$'\x1b[0m'
        else
            __show_str+="${_COMPLETE_NG_SEP}"
        fi

        # fullvalue, value, index, display, show, prefix
        printf %s\\n "${(q)prefix}${(q)__real_str}${(q)__suffix}${_COMPLETE_NG_SEP}${(q)__hit_str}${_COMPLETE_NG_SEP}${__comp_index}${_COMPLETE_NG_SEP}${__disp_str}${_COMPLETE_NG_SEP}${__show_str}${_COMPLETE_NG_SPACE_SEP}" >&"${__stdout}"
    done
    return "$__code"
}

#zle -C _complete_ng complete-word _complete_ng
zle -C _complete_ng expand-or-complete _complete_ng
zle -N complete_ng
fzf_default_completion=complete_ng
bindkey '^I' complete_ng
