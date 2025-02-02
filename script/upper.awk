#!/usr/bin/awk -f
# Usage: cat num.list | upper.awk -v t=180
# t - target
match($NF, /B([0-9]+)$/, mArr) {
    #print mArr[1]
    a[NR]=mArr[1]
}

END{
    asort(a);
    d = a[NR] - t;
    d = d < 0 ? -d : d;
    res = a[NR];
    for (i=NR-1; i >= 1; i--) {
        d2 = a[i] - t;
        d2 = d2 < 0 ? -d2 : d2
        if (d2 < d) {
            d = d2;
            res = a[i];
        } else {
            break;
        }
    }
    print res
}
