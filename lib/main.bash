# shellcheck disable=SC2207
# Section : main

___advise_run_filepath_(){
    case "$1" in
        /*) ___ADVISE_RUN_FILEPATH_="$1" ;;
        -)  ___ADVISE_RUN_FILEPATH_=/dev/stdin ;;
        *)  ___ADVISE_RUN_FILEPATH_="$___ADVISE_RUN_CMD_FOLDER/$1"
            [ -d "$___ADVISE_RUN_FILEPATH_" ] || return 1
            ___ADVISE_RUN_FILEPATH_="$___ADVISE_RUN_CMD_FOLDER/$1/advise.json"
            [ ! -f "$___ADVISE_RUN_FILEPATH_" ] || return 0
            ___ADVISE_RUN_FILEPATH_="$___ADVISE_RUN_CMD_FOLDER/$1/advise.t.json"
            [ ! -f "$___ADVISE_RUN_FILEPATH_" ] || return 0
            ___ADVISE_RUN_FILEPATH_="$(___x_cmd_advise_man_which "$1")"
            ;;
    esac
    [ ! -f "$___ADVISE_RUN_FILEPATH_" ] || return 0
    return 1
}

___advise_run(){
    [ -z "$___ADVISE_RUN_CMD_FOLDER" ] && ___ADVISE_RUN_CMD_FOLDER="$___X_CMD_ADVISE_TMPDIR"

    local ___ADVISE_RUN_FILEPATH_;  ___advise_run_filepath_ "${1:-${COMP_WORDS[0]}}" || return 1

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


    local candidate_arr
    local candidate_exec
    local candidate_exec_arr

    local cur="${COMP_WORDS[COMP_CWORD]}"       # Used in `eval "$candidate_exec"`
    local offset                                # Used in `eval "$candidate_exec"`

    eval "$(___advise_get_result_from_awk "$___ADVISE_RUN_FILEPATH_")" 2>/dev/null
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
