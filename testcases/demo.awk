#!/bin/awk -f
BEGIN{
    print "===BEGIN==="
}
{
    str = $0
    gsub(/^\357\273\277|^\377\376|^\376\377/, "\n&", str)
    print str
}
END{
    print "===ENG==="
}