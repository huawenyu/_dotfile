#!/usr/bin/awk -f
# Usage: this -v inFile="srcFile"
# t - target
BEGIN {
    FS=":"
    print "!_TAG_FILE_ENCODING	utf-8	//"
    print "!_TAG_FILE_FORMAT	2	/extended format; --format=1 will not append ;\" to lines/"
    print "!_TAG_FILE_SORTED	0	/0=unsorted, 1=sorted, 2=foldcase/"
}

match($0,  /^([0-9]+:)#([ ]+)([a-zA-Z0-9_: ]+)/, groups) {
    lnumber = $1
    tagName = groups[3]
    gsub("\r", "", $2);
    tagStr = $2
    printf("%s\t%s\t/^%s/;\"\t%s\tline:%s\n", tagName, inFile, tagStr, "s", lnumber)
}


END{
}

