
# shellcheck shell=bash

function advise_complete___generic_value( curval, genv, lenv, obj, kp,      i, v, _cand_key_key, _cand_key_arrl, _exec_val, _cand_key_desc ){

    _cand_key_key = kp SUBSEP "\"#cand\""
    if ( obj [ _cand_key_key ] == "" )      _cand_key_key = kp

    _cand_key_arrl = obj[ _cand_key_key L ]

    if ( _cand_key_arrl != "" ) {
        CODE = CODE "\n" "candidate_arr=(" "\n"
        DESC = DESC "\n" "candidate_desc_arr=(" "\n"
        for (i=1; i<=_cand_key_arrl; ++i) {
            v = obj[ _cand_key_key, jqu(i)]
            _cand_key_desc = _cand_key_key SUBSEP v SUBSEP "\"#desc\""
            if( v ~ "^\"" curval ){
                if (v ~ "^\"#[a-z]") continue
                if( obj[ _cand_key_desc ] != "" )   DESC = DESC v ":" obj[ _cand_key_desc ] "\n"
                CODE = CODE v "\n"
            }
        }
        CODE = CODE ")"
        DESC = DESC ")"
    }
    # print "DESC: " DESC

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
        DESC = DESC "\n" "candidate_desc_arr=(" "\n"
        for (i=1; i<=_arrl; ++i) {
            v = obj[ obj_prefix, jqu(i) ]
            _cand_key_desc = obj_prefix SUBSEP v SUBSEP "\"#desc\""
            if (v ~ "^\"" curval) {
                if( obj[ _cand_key_desc ] != "" )   DESC = DESC v ":" obj[ _cand_key_desc ] "\n"
                CODE = CODE v "\n"
            }
        }
        CODE = CODE ")"
        DESC = DESC ")"
        return CODE
    }

    if ( curval ~ /^-/ ) {
        _arrl = obj[ obj_prefix L ]
        CODE = CODE "\n" "candidate_arr=(" "\n"
        DESC = DESC "\n" "candidate_desc_arr=(" "\n"
        for (i=1; i<=_arrl; ++i) {
            v = obj[ obj_prefix, jqu(i) ]
            _cand_key_desc = obj_prefix SUBSEP v SUBSEP "\"#desc\""
            if (v ~ "^\"" curval) {
                if (v ~ "^\"--") continue
                if( obj[ _cand_key_desc ] != "" )   DESC = DESC v ":" obj[ _cand_key_desc ] "\n"
                CODE = CODE v "\n"
            }
        }
        CODE = CODE ")"
        DESC = DESC ")"
        # print "DESC: " DESC
        return CODE
    }

    if ( aobj_option_all_set( lenv, obj, obj_prefix ) ) {
        return advise_complete_argument_value( curval, genv, lenv, obj, obj_prefix, 1 )
    } else {
        l = obj[ obj_prefix L ]

        CODE = CODE "\n" "candidate_arr=(" "\n"
        DESC = DESC "\n" "candidate_desc_arr=(" "\n"
        for (i=1; i<=l; ++i) {
            k = obj[ obj_prefix, jqu(i) ]
            if (k ~ "^[^-]") continue
            if ( aobj_istrue(obj, obj_prefix SUBSEP k SUBSEP "\"#subcmd\"" ) ) continue

            if ( aobj_required(obj, obj_prefix SUBSEP k) ) {
                _cand_key_desc = obj_prefix SUBSEP k SUBSEP "\"#desc\""
                if ( lenv_table[ k ] == "" ) {
                    if( obj[ _cand_key_desc ] != "" )   DESC = DESC k ":" obj[ _cand_key_desc ] "\n"
                    CODE = CODE k "\n"
                }
            }
        }
        CODE = CODE ")"
        DESC = DESC ")"
        return CODE
    }
}
