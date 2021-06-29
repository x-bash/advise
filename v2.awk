BEGIN{
    false = 0;      true = 1

    RS = "\034"
    # KEYPATH_SEP = "\034"  # Not works with regex pattern [^\034]
    KEYPATH_SEP = "\003"
    # KEYPATH_SEP = "-"
    VAL_SEP = "\n"
    FUNC_SEP = "\004"
    FUNC_SEP_LEN = FUNC_SEP "len"
}

function str_wrap(s){
    return "\"" s "\""
}

function pattern_wrap(s){
    return "\"[^\003]*:" s ":[^\003]*\""
    # return "\"[^-\034\035]*:" s ":[^-\034\035]*\""
    # return "\"[^-]*:" s ":[^-]*\""
}

function debug(msg){
    if (dbg == false) return
	print "idx[" s_idx "]  DEBUG:" msg > "/dev/stderr"
}


function json_walk_panic(msg,       start){
    start = s_idx - 10
    if (start <= 0) start = 1
    print (msg " [index=" s_idx "]:\n-------------------\n" JSON_TOKENS[s_idx -2] "\n" JSON_TOKENS[s_idx -1] "\n" s "\n" JSON_TOKENS[s_idx + 1] "\n-------------------") > "/dev/stderr"
    exit 1
}

BEGIN {
    RULE_ID_TO_NAME
    RULE_NAME_ARGNUM
    RULE_ID_M
    RULE_ID_CANDIDATES
}

function rule_add_key( keypath, key,
    num, tmp ) {

    key = substr(key, 2, length(2))  # Notice: simple unwrap
    keyarrlen = split(key, keyarr, "|")
    first = keyarr[1]

    KEYPREFIX = keypath KEYPATH
    keyid = KEYPREFIX key
    

    if (first ~ /-/) {
        # options
        last = keyarr[keyarrlen]
        if match(last, /^\|[0-9]+$/) {
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

        last = keyarr[keyarrlen]
        if (last == "m") {
            RULE_ID_M[ keyid ] = true
            keyarrlen = keyarrlen - 1
        }
    } else {
        RULE_ID_ARGNUM[ keyid ] = -1    # Means it is subcmd
    }

    tmp = ""
    for (i=1; i<=keyarrlen; ++i) {
        e = keyarr[i]
        RULE_NAME_TO_ID[ KEYPREFIX e ] = keyid
        tmp = tmp " " e
    }
    RULE_ID_CANDIDATES[ keypath ] = RULE_ID_CANDIDATES[ keypath ] tmp
}

function rule_add_list_val( keypath, val,
    num, tmp ) {

    val = substr(val, 2, length(val)-2)     # Notice: simple unwrap
    RULE_ID_CANDIDATES[ keypath ] = RULE_ID_CANDIDATES[ keypath ] " " val   # unwrap val
}

function rule_add_dict_val( keypath, val,
    num, tmp ) {

    if (val == "null") {
        RULE_ID_ARGNUM[ keypath ] = 0
        # No candidates
    } else {
        RULE_ID_CANDIDATES[ keypath ] = "#!> " val
    }    
}

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
        key = s
        cur_keypath = keypath KEYPATH_SEP key

        rule_add_key(cur_keypath, key)

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

NR==1{
    json_walk($0)
}

NR==2{
    argstr = $0

    gsub("\n", "\001", argstr)
    parsed_arglen = split(argstr, parsed_argarr, "\002")

    # prev = parsed_argarr[parsed_arglen-1]
    # cur = parsed_argarr[parsed_arglen]
    
    ruleregex = ""

    arglen=0
    used_arg = ""
    rest_argv_len = 0
    # rest_argv

    final_keypath = "."

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

            cur_option = arg
            option_id = RULE_NAME_TO_ID[ keypath KEYPATH_SEP cur_option ]
            if (arg ~ /^--/) {
                argarr[++arglen] = arg
                used_arg_add(final_keypath, arg)
            } else {
                if (length(arg) == 2) {
                    argarr[++arglen] = arg
                    used_arg_add(final_keypath, arg)
                } else if (option_id != "") {
                    # For some command like java, "java -version"
                    argarr[++arglen] = arg
                    used_arg_add(final_keypath, arg)
                } else {
                    # like tar: -xvf => -x -v -f 
                    _arg_tmp_arrlen = split(arg, _arg_tmp_arr, "")
                    for (j=2; j<=_arg_tmp_arrlen; ++j) {
                        cur_option = "-" _arg_tmp_arr[j]
                        argarr[++arglen] = cur_option
                        used_arg_add(final_keypath, cur_option)
                    }
                    arg = argarr[arglen]
                }
            }

            if (argval != "") {
                argarr[++arglen] = argval
                cur_option = ""
            } else {
                keypath = rule_search(final_keypath KEYPATH_SEP pattern_wrap(arg))
                rule = rule_get(keypath)
                # print "--- " final_keypath KEYPATH_SEP pattern_wrap(arg)
                if (rule != "null") {
                    # TODO: Now problem is: How many arguments
                    if (i+1 < parsed_arglen) {
                        argarr[++arglen] = parsed_argarr[++i]
                    }
                } else {
                    cur_option = ""
                }
            } 
            
        } else {
            cur_option = ""

            argarr[++arglen] = arg

            option_id = RULE_NAME_TO_ID[ keypath KEYPATH_SEP arg ]
            
            if (option_id == "") {
                # Must be positional argument
                for (j=i; j<=parsed_arglen; ++j) {
                    rest_argv[++rest_argv_len] = parsed_argarr[j]
                }
                break
            }

            # Must be subcommand argument
            final_keypath = option_id
            used_arg = ""
        }
        
    }

    # print "aaa\t" parsed_argarr[parsed_arglen-1]
    # print "bbb\t" argarr[arglen-1]
    # print "bbb\t" argarr[arglen]
    argarr[++arglen] = parsed_argarr[parsed_arglen]


    cur = argarr[arglen]

    if (cur == "\177") {    # ascii code 127 0x7F 0177 ==> DEL
        cur = ""
    }

    if (rest_argv_len > 0) {
        # print "used:\t" used_arg
        # print "keypath:\t" final_keypath
        # print "position argument:\t" rest_argv_len

        print_positional_candidates(final_keypath, rest_argv_len)

    } else {

        # cur_option
        # last_optarg_index
        prev = argarr[arglen-1]
        
        # print "used:\t" used_arg
        # print "keypath:\t" final_keypath
        # print "prev:\t" prev
        # print "cur:\t" cur


        if (cur_option != "") {
            option_id = RULE_NAME_TO_ID[ final_keypath KEYPATH_SEP cur_option ] "|" last_optarg_index
            # RULE_ID_CANDIDATES[ option_id ]
            show_candidates( option_id, cur )
        } else {
            # list subcmd or options or postional arguments
            show_candidates( final_keypath, cur )
        }
    }

}

