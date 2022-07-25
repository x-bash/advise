
{
    if (NR>1) {
        # if ($0 != "") jiparse(obj, $0)
        if ($0 != "") jiparse_after_tokenize(obj, $0)
    } else {
        prepare_argarr( $0 )
    }
}

END{
    FG_BLUE = "\033[36m"
    FG_RED  = "\033[91m"
    UI_END  = "\033[0m"
    HELP_INDENT_STR = "    "
    DESC_INDENT_STR = "   "
    print_helpdoc( parsed_argarr, obj )
}

# Section: prepare argument
function prepare_argarr( argstr,        i, l, _arg ){
    if ( argstr == "" ) argstr = "" # "." "\002"

    gsub("\n", "\001", argstr)
    l = split(argstr, parsed_argarr, "\002")

    for (i=1; i<=parsed_arglen; ++i) {
        _arg = parsed_argarr[i]
        gsub("\001", "\n", _arg)
        parsed_argarr[i] = _arg
    }
    parsed_argarr[L] = l
}

function aobj_get_optargc( obj, obj_prefix, option_id,  _res, i, l, v ){
    obj_prefix = obj_prefix SUBSEP option_id
    if ( "" != (_res = obj[ obj_prefix L "argc" ]) ) return _res
    for (i=1; i<100; ++i) {     # 100 means MAXINT
        if (obj[ obj_prefix, jqu("#" i) ] == "") break
    }
    if (i != 1 ) return obj[ obj_prefix, option_id L "argc" ] = --i
    else {
        if ( obj[ obj_prefix ] == "[") return obj[ obj_prefix L "argc" ] = ( obj[ obj_prefix, option_id L ] != 0 )
        l = obj[ obj_prefix L]
        for (i=1; i<=l; ++i) {
            v = obj[ obj_prefix, i ]
            if ((v ~ "^\"#exec") || (v ~ "^\"#cand") || v ~ "^\"#regex") return obj[ obj_prefix L "argc" ] = 1
            if (v ~ "^\"#") continue
            return obj[ obj_prefix L "argc" ] = 1
        }
    }
    return 0
}

function get_option_string( obj, obj_prefix, v,         _str){
    _str = juq(v)
    gsub("\\|", ",", _str)
    return _str juq(obj[ obj_prefix, v, "\"#arguments_str\""])
}

function str_joinwrap2(sep, obj, prefix, start, end,     i, _result) {
    _result = (start <= end) ? obj[prefix SUBSEP "\""start"\""] : ""
    for (i=start+1; i<=end; ++i) _result = _result sep obj[prefix SUBSEP "\""start"\""]
    return _result
}

function generate_help_for_namedoot_cal_maxlen_desc( obj, obj_prefix, opt_text_arr,            l, i, _len, _max_len, _opt_help_doc ){
    _max_len = 0
    l = opt_text_arr[ L ]
    for ( i=1; i<=l; ++i ) {
        opt_text_arr[ i ]   =  _opt_help_doc    = get_option_string( obj, obj_prefix, opt_text_arr[ i ] )       # obj[ i ] is option_ids
        opt_text_arr[ i L ] = _len              = length( _opt_help_doc )        # TODO: Might using wcswidth
        if ( _len > _max_len )    _max_len = _len
    }
    return _max_len
}

function generate_optarg_rule_string_inner(obj, obj_prefix, option_id,     _str, _dafault, _regexl, _candl){
    _default = obj[ obj_prefix SUBSEP option_id SUBSEP "\"#default\"" ]
    _regexl = obj[ obj_prefix SUBSEP option_id SUBSEP "\"#cand_regex\"" L]
    _candl = obj[ obj_prefix SUBSEP option_id SUBSEP "\"#cand\"" L]
    if (_default != "" ) _str = _str " [default: "   juq(_default) "]"
    if ( _regexl > 0 )   _str = _str " [regex: "     str_joinwrap2( "|", obj, obj_prefix SUBSEP option_id SUBSEP "\"#cand_regex\"" , 1, _regexl ) "]"
    if ( _candl > 0  )   _str = _str " [candidate: " str_joinwrap2( ", ", obj, obj_prefix SUBSEP option_id SUBSEP "\"#cand\"" , 1, _candl ) "]"
    return _str
}

function generate_optarg_rule_string(obj, obj_prefix, option_id,     _str, _dafault, _regexl, _candl, l, i) {
    l = aobj_get_optargc( obj, obj_prefix, option_id )
    _str = _str generate_optarg_rule_string_inner(obj, obj_prefix, option_id)
    obj_prefix = obj_prefix SUBSEP option_id
    for (i=1; i<=l; ++i) _str = _str generate_optarg_rule_string_inner(obj, obj_prefix, "\"#"i"\"")
    return _str
}

function cut_line( _line, _space_len,               _max_len_line, _option_after_arrl, _part_len, key){
    if( COLUMNS == "" )     return _line

    _max_len_line = COLUMNS - _space_len - 3 - 4
    if ( length(_line) < _max_len_line )  return _line

    _option_after_arrl = split( _line, _option_after_arr, " " )
    for(key=1; key<=_option_after_arrl; ++key){
        _part_len += length(_option_after_arr[key]) + 1
        if (_part_len >= _max_len_line) {
            _part_len -= ( length(_option_after_arr[key]) + 1 )
            break
        }
    }
    return substr(_line, 1, _part_len) "\n" str_rep(" ", _space_len+7)  cut_line( substr(_line, _part_len + 1 ), _space_len )
}

function generate_help( obj, obj_prefix, arr, text,          i, v, _str, _max_len, opt_text_arr, _option_after ){
    arr_clone( arr, opt_text_arr )
    _max_len = generate_help_for_namedoot_cal_maxlen_desc( obj, obj_prefix, opt_text_arr )
    _str = "\n" text ":\n"
    for ( i=1; i<=arr_len(arr); ++i ) {
        v = arr[ i ]
        _option_after = juq(obj[ obj_prefix, v, "\"#desc\"" ]) UI_END generate_optarg_rule_string(obj, obj_prefix, v)
        _str = _str HELP_INDENT_STR sprintf("%s" DESC_INDENT_STR "%s\n",
            FG_BLUE         str_pad_right(opt_text_arr[i], _max_len),
            FG_RED          cut_line( _option_after, _max_len ))
    }
    if (text == "SUBCOMMANDS") _str = _str "\nRun 'CMD SUBCOMMAND --help' for more information on a command."
    return _str
}

function print_helpdoc( args, obj,          obj_prefix, argl, i, l, v, _str){
    obj_prefix = SUBSEP "\"1\""   # Json Parser
    argl = args[L]
    for (i =1; i<=argl; ++i){
        obj_prefix = obj_prefix SUBSEP jqu(args[i])
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
