BEGIN{
    true=1; false=0
    opt="{"
    IS_COMMANDS=false
}
function get_json(text,    i,arr,arrcom){
    sub(/^[ \t]+/, "",text)
    if (text ~ /^-/){
        split(text,arr," ")
        opt=opt "\n    \""
        for (i in arr){
            gsub(/[[:blank:]]*/,"",arr[i])
            if (arr[i] ~ /^-/){
                gsub(/,/,"|",arr[i])
                opt=opt arr[i]
            }else{
                break
            }
        }
        opt=opt "\": null,"
        return
    }
    if(text ~ "Commands:"){
        if (IS_COMMANDS == false){
            IS_COMMANDS=true
            return
        }
    }
    if (IS_COMMANDS == true){
        if(text ~ /^[ \t\r]*$/){
            IS_COMMANDS=false
            return
        }
        split(text,arrcom," ")
        opt=opt "\n    \"" arrcom[1] "\": null,"
        return
    }
}
{
    text=$0
    get_json(text)
}
END{
    opt=substr(opt,1,length(opt)-1)
    opt=opt "\n}"
    print opt
    text=""
    IS_COMMANDS=false
    opt=""
}