test123(){
    local fp="${1:-filepath}"; shift
    echo "-----"
    echo "Before awk: $*"
    local IFS
    IFS="$(printf "\002")"
#     awk -f v1.awk <<A
# $(cat "$fp")$(printf "\034")${COMP_CWORD[*]}"
# A

    s="$*"

    awk -f v1.awk <<A
$(cat "$fp")$(printf "\034")${s}$(printf "\034")
A

    echo -e "-----\n"
}

# test123 test-data2.json work ""

test123 test-data2.json work --host=abc ""
# test123 test-data2.json work --host=abc -sv abc ""

# test123 test-data2.json work --host=abc -version -v repo create --has_wiki a
# test123 test-data2.json work --host=abc -v repo create --has_wiki
# test123 test-data2.json work --host=abc -v ""

