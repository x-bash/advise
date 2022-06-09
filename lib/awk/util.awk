# Section: utils
BEGIN{
    false = 0
    true = 1

    EXIT_CODE = 0
}

function panic(msg){
    print "[PANIC]: " msg >"/dev/stderr"
    EXIT_CODE = 1
    exit(1)
}

function assert(condition, msg){
    if (condition == 0) {
        panic(msg)
    }
}

## EndSection