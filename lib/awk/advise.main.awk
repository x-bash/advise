
{
    if (NR>1) {
        # if ($0 != "") json_parse(obj, $0)git
        if ($0 != "") json_parse_after_tokenize(obj, $0)
    } else {
        # Read the argument
        prepare_argarr( $0 )
    }
}

END{
    # for (i in obj) print i "\t\t\t" obj[i] > "bbb"
    if (EXIT_CODE == 0) {
        # enhance_argument_parser( obj )
        parse_args_to_env( parsed_argarr, parsed_arglen, obj, "", genv_table, lenv_table )
        # showing candidate code
    }

}

# Section: prepare argument
function prepare_argarr( argstr,        i,arg ){
    if ( argstr == "" ) argstr = "" # "." "\002"

    gsub("\n", "\001", argstr)
    parsed_arglen = split(argstr, parsed_argarr, "\002")

    ruleregex = ""
    arglen = 0
    rest_argv_len = 0

    current_keypath = "."
    # opt_len = parsed_arglen

    for (i=1; i<=parsed_arglen; ++i) {
        arg = parsed_argarr[i]
        gsub("\001", "\n", arg)
        parsed_argarr[i] = arg
    }
}

# EndSection


# Section: parse argument into env table

# Complete Rest Argument
# Complete Option Name Or RestArgument
# Complete Option Argument

function env_table_set_true( key, keypath ){
    env_table_set( key, keypath, 1 )
}

function env_table_set( key, keypath, value ){
    genv_table[ keypath ] = value
    lenv_table[ key ] = value
}


function parse_args_to_env___option( obj, obj_prefix, args, argl, arg, arg_idx, genv_table, lenv_table ){
    _arg_id = aobj_get_id_by_name( obj, obj_prefix, arg )
    if (_arg_id == "") {
        return 0
    }

    _optargc = aobj_get_optargc( obj, obj_prefix, _arg_id )
    # print "_optargc:" _optargc "xx" obj[ obj_prefix, _arg_id  ]
    if (_optargc == 0) {
        env_table_set_true( _arg_id, obj_prefix SUBSEP _arg_id SUBSEP k )
        return arg_idx
    }

    for (k=1; k<=_optargc; ++k)  {
        if ( arg_idx >= argl ) {
            print "args:" args[ arg_idx ] " arg_idx:" arg_idx " _arg_id:" _arg_id " argl:" argl
            # print "cc:" obj[ obj_prefix SUBSEP _arg_id SUBSEP jqu(k) ]
            print advise_complete_option_value( args[ arg_idx-1 ], genv_table, lenv_table, obj, obj_prefix, _arg_id, k )
            return arg_idx # Not Running at all .. # TODO
        }
        env_table_set( _arg_id, obj_prefix SUBSEP _arg_id SUBSEP k, args[ arg_idx++ ] )
    }
    return arg_idx
}

function parse_args_to_env( args, argl, obj, obj_prefix, genv_table, lenv_table,    i, j, _subcmdid ){

    obj_prefix = SUBSEP jqu(1)   # Json Parser

    i = 1;
    while ( i<=argl ) {
        arg = args[ i ];    i++

        _subcmdid = aobj_get_subcmdid_by_name( obj, obj_prefix, arg )
        if (_subcmdid != "") {
            # TODO: Check all required options set
            if ( ! aobj_option_all_set( lenv_table, obj, obj_prefix  ) ) {
                # TODO: show message that it is wrong ...
                print "all required options should be set"
            }
            obj_prefix = obj_prefix SUBSEP _subcmdid
            # print "_subcmdid:" _subcmdid "obj_prefix:" obj_prefix
            delete lenv_table
            continue
        }

        if (arg ~ /^--/) {
            if ( 0 == parse_args_to_env___option( obj, obj_prefix, args, argl, arg, i, genv_table, lenv_table ) ) break
        } else if (arg ~ /^-/) {
            j = parse_args_to_env___option( obj, obj_prefix, args, argl, arg, i, genv_table, lenv_table )
            if (j != 0) {
                i = j
                continue
            }

            _arg_arrl = split(arg, _arg_arr, "")
            for (j=2; j<=_arg_arrl; ++j) {
                _arg_id = aobj_get_id_by_name( obj, obj_prefix, "-" _arg_arr[j] )
                assert( _arg_id == "", "Fail at parsing: " arg ". Not Found: -" _arg_arr[j] )
                _optargc = aobj_get_optargc( obj, obj_prefix, _arg_id )
                if (_optargc == 0) {
                    env_table_set_true( _arg_id, obj_prefix SUBSEP _arg_id SUBSEP k )
                    continue
                }

                assert( j==_arg_arrl, "Fail at parsing: " arg ". Accept at least one argument: -" _arg_arr[j] )

                for (k=1; k<=_optargc; ++k)  {
                    if ( i>argl ) {
                        advise_complete_option_value( args[i], genv_table, lenv_table, obj, obj_prefix SUBSEP _arg_id, k )
                        return  # Not Running at all .. # TODO
                    }
                    env_table_set( _arg_id, obj_prefix SUBSEP _arg_id SUBSEP k, args[ i++ ] )
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
    i = i-2
    # print "i: " i " argl: " argl
    for (j=1; i+j-1 > argl; ++j) {
        # print "i+j-1:" i+j-1 " argl:" argl
        rest_arg[ j ] = args[ i+j-1 ]
        print "rest_arg[ j ]: " rest_arg[ j ]
    }

    rest_argc = j-1

    print "rest_argc:" rest_argc

    if (rest_argc == 0) {
        advise_complete_option_name_or_argument_value( args[i], genv_table, lenv_table, obj, obj_prefix )
        return
    }

    rest_argc_min = aobj_get_minimum_rest_argc( obj, obj_prefix )
    rest_argc_max = aobj_get_maximum_rest_argc( obj, obj_prefix )

    # print "rest_argc_min:" rest_argc_min " rest_argc_max:" rest_argc_max
    # if (rest_argc == rest_argc_max) {
    #     # No Advise
    # } else if (rest_argc > rest_argc_max) {
    #     # No Advise. Show it is wrong.
    # } else {
    #     print "obj_prefix:" obj_prefix
    #     advise_complete_argument_value( genv_table, lenv_table, obj, obj_prefix, rest_argc + 1 )
    # }
    if (rest_argc > rest_argc_max) {
        # No Advise. Show it is wrong.
    } else {
        # print "obj_prefix:" obj_prefix
        advise_complete_argument_value( args[i], genv_table, lenv_table, obj, obj_prefix, rest_argc + 1 )
    }

}
# EndSection
