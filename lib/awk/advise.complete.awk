
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

    # Show the argument
    # 1. If all ready, then just show the argument
    # 2. If not ready, show the option necessary


    # # If not require ready...
    # advise_complete_option_name( genv_table, lenv_table, obj, obj_prefix )
    # # TODO: Check upper level options provided
    # if ( aobj_options_all_ready( obj, obj_prefix, lenv ) ) {
    #     advise_complete_argument_value( genv_table, lenv_table, obj, obj_prefix, 1 )
    #     return
    # }

}
