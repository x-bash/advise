
# shellcheck shell=bash

function advise_complete___generic_value( curval, genv, lenv, obj, kp ){

    _cand_key_key = kp SUBSEP "\"#cand\""
    _cand_key_arrl = obj[ _cand_key L ]

    if ( _cand_key_arrl != "" ) {
        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=_cand_key_arrl; ++i) {
            CODE = CODE  obj[ _cand_key_key, i] "\n"
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
    return advise_complete___generic_value( curval, genv, lenv, obj, obj_prefix SUBSEP option_id SUBSEP arg_nth )
}

# Just tell me the arguments
function advise_complete_argument_value( curval, genv, lenv, obj, obj_prefix, nth ){
    _kp = obj_prefix SUBSEP "\"#" nth "\""
    if (obj[ _kp ] != "") {
        return advise_complete___generic_value( curval, genv, lenv, obj, _kp )
    }

    _kp = obj_prefix SUBSEP "\"#n\""
    if (obj[ _kp ] != "") {
        return advise_complete___generic_value( curval, genv, lenv, obj, _kp )
    }
}

# Most complicated
function advise_complete_option_name_or_argument_value( curval, genv, lenv, obj, obj_prefix ){
    if ( curval ~ /^--/ ) {
        _arrl = obj[ obj_prefix L ]
        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=_arrl; ++i) {
            v = obj[ obj_prefix, i ]
            if (v ~ "^\"" curval) {
                CODE = CODE v "\n"
            }
        }

        return CODE
    }

    if ( curval ~ /^-/ ) {
        _arrl = obj[ obj_prefix L ]
        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=_arrl; ++i) {
            v = obj[ obj_prefix, i ]
            if (v ~ "^\"" curval) {
                if (v ~ "^\"--") continue
                CODE = CODE v "\n"
            }
        }
        return CODE
    }

    if ( aobj_options_all_ready( obj, obj_prefix, lenv ) ) {
        return advise_complete_argument_value( curval, genv, lenv, obj, obj_prefix, 1 )
    } else {
        l = obj[ obj_prefix L ]

        CODE = CODE "\n" "candidate_arr=(" "\n"
        for (i=1; i<=l; ++i) {
            k = obj[ obj_prefix, i ]
            if (k ~ "^[^-]") continue
            if ( aobj_istrue(obj, obj_prefix SUBSEP k SUBSEP "\"#subcmd\"" ) ) continue

            if ( aobj_required(obj, obj_prefix SUBSEP k) ) {
                if ( lenv_table[ k ] == "" ) {
                    CODE = CODE k "\n"
                }
            }
        }
        return CODE
    }
}
