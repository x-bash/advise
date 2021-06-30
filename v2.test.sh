
test123(){
    local fp="${1:-filepath}"; shift
    echo "-----"
    echo "Before awk: $*"
    local IFS=$'\002' # IFS="$(printf "\002")"

    s="$*"

    {
        cat "$fp"
        printf "\034%s\034" "$s"  # printf "\034${s}\034"
    } | awk -f v2.awk # 2>/dev/null

    echo -e "-----\n"
}

# test123 test-data2.json work ""

# time test123 test/3.json ""
# time test123 test/3.json repo --debug --repo abc --
# time test123 test/3.json repo --debug --repo abc 1 ""
# time test123 test/3.json repo --debug --repo abc 1 2 ""
# time test123 test/3.json repo --debug --repo abc ""
# time test123 test/3.json repo --debug -r3 3 ""

# time test123 test/3.json user create ""
# time test123 test/3.json repo --repo2 ""
time test123 test/3.json repo --repo2 "abc" ""
# time test123 test/3.json user create1 ""


