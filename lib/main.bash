# shellcheck disable=SC2207
# Section : main
___advise_run(){
    local resname="${1:-${COMP_WORDS[0]}}"

    [ -z "$___ADVISE_RUN_CMD_FOLDER" ] && ___ADVISE_RUN_CMD_FOLDER="$___X_CMD_ADVISE_TMPDIR"

    local filepath
    case "$resname" in
        /*) filepath="$resname" ;;
        -)  filepath=/dev/stdin ;;
        *)  filepath="$___ADVISE_RUN_CMD_FOLDER/$resname"
            [ ! -d "$filepath" ] || filepath="$___ADVISE_RUN_CMD_FOLDER/$resname/advise.json"
            [ -f "$filepath" ] || filepath="$___ADVISE_RUN_CMD_FOLDER/$resname/advise.t.json"
            [ -f "$filepath" ] || filepath="$(___x_cmd_advise_man_which "$resname")" ;;
    esac
    [ -f "$filepath" ] || return

    if [ "${BASH_VERSION#3}" = "${BASH_VERSION}" ]; then
        local last="${COMP_WORDS[COMP_CWORD]}"
        case "$last" in
            \"*|\'*)    COMP_LINE="${COMP_LINE%"$last"}"
                        tmp=( $COMP_LINE ); tmp+=("$last")  ;;
            *)          tmp=( $COMP_LINE ) ;;
        esac

        # Ends with space
        if [ "${COMP_LINE% }" != "${COMP_LINE}" ]; then
            tmp+=( "" )
        fi

        COMP_WORDS=("${tmp[@]}")
        COMP_CWORD="$(( ${#tmp[@]}-1 ))"
    fi

    local cur="${COMP_WORDS[COMP_CWORD]}"
    local candidate_arr
    local candidate_exec
    local candidate_exec_arr
    local offset
    eval "$(___advise_get_result_from_awk)" 2>/dev/null
    local IFS=$'\n'
    eval "$candidate_exec" 2>/dev/null

    IFS=$' '$'\t'$'\n'
    COMPREPLY=(
        $(
            compgen -W "${candidate_arr[*]} ${candidate_exec_arr[*]}" -- "$cur"
        )
    )

    __ltrim_completions "$cur" "@"
    __ltrim_completions "$cur" ":"
    __ltrim_completions "$cur" "="
}
## EndSection
