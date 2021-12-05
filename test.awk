NR==2{
    argstr = $0
    if ( argstr == "" ) argstr = "" # "." "\002"

    gsub("\n", "\001", argstr)
    parsed_arglen = split(argstr, parsed_argarr, "\002")

    ruleregex = ""

    arglen=0
    rest_argv_len = 0

    current_keypath = "."
    opt_len = parsed_arglen

    for (i=1; i<=parsed_arglen; ++i) {
        arg = parsed_argarr[i]
        gsub("\001", "\n", arg)
        parsed_argarr[i] = arg
    }

    for (i=1; i<parsed_arglen; ++i) {
        if (arg ~ /^-/) {

            if(match(arg,/=/)){
                continue
            }
            if (match(arg, /^--?[A-Za-z0-9_+-]+=/)){

            }
            ...
            if (option_id != "") {
                used_option_add( option_id )
            } else {
               ...
                if (arg ~ /^-[^-]/) {
                    ...

                }

                ...
            }

            # handle optarg value
            if (argval != "") {
                ...
            } else {
                ...
                for (cur_optarg_index=1; cur_optarg_index<=optarg_num; ++cur_optarg_index) {
                    ....
                }

                if (cur_optarg_index > optarg_num) {
                   ...
                }
            }
        } else {

            # skip "@<object>"
            if ( (arg ~ /^@/) ) {
                if ( get_colon_argument_optionid( current_keypath ) != "") {
                    ...
                }
            }

            ....
            if (option_id == "") {
                ...
            }

            # Must be subcommand argument
            ...
        }
    }

    ...

    if (cur == "\177") {    # ascii code 127 0x7F 0177 ==> DEL
        cur = ""
    }

    if ( (cur ~ /^@/ ) ) {
        ...
    }

    if (rest_argv_len > 0) {
        ...
    } else if (cur_option_alias != "") {
        ...
    } else if(match(cur,/^-.*=/)){
        ...
    } else {
        ....
    }
}