
# Just show the value
function advise_complete_option_value( curval, genv, lenv, obj, obj_prefix, option_id, arg_nth ){
    # Just show the option value
    # eval and set the value
}

# Just tell me the arguments
function advise_complete_argument_value( curval, genv, lenv, obj, obj_prefix, nth ){

}

# Most complicated
function advise_complete_option_name_or_argument_value( curval, genv, lenv, obj, obj_prefix, nth ){
    if ( curval ~ /^--/ ) {
        # Just show the --
        # If No Option ... No Option should be provided
        return
    }

    if ( curval ~ /^-/ ) {
        # Just show the -
        # If No Option ... No Option should be provided
        # TODO: Not found, then compressed argument
        return
    }

    if ( aobj_options_all_ready( obj, obj_prefix, lenv ) ) {
        # arguments
    } else {
        # show require options
    }
}
