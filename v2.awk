
###############################
# Step 0 Utilities
###############################

BEGIN{
    false = 0;      true = 1

    RS = "\034"
    # KEYPATH_SEP = "\034"  # Not works with regex pattern [^\034]
    # KEYPATH_SEP = "\003"
    KEYPATH_SEP = ","
    # KEYPATH_SEP = "-"
    VAL_SEP = "\n"
    FUNC_SEP = "\004"
    FUNC_SEP_LEN = FUNC_SEP "len"
}

function str_wrap(s){
    return "\"" s "\""
}

function str_unwrap(s){
    # return "\"" s "\""
    return substr(s, 2, length(s)-2)
}

function str_startswith(src, prefix,    len){
    len = length(prefix)
    if (len == 0)   return true
    if (substr(src, 1, len) == prefix) {
        return true
    }
    return false
}

function pattern_wrap(s){
    return "\"[^\003]*:" s ":[^\003]*\""
    # return "\"[^-\034\035]*:" s ":[^-\034\035]*\""
    # return "\"[^-]*:" s ":[^-]*\""
}

function debug(msg){
    # if (dbg == false) return
	print "idx[" s_idx "]\tDEBUG:   " msg > "/dev/stderr"
}

function json_walk_panic(msg,       start){
    start = s_idx - 10
    if (start <= 0) start = 1
    print (msg " [index=" s_idx "]:\n-------------------\n" JSON_TOKENS[s_idx -2] "\n" JSON_TOKENS[s_idx -1] "\n" s "\n" JSON_TOKENS[s_idx + 1] "\n-------------------") > "/dev/stderr"
    exit 1
}

###############################
# Step 1 RULE
###############################
BEGIN {
    # RULE_ID_TO_NAME
    # RULE_ID_ARGNUM
    # RULE_ID_M
    # RULE_ID_R
    # RULE_ID_R_LIST
    # RULE_ID_CANDIDATES
}

function rule_add_key( keypath, key,
    num, tmp ) {

    # key = str_unwrap( key )  # Notice: simple unwrap

    
    keyarrlen = split(key, keyarr, "|")
    first = keyarr[2]

    # debug( "rule_add_key\t" keypath "\t-- " key "\t-- " keyid "\t-- " first )

    KEYPREFIX = keypath KEYPATH_SEP
    keyid = KEYPREFIX key


    if (first ~ /-/) {
        # options
        last = keyarr[keyarrlen]
        if ( match(last, /^[0-9]+$/) ) {
            keyid = substr(keyid, 1, length(keyid)-RLENGTH)
            num = substr(keyid, length(keyid)-RLENGTH+1)
            tmp = RULE_ID_ARGNUM[ keyid ] || 0
            if (tmp < num) {
                RULE_ID_ARGNUM[ keyid ] = num
            }
            keyarrlen = keyarrlen - 1
        } else {
            RULE_ID_ARGNUM[ keyid ] = 1
            # Notice: What if value is null ?
        }
        # debug( "rule_add_key\t" keypath "\t-- " keyid "\t-- " RULE_ID_ARGNUM[ keyid ] )

        last = keyarr[keyarrlen]
        if (last ~ /^[rm|mr|r|m]$/) {
            keyarrlen = keyarrlen - 1
            if (last ~ "m")     RULE_ID_M[ keyid ] = true
            if (last ~ "r")     {
                RULE_ID_R[ keyid ] = true
                RULE_ID_R_LIST = RULE_ID_R_LIST "\n" keyid
            }
        }
    } else {
        RULE_ID_ARGNUM[ keyid ] = -1    # Means it is subcmd
    }

    # tmp = ""
    for (i=1; i<=keyarrlen; ++i) {
        e = keyarr[i]
        RULE_ALIAS_TO_ID[ KEYPREFIX e ] = keyid
        # tmp = tmp " " e
    }
    # RULE_ID_CANDIDATES[ keypath ] = RULE_ID_CANDIDATES[ keypath ] tmp
    RULE_ID_CANDIDATES[ keypath ] = RULE_ID_CANDIDATES[ keypath ] "\n" keyid
}

