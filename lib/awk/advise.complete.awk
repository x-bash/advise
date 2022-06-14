
# shellcheck shell=bash

function advise_complete___generic_value( curval, genv, lenv, obj, kp,      i, v, _cand_key_key, _cand_key_arrl, _exec_val, _cand_key_desc ){

    _cand_key_key = kp SUBSEP "\"#cand\""
    if ( obj [ _cand_key_key ] == "" )      _cand_key_key = kp

    _cand_key_arrl = obj[ _cand_key_key L ]

    if ( _cand_key_arrl != "" ) {
        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=_cand_key_arrl; ++i) {
            v = obj[ _cand_key_key, jqu(i)]
            _cand_key_desc = _cand_key_key SUBSEP v SUBSEP "\"#desc\""
            DESC = obj[ _cand_key_desc ]
            if( v ~ "^\"" curval ){
                if (v ~ "^\"#[a-z]") continue
                if( DESC != "" )   CODE = CODE v ":" DESC "\n"
                else CODE = CODE v "\n"
            }
        }
        CODE = CODE ")"
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
function advise_complete_argument_value( curval, genv, lenv, obj, obj_prefix, nth,      _kp ){
    _kp = obj_prefix SUBSEP "\"#" nth "\""
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
function advise_complete_option_name_or_argument_value( curval, genv, lenv, obj, obj_prefix,        i, k, v, l,  _arrl, _cand_key_desc ){
    if ( curval ~ /^--/ ) {
        _arrl = obj[ obj_prefix L ]
        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=_arrl; ++i) {
            v = obj[ obj_prefix, jqu(i) ]
            _cand_key_desc = obj_prefix SUBSEP v SUBSEP "\"#desc\""
            DESC = obj[ _cand_key_desc ]
            if (v ~ curval) {
                if( DESC != "" )   CODE = CODE v ":" DESC "\n"
                else CODE = CODE v "\n"
            }
        }
        CODE = CODE ")"
        return CODE
    }

    if ( curval ~ /^-/ ) {
        _arrl = obj[ obj_prefix L ]
        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=_arrl; ++i) {
            v = obj[ obj_prefix, jqu(i) ]
            _cand_key_desc = obj_prefix SUBSEP v SUBSEP "\"#desc\""
            DESC = obj[ _cand_key_desc ]
            if (v ~ curval) {
                if (v ~ "^--") continue
                if( DESC != "" )   CODE = CODE v ":" DESC "\n"
                else CODE = CODE v "\n"
            }
        }
        CODE = CODE ")"
        return CODE
    }

    if ( aobj_option_all_set( lenv, obj, obj_prefix ) ) {
        return advise_complete_argument_value( curval, genv, lenv, obj, obj_prefix, 1 )
    } else {
        l = obj[ obj_prefix L ]

        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=l; ++i) {
            k = obj[ obj_prefix, jqu(i) ]
            if (k ~ "^[^-]") continue
            if ( aobj_istrue(obj, obj_prefix SUBSEP k SUBSEP "\"#subcmd\"" ) ) continue

            if ( aobj_required(obj, obj_prefix SUBSEP k) ) {
                _cand_key_desc = obj_prefix SUBSEP k SUBSEP "\"#desc\""
                DESC = obj[ _cand_key_desc ]
                if ( lenv_table[ k ] == "" ) {
                    if( DESC != "" )   CODE = CODE k ":" DESC "\n"
                    else CODE = CODE k "\n"
                }
            }
        }
        CODE = CODE ")"
        return CODE
    }
}
