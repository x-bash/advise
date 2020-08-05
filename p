#shellcheck shell=bash

# param.__parse '
#     argenv[org] "Provide organization"
#     arg[repo] "repo name" =~ [:alpha:][[:alnum:]-_]+
#     arg[access] = public private inner-source
# '

<<A
@p '
    org "Provide organization" =~ [abc]+ [[:alnum:]]+
    repo "Repository name"
    access=public = public private inner-source
'
A

alias @p='p.__trap_to_parse "$@"; :'

p.__trap_to_parse(){

    local latest_debug_code
    latest_debug_code=$(trap DEBUG)
    local latest_debug_set="trap ${latest_debug_code:-"\"\""} DEBUG"

    local code="eval \"\$(p.__parse $* \${COMMAND:1})\""
    
    echo "$code"
    
    final_code="
        $code
        $latest_debug_set
    "

    trap "$final_code" DEBUG
    
}

str.repr(){
    # echo "\"$(echo "$1" | sed s/\"/\\\\\"/g)\""
    # echo "\"${1//\"/\\\\\"}\""
    echo "\"${1//\"/\\\"}\""
}

p.__parse(){

    local ARG_NUM=$(( ${#@} ))
    local ARG_NUM_1=$(( ${#@} - 1 ))
    local ARGS=("${@:1:$ARG_NUM_1}")

    local STR="${@:$ARG_NUM}"

    local i

    local varlist=()
    local typelist=()
    local vallist=()
    local deslist=()
    local deflist=()
    local oplist=()
    local choicelist=()

    while read line; do
        # line="$(str.trim "$line")"
        [ "$line" == "" ] && continue

        echo "--- $line"
     
        local operator="str"

        local all_arg_arr
        read -a all_arg_arr <<< "$line"

        varname=${all_arg_arr[0]}

        if [[ $varname == *=* ]]; then
            local default="${varname#*=}"
            varname="${varname%%=*}"
            varlist+=("$varname")
            vallist+=("$default")
            deflist+=("$default")
        else
            varlist+=("$varname")
            vallist+=("")
            deflist+=("")
        fi

        local IFS=$'\n'

        case ${all_arg_arr[1]} in
        = | =~ | str | float | int) 
            operator=${all_arg_arr[1]}
            choicelist=("${all_arg_arr[*]:2}");;
        *)
            description=${all_arg_arr[1]}
            operator=${all_arg_arr[2]}
            choicelist=("${all_arg_arr[*]:3}");;
        esac

        deslist+=("$description")
        typelist+=("argenv")
        oplist+=("$operator")
    done <<< "$STR"

    # echo setup environment value >&2
    
    for i in $(seq ${#varlist[@]}); do
        if [[ "${typelist[$i]}" == "*env" ]]; then
            local name=${varlist[$i]}
            vallist[$i]=${!$name}
        fi
    done
    
    # echo setup parameter value >&2
    set -- "${ARGS[@]}"
    while [ ! "$#" -eq 0 ]; do
        local parameter_name=$1
        shift
        if [[ "$parameter_name" == --* ]]; then
            parameter_name=${parameter_name:2}
            local sw=0
            for i in "${!varlist[@]}"; do
                [[ ! "${typelist[i]}" = arg* ]] && continue
                local _varname=${varlist[i]}
                # echo  "$parameter_name" == "$_varname"
                if [ "$parameter_name" == "$_varname" ]; then
                    vallist[$i]=$1
                    shift
                    sw=1
                    break
                fi
            done
            if [ $sw -eq 0 ]; then
                echo "Unsupported parameter: --$parameter_name" >&2
                echo "return 1 >&2"
                return 0
            fi
        fi
    done
    
    # echo "--------"
    # echo "${varlist[@]}"
    # echo "${vallist[@]}"
    # echo "${#deslist[@]}"
    # echo "${deflist[@]}"
    # echo "${oplist[@]}"
    # echo "--------"

    # setup default value
    for i in $(seq "${#varlist[@]}"); do
        local name="${varlist[$i]}"
        local val="${vallist[$i]}"
        if [ "$val" == "" ]; then
            vallist[$i]=${deflist[$i]}
        fi
    done

    # using local value
    for i in $(seq "${#varlist[@]}"); do
        (( i=i-1 ))
        local name="${varlist[i]}"
        local val="${vallist[i]}"

        local op="${oplist[$i]}"
        local choice=("${choicelist[i]}")

        case "$op" in
        =~)
            local match=0
            for c in "${choice[@]}"; do
                echo "$val" =~ $c
                if [[ "$val" =~ $c ]]; then
                    match=1
                    break
                fi
            done

            if [ $match -eq 0 ]; then
                echo "echo Value of $name is not one of the regex set >&2"
                # echo "echo '$val' expected to be ${choice[@]} >&2"
                echo 'return 1 2>&1'
                return 0;
            fi;;
        =)
            local match=0
            for c in "${choice[@]}"; do
                if [ "$c" == "$val" ]; then
                    match=1
                    break
                fi
            done

            if [ $match -eq 0 ]; then
                echo "echo Value of $name is not one of the candidate set >&2"
                echo 'return 1 2>&1'
                return 0
            fi ;;
        str | int)
            if [[ "$op" = "int" && ! "$val" =~ ^[\ \t]+[0-9]+[\ \t]+$ ]] ]]; then
                echo "echo Value of $name is integer >&2"
                echo 'return 1 2>&1'
                return 1
            fi
            local match=0
            for c in "${choice[@]}"; do
                if [ "$c" = "$val" ]; then
                    match=1
                    break
                fi
            done

            if [ $match -eq 0 ]; then
                echo "echo Value of $name is not one of the $op set >&2"
                echo 'return 1 2>&1'
                return 0
            fi ;;
        *) [ "$op" == "" ] || echo ": TODO: $op" 2>&1
        ;;
        esac

        # TODO: notice the '' inside the string
        echo "local $name=$(str.repr "$val")"
    done

}

# p.__parse --repo hi --org "dy\" innoa" '
p.__parse --repo hi --org "dyi" '
    org "Provide organization" =~ [abc]+ [[:alnum:]]+
    repo "Repository name"
    access=public = public private inner-source
'

