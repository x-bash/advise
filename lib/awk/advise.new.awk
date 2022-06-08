
NR>1{
    if ($0 != "") json_parse( $0, obj )
    next
}

# Section: prepare argument

function prepare_argarr( argstr ){
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
}

# NR==1
{
    # Read the argument
    prepare_argarr( $0 )
}

# EndSection

BEGIN{
    EXIT_CODE = 0
}

function panic(msg){
    print "[PANIC]: " msg >"/dev/stderr"
    EXIT_CODE = 1
    exit(1)
}

function assert(condition, msg){
    if (condition == 0) {
        panic(msg)
    }
}

function parse_args_to_obj( args, obj, env_table,     i, j ){
    argl = args[ L ]

    while ( i<=argl ) {
        arg = args[ i ];    i++

        if (arg ~ /^--/) {
            _arg_id = aobj_get_id_by_name( arg )
            if (_arg_id != "") {
                _optargc = aobj_get_optargc( _arg_id )
                for (k=1; k<=_optargc; ++j)         obj[ _arg_id, k ] = args[ i++ ]
                continue
            }
        } else if (arg ~ /^-/) {
            _arg_id = aobj_get_id_by_name( arg )
            if (_arg_id != "") {
                _optargc = aobj_get_optargc( _arg_id )
                for (k=1; k<=_optargc; ++j)         obj[ _arg_id, k ] = args[ i++ ]
                continue
            }

            _arg1_arrl = split(arg, _arg1_arr)
            for (j=2; j<=_arg1_arrl; ++j) {
                _arg_id = aobj_get_id_by_name( "-" _arg1_arrl[j] )
                assert( _arg_id != "", "Fail at parsing: " arg ". Not Found: -" _arg1_arrl[j] )
                _optargc = aobj_get_optargc( _arg_id )
                if (_optargc > 0) {
                    assert( j==_arg1_arrl, "Fail at parsing: " arg ". Accept at least one argument: -" _arg1_arrl[j] )
                    for (k=1; k<=_optargc; ++j)     obj[ _arg_id, k ] = args[ i++ ]
                }
            }
            continue
        }

        # gt create repo :+wiki :-issue
        # gt create repo --NoWiki --NoIssue --
        # else if (arg ~ /^:[-+]/) {
        #     continue
        # }
        break
    }

    # handle it into argument
    for (j=1; i+j-1 > argl; ++j) {
        rest_arg[ j ] = args[ i+j-1]
    }
}

END{
    if (EXIT_CODE == 0) {
        enhance_argument_parser( obj )
        parse_args_to_obj( obj, env_table )
        # showing candidate code
    }
}

