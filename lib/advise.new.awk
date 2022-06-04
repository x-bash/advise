
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

function parse_arguments( args, obj, env_table,     i, j ){
    argl = args[ L ]

    while ( i<=argl ) {
        arg = args[ i ]

        if (arg ~ /^--/) {

            continue
        } else if (arg ~ /^-/) {

            continue
        } else if (arg ~ /^:[-+]/) {

            continue
        }

        # handle it into argument

        for (j=1; i+j-1 > argl; ++j) {
            rest_arg[ j ] = args[ i+j-1]
        }
    }

}

END{
    enhance_argument_parser( obj )

    parse_arguments( obj, env_table )

    # showing candidate code

}

