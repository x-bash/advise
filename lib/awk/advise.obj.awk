

function aobj_get_subcmdid_by_name( obj, obj_prefix, name ){

}

function aobj_get_id_by_name( obj, obj_prefix, name ){

}

function aobj_required( obj, kp ){
    if (obj[ kp, "#require" ] == "true" ) {
        return 1
    } else {
        return 0
    }
}

function aobj_get_optargc( obj, obj_prefix, option_id ){

}

function aobj_cal_rest_argc_maxmin( obj, obj_prefix, rest_arg_id,       i, l, k, _min, _max, _id ){
    l = obj[ obj_prefix L ]
    _min = 0
    _max = 0
    for (i=1; i<=l; ++i) {
        k = obj[ obj_prefix, i ]
        if (k ~ "(^[^#])|(^#n)") continue
        k = int( substr(k, 2) )

        if (aobj_required( obj, obj_prefix SUBSEP i ) ) {
            if (_min < i) _min = i
        }
        if (_max < i) _max = i
    }

    _id = aobj_get_id_by_name( obj, obj_prefix, "#n")
    if ( _id != "" ) {
        _max = 10000    # Big Number
    }

    obj[ obj_prefix, L "restarg__min" ] = _min
    obj[ obj_prefix, L "restarg__max" ] = _max

}

function aobj_get__minimum_rest_argc( obj, obj_prefix, rest_arg_id,  _res ){
    if ( ( _res = obj[ obj_prefix, L "restarg__min" ] ) != "" ) return _res

    aobj_cal_rest_argc_maxmin( obj, obj_prefix, rest_arg_id )
    return obj[ obj_prefix, L "restarg__min" ]
}

function aobj_get__maximum_rest_argc( obj, obj_prefix, rest_arg_id, _res ){
    if ( ( _res = obj[ obj_prefix, L "restarg__max" ] ) != "" ) return _res

    aobj_cal_rest_argc_maxmin( obj, obj_prefix, rest_arg_id )
    return obj[ obj_prefix, L "restarg__max" ]
}


