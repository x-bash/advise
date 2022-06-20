# shellcheck disable=SC2207
# Section : main
___advise_run(){
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local resname="${1:-${COMP_WORDS[0]}}"

    [ -z "$___ADVISE_RUN_CMD_FOLDER" ] && ___ADVISE_RUN_CMD_FOLDER="$___X_CMD_ADVISE_TMPDIR"

    local filepath
    case "$resname" in
        /*) filepath="$resname" ;;
        -)  filepath=/dev/stdin ;;
        *)  filepath="$___ADVISE_RUN_CMD_FOLDER/$resname"
            [ ! -d "$filepath" ] || filepath="$filepath/advise.json" ;;
    esac
    [ -f "$filepath" ] || return

    local candidate_arr candidate_exec
    eval "$(___advise_get_result_from_awk)" 2>/dev/null
    local OLDIFS="$IFS"
    local IFS=$'\n'
    local candidate_exec_arr=( $("$candidate_exec" 2>/dev/null) )

    IFS="$OLDIFS"
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
