
# Section : main
___advise_get_result_from_awk(){
    local result cmd_result
    local IFS=$'\002'
    local s="${COMP_WORDS[*]}"
    s="${s#*"$IFS"}"

    # Handle the case that the last word has "@" or ":" in bash.
    COMP_LINE="${COMP_WORDS[*]}"
    local cur_1="${COMP_WORDS[COMP_CWORD-1]}"
    case "$cur_1" in
        *@|*:)
            if [ "${COMP_LINE% }" != "${COMP_LINE}" ]; then
                s="${s%$cur_1$IFS$cur}"
                s="${s}${cur_1}$cur"
            fi
            ;;
        *)
    esac

    IFS=$'\n'
    result="$(
        {
            cat "$filepath"
            printf "\034%s\034" "$s"
        } | awk -f "$___X_CMD_ROOT_MOD/advise/lib/advise.awk" 2>/dev/null
    )"
    local cmd="${result##*\#> }"
    cmd_result=""

    if [ "$cmd" != "$result" ]; then
        cmd_result="$(eval "$cmd" 2>/dev/null)"
        result="${result%%\#> *}"
    fi

    printf "%s" "$result
$cmd_result"
}

___advise_run(){
    local resname cur
    if [ -n "$ZSH_VERSION" ];then
        local COMP_WORDS=("${words[@]}")
        local COMP_CWORD="$(( ${#words[@]}-1 ))"
        cur="${COMP_WORDS[COMP_CWORD+1]}"
        resname="${1:-${COMP_WORDS[1]}}"
    else
        cur="${COMP_WORDS[COMP_CWORD]}"
        resname="${1:-${COMP_WORDS[0]}}"
    fi

    local filepath
    [ -z "$___ADVISE_RUN_CMD_FOLDER" ] && ___ADVISE_RUN_CMD_FOLDER="$___X_CMD_ADVISE_TMPDIR"
    case "$resname" in
        /*) filepath="$resname" ;;
        -)  filepath=/dev/stdin ;;
        *)
            if [ -d "$___ADVISE_RUN_CMD_FOLDER/$resname" ]; then
                filepath="$___ADVISE_RUN_CMD_FOLDER/$resname/advise.json"
            else
                filepath="$___ADVISE_RUN_CMD_FOLDER/$resname"
            fi
            ;;
    esac
    [ -f "$filepath" ] || return

    if [ -n "$BASH_VERSION" ] && [ "${BASH_VERSION#3}" = "${BASH_VERSION}" ]; then
        local last="${COMP_WORDS[COMP_CWORD]}"
        case "$last" in
            \"*|\'*)
                COMP_LINE="${COMP_LINE%"$last"}"
                tmp=( $COMP_LINE )
                tmp+=("$last")
                ;;
            *)
                tmp=( $COMP_LINE )
                ;;
        esac

        # Ends with space
        if [ "${COMP_LINE% }" != "${COMP_LINE}" ]; then
            tmp+=( "" )
        fi

        COMP_WORDS=("${tmp[@]}")
        COMP_CWORD="$(( ${#tmp[@]}-1 ))"
    fi

    local OLDIFS="$IFS"
    local IFS=$'\n'
    local cmds
    cmds="$(___advise_get_result_from_awk)"
    local commands=($(printf "%s" "$cmds"))
    desc=()
    cmds=()
    for i in "${commands[@]}"; do
        if [ ! "$i" = "${i%%---*}" ] && [ -n "$ZSH_VERSION" ];then
            desc+=("\"${i%% *}:${i#*--- }\"")
            continue
        fi
        cmds+=("${i%% *}")
    done

    if [ -n "$ZSH_VERSION" ];then
        eval "desc=(${desc[*]})"
        _describe 'commands' desc
        compadd -a cmds
    else
        if [[ ! "$BASH_VERSION" =~ ^3.* ]];then
            if [[ "$result" =~ [:=\/]$ ]];then
                compopt -o nospace
            else
                compopt +o nospace
            fi
        fi

        # shellcheck disable=SC2207
        COMPREPLY=(
            $(
                compgen -W "${cmds[*]}" -- "$cur"
            )
        )

        __ltrim_completions "$cur" "@"
        __ltrim_completions "$cur" ":"
        __ltrim_completions "$cur" "="
    fi
    IFS="$OLDIFS"
}

## EndSection
