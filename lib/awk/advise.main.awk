
{
    if (NR>1) {
        if ($0 != "") json_parse( $0, obj )
    } else {
        # Read the argument
        prepare_argarr( $0 )
    }
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

# EndSection

# Complete Rest Argument
# Complete Option Name Or RestArgument
# Complete Option Argument

function parse_args_to_env( args, obj, obj_prefix, genv_table, lenv_table,    i, j, _subcmdid ){
    argl = args[ L ]

    obj_prefix = ""

    while ( i<=argl ) {
        arg = args[ i ];    i++

        _subcmdid = aobj_get_subcmdid_by_name( obj, obj_prefix, obj_prefix, arg )
        if (_subcmdid != "") {
            obj_prefix = obj_prefix SUBSEP _subcmdid
            delete lenv_table
            continue
        }

        if (arg ~ /^--/) {
            _arg_id = aobj_get_id_by_name( obj, obj_prefix, arg )
            if (_arg_id != "") {
                _optargc = aobj_get_optargc( obj_prefix SUBSEP _arg_id )
                for (k=1; k<=_optargc; ++k)  {
                    if ( i>argl ) {
                        advise_complete_option_value( genv_table, lenv_table, obj, obj_prefix SUBSEP _arg_id, k )
                        return
                    }
                    genv_table[ obj_prefix, _arg_id, k ] = args[ i++ ]
                    lenv_table[ _arg_id, k ] = args[ i++ ]
                }
                continue
            }
        } else if (arg ~ /^-/) {
            _arg_id = aobj_get_id_by_name( obj, obj_prefix, arg )
            if (_arg_id != "") {
                _optargc = aobj_get_optargc( obj, obj_prefix, _arg_id )
                for (k=1; k<=_optargc; ++k)  {
                    if ( i>argl ) {
                        advise_complete_option_value( genv_table, lenv_table, obj, obj_prefix SUBSEP _arg_id, k )
                        return
                    }
                    genv_table[ obj_prefix, _arg_id, k ] = args[ i++ ]
                    lenv_table[ _arg_id, k ] = args[ i++ ]
                }
                continue
            }

            _arg1_arrl = split(arg, _arg1_arr)
            for (j=2; j<=_arg1_arrl; ++j) {
                _arg_id = aobj_get_id_by_name( obj, obj_prefix, "-" _arg1_arrl[j] )
                assert( _arg_id != "", "Fail at parsing: " arg ". Not Found: -" _arg1_arrl[j] )
                _optargc = aobj_get_optargc( obj, obj_prefix, _arg_id )
                if (_optargc > 0) {
                    assert( j==_arg1_arrl, "Fail at parsing: " arg ". Accept at least one argument: -" _arg1_arrl[j] )

                    for (k=1; k<=_optargc; ++k)  {
                        if ( i>argl ) {
                            advise_complete_option_value( genv_table, lenv_table, obj, obj_prefix SUBSEP _arg_id, k )
                            return
                        }

                        genv_table[ obj_prefix, _arg_id, k ] = args[ i++ ]
                        lenv_table[ _arg_id, k ] = args[ i++ ]
                    }
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
        rest_arg[ j ] = args[ i+j-1 ]
    }

    rest_argc = j-1

    if (rest_argc == 0) {
        # If not require ready...
        advise_complete_option_name( genv_table, lenv_table, obj, obj_prefix )
        # TODO: Check upper level options provided
        if ( aobj_options_all_ready( obj, obj_prefix, lenv ) ) {
            advise_complete_argument_value( genv_table, lenv_table, obj, obj_prefix, 1 )
            return
        }
        return
    }

    rest_argc_min = aobj_get_minimum_rest_argc( obj, obj_prefix )
    rest_argc_max = aobj_get_maximum_rest_argc( obj, obj_prefix )

    if (rest_argc == rest_argc_max) {
        # No Advise
    } else if (rest_argc > rest_argc_max) {
        # No Advise. Show it is wrong.
    } else {
        advise_complete_argument_value( genv_table, lenv_table, obj, obj_prefix, rest_argc + 1 )
    }

}

END{
    if (EXIT_CODE == 0) {
        enhance_argument_parser( obj )
        parse_args_to_env( obj, obj_prefix, genv_table )
        # showing candidate code
    }
}

