
# shellcheck shell=bash

function advise_complete___generic_value( curval, genv, lenv, obj, kp,      i, v, _cand_key_key, _cand_key_arrl, _exec_val, _desc ){
    _cand_key_key = kp SUBSEP "\"#cand\""
    _cand_key_arrl = obj[ _cand_key_key L ]

    if ( _cand_key_arrl != "" ) {
        CODE = CODE "\n" "candidate_arr=(" "\n"
        CODE = CODE ARG_VALUE
        for (i=1; i<=_cand_key_arrl; ++i) {
            v = obj[ _cand_key_key, "\"" i "\"" ]
            if( v ~ "^\"" curval ) CODE = CODE v "\n"
        }
        CODE = CODE ")"
        ARG_VALUE = ""
    }

    _exec_val = obj[ kp SUBSEP "\"#exec\"" ]
    if ( _exec_val != "" ) {
        CODE = CODE "\n" "candidate_exec=" _exec_val ";"
    }

    # TODO: Other code
    return CODE
}

# Just show the value
function advise_complete_option_value( curval, genv, lenv, obj, obj_prefix, option_id, arg_nth ){
    return advise_complete___generic_value( curval, genv, lenv, obj, obj_prefix SUBSEP option_id SUBSEP "\"#" arg_nth "\"")
}

# Just tell me the arguments
function advise_complete_argument_value( curval, genv, lenv, obj, obj_prefix, nth,      _kp, i, l , v, _desc, _arr_v, _arr_vl ){

    l = obj[ obj_prefix L ]
    for (i=1; i<=l; ++i) {
        v = obj[ obj_prefix, i ]
        if ((v ~ curval) && ( v !~ "^\"#")) {
            if (( curval == "" ) && ( v ~ "^\"-" )) if ( ! aobj_required(obj, obj_prefix SUBSEP i) ) continue
            _desc = juq(obj[ obj_prefix SUBSEP v SUBSEP "\"#desc\"" ])
            _arr_vl = split( juq(v), _arr_v, "|" )
            for ( j=1; j<=_arr_vl; ++j) {
                if ( _desc != "" ) ARG_VALUE = ARG_VALUE jqu(_arr_v[j] ":" _desc) "\n"
                else ARG_VALUE = ARG_VALUE jqu(_arr_v[j]) "\n"
            }
        }
    }

    _kp = obj_prefix SUBSEP "\"#" nth "\""
    if (obj[ _kp ] != "") {
        return advise_complete___generic_value( curval, genv, lenv, obj, _kp )
    }

    _kp = obj_prefix SUBSEP "\"#n\""
    if (obj[ _kp ] != "") {
        return advise_complete___generic_value( curval, genv, lenv, obj, _kp )
    }

    CODE = CODE "\n" "candidate_arr=(" "\n"
    CODE = CODE ARG_VALUE
    CODE = CODE ")"
    ARG_VALUE=""
}

# Most complicated
function advise_complete_option_name_or_argument_value( curval, genv, lenv, obj, obj_prefix,        i, j, k, v, _arrl, _desc, _arr_vl, _arr_v ){
    if ( curval ~ /^--/ ) {
        _arrl = obj[ obj_prefix L ]
        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=_arrl; ++i) {
            v = obj[ obj_prefix, i ]
            if (v ~ curval) {
                _desc = juq(obj[ obj_prefix SUBSEP v SUBSEP "\"#desc\"" ])
                _arr_vl = split( juq(v), _arr_v, "|" )
                for ( j=1; j<=_arr_vl; ++j) {
                    if ( _desc != "" ) CODE = CODE jqu(_arr_v[j] ":" _desc) "\n"
                    else CODE = CODE jqu(_arr_v[j]) "\n"
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
            v = obj[ obj_prefix, i ]
            if ((v ~ curval) && (lenv[v] == "")) {
                if (v ~ "^--") continue
                _desc = juq(obj[ obj_prefix SUBSEP v SUBSEP "\"#desc\"" ])
                _arr_vl = split( juq(v), _arr_v, "|" )
                for ( j=1; j<=_arr_vl; ++j) {
                    if ( _desc != "" ) CODE = CODE jqu(_arr_v[j] ":" _desc) "\n"
                    else CODE = CODE jqu(_arr_v[j]) "\n"
                }
            }
        }
        CODE = CODE ")"
        return CODE
    }

    if ( aobj_option_all_set( lenv, obj, obj_prefix ) ) {
        return advise_complete_argument_value( curval, genv, lenv, obj, obj_prefix, 1 )
    }

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
