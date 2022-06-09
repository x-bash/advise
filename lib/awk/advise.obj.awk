
# Except getting option argument count
function aobj_cal_rest_argc_maxmin( obj, obj_prefix,       i, j, k, l, _l, _id, _min, _max, _id ){
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

        arrl = split(k, arr, "|")
        j = 0
        _l = 0
        _id = obj_prefix SUBSEP k
        for (j=1; j<=arrl; ++j) {
            NAME_ID[ obj_prefix, arr[j] ] = _id
        }

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
        if ( obj[obj_prefix, i, "#subcmd"] == "true" ) continue

        if ( obj[ obj_prefix, i, "#r" ] == "true" ) {
            if ( lenv_table[ k ] == "" )  return false
        }
    }
    return true
}

function aobj_get_subcmdid_by_name( obj, obj_prefix, name, _res ){
    _res = aobj_get_id_by_name( obj, obj_prefix, name )
    if ( _res ~ /^[^-]/) return _res
    if ( obj[ obj_prefix, _res, "#subcmd" ] == "true" ) return _res
    return
}

function aobj_get_id_by_name( obj, obj_prefix, name, _res ){
    if ("" != (_res = NAME_ID[ obj_prefix, name ]) )  return _res
    aobj_cal_rest_argc_maxmin( obj, obj_prefix )
    return NAME_ID[ obj_prefix, name ]
}

function aobj_required( obj, kp ){
    if (obj[ kp, "#require" ] == "true" ) {
        return 1
    } else {
        return 0
    }
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


