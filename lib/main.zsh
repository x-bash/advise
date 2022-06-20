
# Section : main
___advise_run(){
    local COMP_WORDS=("${words[@]}")
    local COMP_CWORD="$(( ${#words[@]}-1 ))"
    local cur="${COMP_WORDS[COMP_CWORD+1]}"
    local resname="${1:-${COMP_WORDS[1]}}"

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
    local candidate_exec_arr=( $(eval "$candidate_exec" 2>/dev/null) )

    [ -z "$candidate_arr" ] || _describe 'commands' candidate_arr
    [ -z "$candidate_exec_arr" ] || _describe 'commands' candidate_exec_arr
}
## EndSection
