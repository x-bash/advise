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
            [ ! -d "$filepath" ] || filepath="$___ADVISE_RUN_CMD_FOLDER/$resname/advise.json"
            [ -f "$filepath" ] || filepath="$___ADVISE_RUN_CMD_FOLDER/$resname/advise.t.json";;
    esac
    [ -f "$filepath" ] || return

    local candidate_arr
    local candidate_exec
    local candidate_exec_arr
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