function rule_add_list_val( keypath, val,
    num, tmp ) {

    val = str_unwrap( val )     # Notice: simple unwrap

    if (match(keypath, KEYPATH_SEP "[0-9]+$") ) {
        keypath = substr( keypath, 1, RSTART-1 )
    }

    # debug("rule_add_list_val\t" keypath "\t" val)
    
    RULE_ID_CANDIDATES[ keypath ] = RULE_ID_CANDIDATES[ keypath ] "\n" val   # unwrap val
}

function rule_add_dict_val( keypath, val,
    num, tmp ) {

    if (val == "null") {
        RULE_ID_ARGNUM[ keypath ] = 0
        # No candidates
    } else {
        RULE_ID_CANDIDATES[ keypath ] = "#> " str_unwrap( val )
    }    
}

###############################
# Step 2 JSON: utilities
###############################
function json_walk_dict(keypath, indent,    
    data, nth, cur_keypath, cur_indent, key, value){

    if (s != "{") {
        # debug("json_walk_dict() fails" )
        return false
    }
    
    nth = -1
    s = JSON_TOKENS[++s_idx]

    data = "{"

    while (1) {
        nth ++
        if (s == "}") {
            s = JSON_TOKENS[++s_idx];  break
        }

        # if (s == ":") { json_walk_panic("json_walk_dict() Expect A value NOT :") }
        key = str_unwrap( s )
        rule_add_key(keypath, key)
        cur_keypath = keypath KEYPATH_SEP key


        data = data VAL_SEP key

        s = JSON_TOKENS[++s_idx]
        if (s != ":") json_walk_panic("json_walk_dict() Expect :")
        
        s = JSON_TOKENS[++s_idx]            # Value
        json_walk_value(cur_keypath, cur_indent, "dict")

        if (s == ",") s = JSON_TOKENS[++s_idx]
    }

    return true
}

function json_walk_array(keypath, indent,
    data, nth, cur_keypath, cur_indent, cur_item, comma, count){
    # debug("json_walk_array start() ")
    if (s != "[")   return false

    nth = -1
    s = JSON_TOKENS[++s_idx]

    data="["
    
    while (1) {
        nth++;
        if (s == "]") {
            s = JSON_TOKENS[++s_idx];   break
        }

        cur_keypath = keypath KEYPATH_SEP nth

        # if (s == ",")  json_walk_panic("json_walk_array() Expect a value but get " s)
        json_walk_value(cur_keypath, cur_indent, "list")
        # debug("json_walk_array() value: " result)
        
        data = data VAL_SEP result

        if (s == ",")   s = JSON_TOKENS[++s_idx]
    }

    return true
}

function json_walk_value(keypath, indent, struct_type){
    if (json_walk_dict(keypath, indent) == true) {
        return true
    }

    if (json_walk_array(keypath, indent) == true) {
        return true
    }

    result = s

    if (struct_type == "dict") {
        rule_add_dict_val(keypath, s)
    } else if (struct_type == "list") {
        rule_add_list_val(keypath, s)
    }

    s = JSON_TOKENS[++s_idx]
    return true
}

function _json_walk(    final, idx, nth){
    if (s == "")  s = JSON_TOKENS[++s_idx]

    # nth = 0
    # while (s_idx <= s_len) {
    #     if (json_walk_value(nth++, "") == false) {
    #        json_walk_panic("json_walk() Expect a value")
    #     }
    # }

    json_walk_dict(".", "")
}

