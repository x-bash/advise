BEGIN{
    UI_LEFT  = ( UI_LEFT == "" ) ? "\033[36m" : UI_LEFT
    UI_RIGHT = ( UI_RIGHT == "" ) ? "\033[91m" : UI_RIGHT
    UI_END   = "\033[0m"
    HELP_INDENT_STR = "    "
    DESC_INDENT_STR = "   "
    if (IS_INTERACTIVE != 1) UI_LEFT = UI_RIGHT = UI_END = ""
}

# Section: prepare argument
function prepare_argarr( argstr,        i, l ){
    if ( argstr == "" ) return
    l = split(argstr, args, "\002")
    args[L] = l
}

function str_cut_line( _line, indent,               _max_len, _len, l, i){
    if( COLUMNS == "" )     return _line

    _max_len = COLUMNS - indent
    if ( length(_line) < _max_len )  return _line

    l = split( _line, _arr, " " )
    if ( length(_arr[1]) < _max_len ){
        for(i=1; i<=l; ++i){
            _len += ( length(_arr[i]) + 1)
            if (_len >= _max_len) {
                _len -= ( length(_arr[i]) + 1 )
                break
            }
        }
    } else {
        _len = _max_len
    }
    return substr(_line, 1, _len) "\n" str_rep(" ", indent)  str_cut_line( substr(_line, _len + 1 ), indent )
}

function get_option_string( obj, obj_prefix, v,         _str){
    _str = juq(v)
    gsub("\\|", ",", _str)
    return _str juq( aobj_get_special_value(obj, obj_prefix SUBSEP v, "arguments_str") )
}

function generate_help_for_namedoot_cal_maxlen_desc( obj, obj_prefix, _text_arr,            l, i, _len, _max_len, _opt_help_doc ){
    l = arr_len(_text_arr)
    for ( i=1; i<=l; ++i ) {
        _text_arr[ i ]   = _opt_help_doc     = get_option_string( obj, obj_prefix, _text_arr[ i ] )
        _text_arr[ i L ] = _len              = length( _opt_help_doc )        # TODO: Might using wcswidth
        if ( _len > _max_len )    _max_len = _len
    }
    return _max_len
}

function generate_optarg_rule_string_inner(obj, obj_prefix,     _str, _dafault, _regexl, _candl, i){
    _default = aobj_get_default(obj, obj_prefix)
    if (_default != "" ) _str = _str " [default: " _default "]"

    _regex_id = aobj_get_special_value_id( obj_prefix, "regex")
    _cand_id = aobj_get_special_value_id( obj_prefix, "cand")
    _regexl  = aobj_len(obj, _regex_id)
    _candl   = aobj_len(obj, _cand_id)
    if ( _regexl > 0 ) {
        _str = _str " [regex: "
        _str = _str juq( aobj_get(obj, _regex_id SUBSEP 1) )
        for (i=2; i<=_regexl; ++i ) _str = _str "|" juq( aobj_get(obj, _regex_id SUBSEP i) )
        _str = _str "]"
    }
    if ( _candl > 0  ) {
        _str = _str " [candidate: "
        _str = _str aobj_get(obj, _cand_id SUBSEP "\""1"\"")
        for (i=2; i<=_candl; ++i ) _str = _str ", " aobj_get(obj, _cand_id SUBSEP "\""i"\"")
        _str = _str "]"
    }
    return _str
}

function generate_optarg_rule_string(obj, obj_prefix, option_id,     _str, l, i) {
    l = aobj_get_optargc( obj, obj_prefix, option_id )
    _str = _str generate_optarg_rule_string_inner(obj, obj_prefix SUBSEP option_id)
    obj_prefix = obj_prefix SUBSEP option_id
    for (i=1; i<=l; ++i) _str = _str generate_optarg_rule_string_inner(obj, obj_prefix SUBSEP "\"#"i"\"")
    return _str
}

function generate_help( obj, obj_prefix, arr, text,          i, v, _str, _max_len, _text_arr, _option_after ){
    arr_clone( arr, _text_arr )
    _max_len = generate_help_for_namedoot_cal_maxlen_desc( obj, obj_prefix, _text_arr )
    _str = "\n" text ":\n"
    for ( i=1; i<=arr_len(arr); ++i ) {
        v = arr[ i ]
        _option_after = juq( aobj_get_description(obj, obj_prefix SUBSEP v) ) UI_END generate_optarg_rule_string(obj, obj_prefix, v)

        _str = _str HELP_INDENT_STR sprintf("%s" DESC_INDENT_STR "%s\n",
            UI_LEFT         str_pad_right( _text_arr[i], _max_len ),
            UI_RIGHT        str_cut_line( _option_after, _max_len + 7 ))
    }
    if (text == "SUBCOMMANDS") _str = _str "\nRun 'CMD SUBCOMMAND --help' for more information on a command."
    return _str
}

function print_helpdoc( args, obj,          obj_prefix, argl, i, l, v, _str){
    obj_prefix = SUBSEP "\"1\""   # Json Parser
    argl = args[L]
    for (i=2; i<=argl; ++i){
        l = aobj_len( obj, obj_prefix )
        for (j=1; j<=l; ++j) {
            optarg_id = aobj_get( obj, obj_prefix SUBSEP j)
            if ("|"juq(optarg_id)"|" ~ "\\|"args[i]"\\|") {
                obj_prefix = obj_prefix SUBSEP optarg_id
                break
            }
        }
    }

    l = aobj_len( obj, obj_prefix )
    for (i=1; i<=l; ++i) {
        v = aobj_get( obj, obj_prefix SUBSEP i)
        if (( v ~ "^\"-" ) && ( ! aobj_istrue(obj, aobj_get_special_value_id(obj_prefix SUBSEP v, "subcmd")) )) {
            if (aobj_get_optargc( obj, obj_prefix, v ) > 0) arr_push( option, v)
            else arr_push( flag, v )
        }
        else if ( v ~ "^\"#(([0-9]+)|n)\"$" ) arr_push( restopt, v )
        else if ( v !~ "^\"#" ) arr_push( subcmd, v )
    }

    if ( arr_len(flag) != 0 )    _str = generate_help( obj, obj_prefix, flag, "FLAGS" )
    if ( arr_len(option) != 0 )  _str = _str generate_help( obj, obj_prefix, option, "OPTIONS" )
    if ( arr_len(restopt) != 0 ) _str = _str generate_help( obj, obj_prefix, restopt, "ARGS" )
    if ( arr_len(subcmd) != 0 )  _str = _str generate_help( obj, obj_prefix, subcmd, "SUBCOMMANDS" )
    print _str
}

{
    if (NR == 1) { prepare_argarr( $0 ); next; }
    if ($0 != "") jiparse_after_tokenize(obj, $0)
}

END{ print_helpdoc( args, obj ) > "/dev/stderr"; }