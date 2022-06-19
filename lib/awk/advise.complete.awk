
# shellcheck shell=bash

function advise_complete___generic_value( curval, genv, lenv, obj, kp,      i, v, _cand_key_arr, _cand_key_arrl, _exec_val, _desc ){

    _cand_key_arr = kp SUBSEP "\"#cand\""
    _cand_key_arrl = obj[ _cand_key_arr L ]
    if ( _cand_key_arrl != "" ) {
        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=_cand_key_arrl; ++i) {
            v = obj[ _cand_key_arr, "\"" i "\"" ]
            if( v ~ "^\"" curval ) CODE = CODE v "\n"
        }
        CODE = CODE ")"
    }

    _exec_val = obj[ kp SUBSEP "\"#exec\"" ]
    if ( _exec_val != "" ) {
        CODE = CODE "\n" "candidate_exec=" _exec_val ";"
    }

    _regex_key_arr = kp SUBSEP "\"#regex\""
    _regex_key_arrl = obj[ _regex_key_arr L ]
    if ( _regex_key_arrl != "" ) {
        CODE = CODE "\n" "candidate_regex=(" "\n"
        for (i=1; i<=_regex_key_arrl; ++i) {
            CODE = CODE obj[ _regex_key_arr, "\"" i "\"" ] "\n"
        }
        CODE = CODE ")"
    }

    # TODO: Other code
    return CODE
}

# Just show the value
function advise_complete_option_value( curval, genv, lenv, obj, obj_prefix, option_id, arg_nth ){
    return advise_complete___generic_value( curval, genv, lenv, obj, obj_prefix SUBSEP option_id SUBSEP "\"#" arg_nth "\"")
}

# Just tell me the arguments
function advise_complete_argument_value( curval, genv, lenv, obj, obj_prefix, nth,      _kp, i, l , v, _option_id, _desc, _arr_value, _arr_valuel ){

    if (nth == 1) {
        CODE = CODE "\n" "argument_arr=(" "\n"
        l = obj[ obj_prefix L ]
        for (i=1; i<=l; ++i) {
            _option_id = obj[ obj_prefix, i ]
            if ( _option_id ~ "^\"#") continue
            _desc = juq(obj[ obj_prefix SUBSEP _option_id SUBSEP "\"#desc\"" ])
            _arr_valuel = split( juq( _option_id ), _arr_value, "|" )
            for ( j=1; j<=_arr_valuel; ++j) {
                v =_arr_value[j]
                if (v ~ "^"curval) {
                    if (( curval == "" ) && ( v ~ "^-" )) if ( ! aobj_required(obj, obj_prefix SUBSEP i) ) continue
                    if ( _desc != "" ) CODE = CODE jqu(v ":" _desc) "\n"
                    else CODE = CODE jqu(v) "\n"
                }
            }
        }
        CODE = CODE ")"
    }

    _kp = obj_prefix SUBSEP "\"#" nth "\""
    if (obj[ _kp ] != "") {
        return advise_complete___generic_value( curval, genv, lenv, obj, _kp )
    }

    _kp = obj_prefix SUBSEP "\"#n\""
    if (obj[ _kp ] != "") {
        return advise_complete___generic_value( curval, genv, lenv, obj, _kp )
    }

    _kp = obj_prefix SUBSEP "\"#n\""
    if (obj[ _kp ] != "") {
        return advise_complete___generic_value( curval, genv, lenv, obj, _kp )
    }

    return advise_complete___generic_value( curval, genv, lenv, obj, obj_prefix )
}

# Most complicated
function advise_complete_option_name_or_argument_value( curval, genv, lenv, obj, obj_prefix,        _option_id, i, j, k, v, _arrl, _desc, _arr_valuel, _arr_value ){
    if ( curval ~ /^--/ ) {
        _arrl = obj[ obj_prefix L ]
        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=_arrl; ++i) {
            _option_id = obj[ obj_prefix, i ]
            _desc = juq(obj[ obj_prefix SUBSEP _option_id SUBSEP "\"#desc\"" ])
            _arr_valuel = split( juq(_option_id), _arr_value, "|" )
            for ( j=1; j<=_arr_valuel; ++j) {
                v = _arr_value[j]
                if ((v ~ curval) && (lenv[ _option_id ] == "")) {
                    if ( _desc != "" ) CODE = CODE jqu(v ":" _desc) "\n"
                    else CODE = CODE jqu(v) "\n"
                }
            }
        }
        CODE = CODE ")"
        return CODE
    }

    if ( curval ~ /^-/ ) {
        _arrl = obj[ obj_prefix L ]
        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=_arrl; ++i) {
            _option_id = obj[ obj_prefix, i ]
            _desc = juq(obj[ obj_prefix SUBSEP _option_id SUBSEP "\"#desc\"" ])
            _arr_valuel = split( juq( _option_id ), _arr_value, "|" )
            for ( j=1; j<=_arr_valuel; ++j) {
                v = _arr_value[j]
                if ((v ~ "--") || ( v !~ "^-")) continue
                if ((v ~ curval) && (lenv[ _option_id ] == "")) {
                    if ( _desc != "" ) CODE = CODE jqu(v ":" _desc) "\n"
                    else CODE = CODE jqu(v) "\n"
                }
            }
        }
        CODE = CODE ")"
        return CODE
    }

    # if ( aobj_option_all_set( lenv, obj, obj_prefix ) ) {
        return advise_complete_argument_value( curval, genv, lenv, obj, obj_prefix, 1 )
    # }

    # l = obj[ obj_prefix L ]

    # CODE = CODE "\n" "candidate_arr=(" "\n"
    # for (i=1; i<=l; ++i) {
    #     k = obj[ obj_prefix, i ]
    #     if (k ~ "^[^-]") continue
    #     if ( aobj_istrue(obj, obj_prefix SUBSEP k SUBSEP "\"#subcmd\"" ) ) continue

    #     if ( aobj_required(obj, obj_prefix SUBSEP k) ) {
    #         _cand_key_desc = obj_prefix SUBSEP k SUBSEP "\"#desc\""
    #         _desc = obj[ _cand_key_desc ]
    #         if ( lenv_table[ k ] == "" ) {
    #             if( _desc != "" )   CODE = CODE k ":" _desc "\n"
    #             else CODE = CODE k "\n"
    #         }
    #     }
    # }

    # CODE = CODE ")"
    # return CODE
}
