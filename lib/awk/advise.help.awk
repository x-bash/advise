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

function cut_line( _line, _space_len,               _max_len_line, l, _len, i){
    if( COLUMNS == "" )     return _line

    _max_len_line = COLUMNS - _space_len - 3 - 4
    if ( length(_line) < _max_len_line )  return _line

    l = split( _line, _arr, " " )
    for(i=1; i<=l; ++i){
        _len += length(_arr[i]) + 1
        if (_len >= _max_len_line) {
            _len -= ( length(_arr[i]) + 1 )
            break
        }
    }
    return substr(_line, 1, _len) "\n" str_rep(" ", _space_len+7)  cut_line( substr(_line, _len + 1 ), _space_len )
}

function str_joinwrap2(sep, obj, prefix, start, end,     i, _result) {
    _result = (start <= end) ? obj[prefix, "\""start"\""] : ""
    for (i=start+1; i<=end; ++i) _result = _result sep obj[prefix, "\""i"\""]
    return _result
}

function get_option_string( obj, obj_prefix, v,         _str){
    _str = juq(v)
    gsub("\\|", ",", _str)
    return _str juq(obj[ obj_prefix, v, "\"#arguments_str\""])
}

function generate_help_for_namedoot_cal_maxlen_desc( obj, obj_prefix, _text_arr,            l, i, _len, _max_len, _opt_help_doc ){
    l = _text_arr[ L ]
    for ( i=1; i<=l; ++i ) {
        _text_arr[ i ]   =  _opt_help_doc    = get_option_string( obj, obj_prefix, _text_arr[ i ] )
        _text_arr[ i L ] = _len              = length( _opt_help_doc )        # TODO: Might using wcswidth
        if ( _len > _max_len )    _max_len = _len
    }
    return _max_len
}

function generate_optarg_rule_string_inner(obj, obj_prefix,     _str, _dafault, _regexl, _candl){
    _default = arr_get(obj, obj_prefix SUBSEP "\"#default\"" )
    _regexl  = arr_get(obj, obj_prefix SUBSEP "\"#cand_regex\"" L)
    _candl   = arr_get(obj, obj_prefix SUBSEP "\"#cand\"" L)
    if (_default != "" ) _str = _str " [default: "   juq(_default) "]"
    if ( _regexl > 0 )   _str = _str " [regex: "     str_joinwrap2( "|", obj, obj_prefix SUBSEP "\"#cand_regex\"" , 1, _regexl ) "]"
    if ( _candl > 0  )   _str = _str " [candidate: " str_joinwrap2( ", ", obj, obj_prefix SUBSEP "\"#cand\"" , 1, _candl ) "]"
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
        _option_after = juq(obj[ obj_prefix, v, "\"#desc\"" ]) UI_END generate_optarg_rule_string(obj, obj_prefix, v)

        _str = _str HELP_INDENT_STR sprintf("%s" DESC_INDENT_STR "%s\n",
            UI_LEFT         str_pad_right( _text_arr[i], _max_len ),
            UI_RIGHT        cut_line( _option_after, _max_len ))
    }
    if (text == "SUBCOMMANDS") _str = _str "\nRun 'CMD SUBCOMMAND --help' for more information on a command."
    return _str
}

function print_helpdoc( args, obj,          obj_prefix, argl, i, l, v, _str){
    obj_prefix = SUBSEP "\"1\""   # Json Parser
    argl = args[L]
    for (i=2; i<=argl; ++i){
        l = obj[obj_prefix L]
        for (j=1; j<=l; ++j) {
            optarg_id = obj[obj_prefix, j]
            if ("|"juq(optarg_id)"|" ~ "\\|"args[i]"\\|") {
                obj_prefix = obj_prefix SUBSEP optarg_id
                break
            }
        }
    }

    l = obj[ obj_prefix L]
    for (i=1; i<=l; ++i) {
        v = obj[ obj_prefix, i ]
        if (( v ~ "^\"-" ) && ( obj[ obj_prefix, v, "\"#subcmd\"" ] != "true" )) {
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