# global variable: text, s, s_idx, s_len
function json_walk(text,   final, b_s, b_s_idx, b_s_len){
    b_s = s;    b_s_idx = s_idx;    b_s_len = s_len;

    RULES_RAW["."]=text
    
    result = "";
    gsub(/^\357\273\277|^\377\376|^\376\377|"[^"\\\001-\037]*((\\[^u\001-\037]|\\u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])[^"\\\001-\037]*)*"|-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?|null|false|true|[ \t\n\r]+|./, "\n&", text)
    # gsub(/^\357\273\277|^\377\376|^\376\377|"[^"\\\000-\037]*((\\[^u\000-\037]|\\u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])[^"\\\000-\037]*)*"|-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?|null|false|true|[ \t\n\r]+|./, "\n&", text)
	gsub("\n" "[ \t\n\r]+", "\n", text)

    s_len = split(text, JSON_TOKENS, /\n/)
    s = JSON_TOKENS[s_idx];     s_idx = 1;

    _json_walk()

    s = b_s;    s_idx = b_s_idx;    s_len = b_s_len;
}

###############################
# Step 3 main
###############################

NR==1{
    json_walk($0)
}

NR==2{
    argstr = $0

    gsub("\n", "\001", argstr)
    parsed_arglen = split(argstr, parsed_argarr, "\002")

    ruleregex = ""

    arglen=0
    rest_argv_len = 0

    current_keypath = "."

    for (i=1; i<=parsed_arglen; ++i) {
        arg = parsed_argarr[i]
        gsub("\001", "\n", arg)
        parsed_argarr[i] = arg
    }

    for (i=1; i<parsed_arglen; ++i) {
        arg = parsed_argarr[i]

        argval = ""
        if (arg ~ /^-/) {
            if (match(arg, /^--?[A-Za-z0-9_+-]+=/)){
                argval = substr(arg, RLENGTH+1)
                arg = substr(arg, 1, RLENGTH)
            }

            cur_option_alias = arg
            option_id = RULE_ALIAS_TO_ID[ current_keypath KEYPATH_SEP cur_option_alias ]

            if (option_id != "") {
                used_option_add( option_id )
            } else {
                is_compact_argument = 0
                if (arg ~ /^-[^-]/) {
                    # like tar: -xvf => -x -v -f 
                    _arg_tmp_arrlen = split(arg, _arg_tmp_arr, "")
                    for (j=2; j<=_arg_tmp_arrlen; ++j) {
                        cur_option_alias = "-" _arg_tmp_arr[j]
                        option_id = RULE_ALIAS_TO_ID[ keypath KEYPATH_SEP cur_option_alias ]
                        if (option_id == "") {
                            is_compact_argument = -1
                            break
                        }
                    }

                    if (is_compact_argument == 0) {
                        for (j=2; j<=_arg_tmp_arrlen; ++j) {
                            argarr[++arglen] = cur_option_alias
                            used_option_add( option_id )
                        }
                        arg = argarr[arglen]
                        is_compact_argument = 1
                    }
                }

                if (is_compact_argument != 1) {
                    # Must be positional argument
                    cur_option_alias = ""
                    for (j=i; j<=parsed_arglen; ++j) {
                        rest_argv[++rest_argv_len] = parsed_argarr[j]
                    }
                }
            }

            # handle optarg value
            if (argval != "") {
                cur_option_alias = ""
            } else {
                cur_option_id = RULE_ALIAS_TO_ID[ current_keypath KEYPATH_SEP cur_option_alias ]
                optarg_num = RULE_ID_ARGNUM[ cur_option_id ]
                for (cur_optarg_index=1; cur_optarg_index<=optarg_num; ++cur_optarg_index) {
                    if (i+1 < parsed_arglen) {
                        argarr[++arglen] = parsed_argarr[++i]
                    }
                }

                if (cur_optarg_index > optarg_num) {
                    cur_option_alias = ""
                    cur_optarg_index = 0
                }
            }
        } else {
            cur_option_alias = ""
            option_id = RULE_ALIAS_TO_ID[ current_keypath KEYPATH_SEP arg ]

            # debug("2\t" option_id "\t|" current_keypath KEYPATH_SEP arg)
            
            if (option_id == "") {
                # Must be positional argument
                for (j=i; j<=parsed_arglen; ++j) {
                    rest_argv[++rest_argv_len] = parsed_argarr[j]
                }
                break
            }

            # Must be subcommand argument
            current_keypath = option_id
            used_option_clear( )
        }
    }

    cur = parsed_argarr[parsed_arglen]

    if (cur == "\177") {    # ascii code 127 0x7F 0177 ==> DEL
        cur = ""
    }

    if (rest_argv_len > 0) {
        # debug("show_positional_candidates:\t" rest_argv_len )
        show_positional_candidates( current_keypath, cur, rest_argv_len)
    } else if (cur_option_alias != "") {
        option_id = RULE_ALIAS_TO_ID[ current_keypath KEYPATH_SEP cur_option_alias ]

        candidates = RULE_ID_CANDIDATES[ option_id "|" last_optarg_index ]
        if (candidates != "") {
            candidates = RULE_ID_CANDIDATES[ option_id ]
        }
        # debug("print_list_candidate")
        print_list_candidate(candidates)
    } else {
        # debug("show_candidates")
        # list subcmd or options or postional arguments
        show_candidates( current_keypath, cur )
    }

}