function used_arg_add(keypath, named_arg,
    kp, arr, arrlen, i) {
    kp = rule_search(keypath KEYPATH_SEP pattern_wrap(named_arg))
    arrlen = split(substr(kp, length(keypath)), arr, ":")
    for (i=2; i<arrlen; ++i) {
        used_arg = used_arg " " arr[i] " "
    }
}

function print_positional_candidates(final_keypath, nth,
    kp){

    kp = rule_search(final_keypath KEYPATH_SEP "\"#" nth "\"")
    if (kp != "null") {
        
        if (kp == "") {
            kp = rule_search(final_keypath KEYPATH_SEP "\"#n\"") 
        }


        # print "1111 " rule_get(kp) >"/dev/stderr"
        print_named_param_candidates(rule_get(kp), cur)
    }
}


function print_named_param_candidates(rule, cur,
    es, esl, e, i, data){

    # print "print_named_param_candidates"

    # Must be a list

    if (rule !~ /^\[/) {
        cmd = substr(rule, 4, length(rule)-4)
        # print cmd > "/dev/stderr"
        system(cmd)

        esl = split(data, es, /[\n\ \t]/)
        for (i=1; i<=esl; ++i) {
            if (cur == "") {
                print es[i]
            } else if (index(es[i], cur) == 1) {
                print es[i]
            }
        }
    } else {
        gsub(/\"/, "", rule) #"
        esl = split(rule, es, VAL_SEP)
        for (i=2; i<=esl; ++i) {
            e = es[i]

            if (cur == "") {
                print e
            } else if (index(e, cur) == 1) {
                print e
            }
        }
    }
}

function print_candidates(final_keypath, cur,
    arr, arr_len, e, es, esl, ese, i, j, output_position){

    # print "print_candidates\t" final_keypath "\t|" cur "|"

    if (cur == "") {
        sw = 0
    } else {
        sw = 1
    }

    keypath = rule_search(final_keypath)
    rule = rule_get(keypath FUNC_SEP_KEY)

    # print "print_candidates\t" final_keypath "\t|" rule "|"


    output_position = 0
    

    arr_len = split(rule, arr, VAL_SEP)
    for (i=2; i<=arr_len; ++i) {
        e = arr[i]
        esl = split(e, es, ":")
        for (j=2; j<esl; ++j) {
            ese = es[j]

            # print ese
            if (ese !~ /^[#-]/) {
                output_position = 1
            }

            if (sw == 0) {  
                if (ese !~ /-/){                  
                    print ese
                }
            } else {  
                if (index(ese, cur) == 1) {
                    if (index(used_arg, " " ese " ") == 0) {
                        print ese
                    }
                }
            }
        }
    }



    if (output_position == 0) {
        print_positional_candidates(final_keypath, 1)
    }

}

