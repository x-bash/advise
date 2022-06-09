
# Except getting option argument count
function aobj_cal_rest_argc_maxmin( obj, obj_prefix,       i, j, k, l, _min, _max, _arr, _arrl ){
    _min = 0
    _max = 0
    l = obj[ obj_prefix L ]
    for (i=1; i<=l; ++i) {
        k = obj[ obj_prefix, i ]

        if (k ~ "^#n") {
            _max = 10000 # Big Number
            continue
        }

        if (k ~ "^#[a-z]") continue

        _arrl = split(k, _arr, "|")
        for (j=1; j<=_arrl; ++j) NAME_ID[ obj_prefix, _arr[j] ] = k

        if (k ~ "^#[0-9]+") {
            k = int( substr(k, 2) )
            if (aobj_required( obj, obj_prefix SUBSEP i ) ) {
                if (_min < i) _min = i
            }
            if (_max < i) _max = i
        }

    }

    obj[ obj_prefix, L "restargc__min" ] = _min
    obj[ obj_prefix, L "restargc__max" ] = _max
}

function aobj_option_all_set( lenv_table, obj, obj_prefix,  i, l, k ){
    l = obj[ obj_prefix L ]
    for (i=1; i<=l; ++i) {
        k = obj[ obj_prefix, i ]
        if (k ~ "^[^-]") continue
        if ( aobj_istrue(obj, obj_prefix SUBSEP k SUBSEP "#subcmd" ) ) continue

        if ( aobj_required(obj, obj_prefix SUBSEP k) ) {
            if ( lenv_table[ k ] == "" )  return false
        }
    }
    return true
}

function aobj_get_subcmdid_by_name( obj, obj_prefix, name, _res ){
    _res = aobj_get_id_by_name( obj, obj_prefix, name )
    if ( _res ~ /^[^-]/) return _res
    if ( aobj_istrue(obj, obj_prefix SUBSEP _res SUBSEP "#subcmd" ) ) return _res
    return
}

function aobj_get_id_by_name( obj, obj_prefix, name, _res ){
    if ("" != (_res = NAME_ID[ obj_prefix, name ]) )  return _res
    aobj_cal_rest_argc_maxmin( obj, obj_prefix )
    return NAME_ID[ obj_prefix, name ]
}

function aobj_required( obj, kp ){
    return (obj[ kp, "#r" ] == "true" )
}

function aobj_istrue( obj, kp ){
    return (obj[ kp ] == "true" )
}

function aobj_get_optargc( obj, obj_prefix, option_id,  _res, i ){
    if ( "" != (_res = obj[ obj_prefix, option_id L "argc" ]) ) return _res
    for (i=1; i<100; ++i) {     # 100 means MAXINT
        if (obj[ obj_prefix, option_id, "#" i ] == "") break
    }
    obj[ obj_prefix, option_id L "argc" ] = i - 1
    return i - 1
}

function aobj_get__minimum_rest_argc( obj, obj_prefix, rest_arg_id,  _res ){
    if ( ( _res = obj[ obj_prefix, L "restargc__min" ] ) != "" ) return _res

    aobj_cal_rest_argc_maxmin( obj, obj_prefix, rest_arg_id )
    return obj[ obj_prefix, L "restargc__min" ]
}

function aobj_get__maximum_rest_argc( obj, obj_prefix, rest_arg_id, _res ){
    if ( ( _res = obj[ obj_prefix, L "restargc__max" ] ) != "" ) return _res

    aobj_cal_rest_argc_maxmin( obj, obj_prefix, rest_arg_id )
    return obj[ obj_prefix, L "restargc__max" ]
}