BEGIN{
    used_option_list = ""
}

function used_option_add(option_id){
    # debug("used_option_add:\t" option_id)
    used_option_list = used_option_list "\n" option_id
}

function used_option_clear(){
    used_option_list = ""
}

function is_all_required_provided(      arr, arrlen, i, elem){
    arrlen = split(RULE_ID_R_LIST, arr, "\n")
    for (i=2; i<=arrlen; ++i) {
        elem = arr[i]
        if (elem != 100) {
            return false
        }
    }
    return true
}

function print_list_candidate(candidates,
    can, i, can_arr_len, can_arr ){

    if ( str_startswith( candidates, "#> " ) ) {
        # print command line
        print candidates
    }

    can_arr_len = split( candidates, can_arr, "\n" )
    for (i=2; i<=can_arr_len; ++i) {
        can = can_arr[i]
        if (str_startswith( can, cur )) print can
    }
}

# That is most complicated.
function show_positional_candidates(final_keypath, cur, rest_argv_len,
    candidates, all_required){

    all_required = is_all_required_provided()
    if ( all_required == false ) return 

    candidates = RULE_ID_CANDIDATES[ final_keypath KEYPATH_SEP "#" rest_argv_len ]
    if (candidates != "") {
        print_list_candidate( candidates )
        return
    }

    candidates = RULE_ID_CANDIDATES[ final_keypath KEYPATH_SEP "#n" ]
    if (candidates != "") {
        print_list_candidate( candidates )
        return
    }   
}

# That is most complicated.
function show_candidates(final_keypath, cur, 
    car_arr, can_arr_len,
    num, used_option_set){

    can_arr_len = split( used_option_list, car_arr, "\n" )
    for (i=2; i<=can_arr_len; ++i) {
        used_option_set[ car_arr[i] ] = true
    }


    candidates = RULE_ID_CANDIDATES[ final_keypath ]

    can_arr_len = split( candidates, car_arr, "\n")

    for (i=2; i<=can_arr_len; ++i) {
        can = car_arr[i]
        if (used_option_set[ can ] == true) continue
        if ( (can == "#n") || (can ~ /^#[0-9]+$/) )  continue
        print_candidate_with_optionid( can, cur )
        used_option_set[ can ] = true
    }

    show_positional_candidates( final_keypath, cur, 1 )
}

function print_candidate_with_optionid( option_id, cur,
    car_arr, can_arr_len, can, i){

    if ( (length(cur)>0) && (cur !~ /^-/) ) return

    can_arr_len = split( option_id, can_arr, KEYPATH_SEP )
    option_id = can_arr[ can_arr_len ]

    can_arr_len = split( option_id, can_arr, "|" )
    for (i=1; i<=can_arr_len; ++i) {
        can = can_arr[i]
        if (str_startswith( can, cur )) {
            print can
        }
    }
}
