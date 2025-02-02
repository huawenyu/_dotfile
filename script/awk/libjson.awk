
function parse_json(str, T, V,  slack,    c,s,n,a,A,b,B,C,U,W,i,j,k,u,v,w,root) {
    # use strings, numbers, booleans as separators
    # c = "[^\"\\\\[:cntrl:]]|\\\\[\"\\\\/bfnrt]|\\u[[:xdigit:]][[:xdigit:]][[:xdigit:]][[:xdigit:]]"
    c = "[^\"\\\\\001-\037]|\\\\[\"\\\\/bfnrt]|\\\\u[[:xdigit:]A-F][[:xdigit:]A-F][[:xdigit:]A-F][[:xdigit:]A-F]"
    s ="\"(" c ")*\""
    n = "-?(0|[1-9][[:digit:]]*)([.][[:digit:]]+)?([eE][+-]?[[:digit:]]+)?"

    root = gsplit(str, A, s "|" n "|true|false|null", T)
    assert(root > 0, "unexpected")

    # rejoin string using value indices
    str = ""
    for (i=1; i<root; i++)
        str = str A[i] i
    str = str A[root]

    # cleanup types and values
    for (i=1; i<root; i++) {
        if (T[i] ~ /^\"/) {
            b = split(substr(T[i], 2, length(T[i])-2), B, /\\/)
            if (b == 0) v = ""
            else {
                v = B[1]
                k = 0
                for (j=2; j <= b; j++) {
                    u = B[j]
                    if (u == "") {
                       if (++k % 2 == 1) v = v "\\"
                    } else {
                        w = substr(u, 1, 1)  
                        if (w == "b") v = v "\b" substr(u, 2)
                        else if (w == "f") v = v "\f" substr(u, 2)
                        else if (w == "n") v = v "\n" substr(u, 2)
                        else if (w == "r") v = v "\r" substr(u, 2)
                        else if (w == "t") v = v "\t" substr(u, 2)
                        else v = v u
                    }
                }
            }
            V[i] = v
            T[i] = "string"
        } else if (T[i] !~ /true|false|null/) {
            V[i] = T[i] + 0
            T[i] = "number"
        } else {
            V[i] = T[i]
        }
    }

    # sanitize string
    gsub(/[[:space:]]+/, "", str)
    if (str !~ /^[][{}[:digit:],:]+$/) {
        if (slack !~ /:/) return -1
        # handle ...unquoted:...
        a = gsplit(str, A, "[[:alpha:]_][[:alnum:]_]*:", B)
        str = ""
        for (i=1; i < a; i++) {
            T[root] = "string"
            V[root] = substr(B[i], 1, length(B[i])-1)
            str = str A[i] root ":"
            root++
        }
        str = str A[a]
        if (str !~ /^[][{}[:digit:],:]+$/) return -10
    }

    # atomic value?
    a = gsplit(str, A, "[[{]", B)
    if (A[1] != "") {
        if (a > 1) return -2
        else if (A[1] !~ /^[[:digit:]]+$/) return -3
        else return A[1]+0
    }

    # parse objects and arrays
    k = root
    C[0] = 0
    for (i=2; i<=a; i++) {
        T[k] = (B[i-1] ~ /\{/) ? "object" : "array"
        C[k] = C[0]
        C[0] = k
        u = gsplit(A[i], U, "[]}]", W)
        assert(u > 0, "unexpected")
        V[k++] = U[1]
        if (i < a && A[i] != "" && U[u] !~ /[,:]$/)
            return -4
        for (j=1; j<u; j++) {
            if (C[0] == 0 || T[C[0]] != ((W[j] == "}") ? "object" : "array")) return -5
            v = C[0]
            w = C[v]
            C[0] = w
            delete C[v]
            if (w) V[w] = V[w] v U[j+1]
        }
    }
    if (C[0] != 0) return -6

    # check contents
    for (i=root; i<k; i++) {
        if (T[i] == "object") {
            # check object contents
            b = split(V[i], B, /,/) 
            for (j=1; j <= b; j++) {
                if (B[j] !~ /^[[:digit:]]+:[[:digit:]]+$/)
                    return -7
                if (T[substr(B[j], 1, index(B[j],":")-1)] != "string")
                    return -8
            }
        } else if (V[i] != "") {
            # check array contents
            if (slack ~ /,/ && V[i] ~ /,$/)
                V[i] = substr(V[i], 1, length(V[i] -1))
            if (V[i] !~ /^[[:digit:]]+(,[[:digit:]]+)*$/)
                return -9
        }
    }
    return root
}


function query_json(str, X,  root, slack,   T, V, A, B, C, i, j, k) {
    k = parse_json(str, T, V, slack)
    if (k < 1) return k
    split(root, C, ".")
    j = 1
    while (j in C) {
        if (T[k] == "array")
            split(V[k], A, ",")
        else {
            split("", A)
            asplit(V[k], B, ":", ",")
            for (i in B)
                A[V[i]] = B[i]
        }
        if (C[j] in A) {
            k = A[C[j]]
            j++
        } else return -11 # can't find requested root
    }
    # split("", B)
    # split("", C)
    split("", X)
    B[k] = ""
    C[k] = 0
    C[0] = k
    do {
        C[0] = C[k]
        delete C[k]
        j = T[k]
        if (j == "array") {
            j = split(V[k], A, ",")
            k = B[k] ? B[k] SUBSEP : ""
            X[k 0] = j
            for (i=1; i<=j; i++) {
               # push A[i] to C, (B[k],i) to B 
                C[A[i]] = C[0]
                B[A[i]] = k i
                C[0] = A[i]
            }
        } else if (j == "object") {
            asplit(V[k], A, ":", ",")
            k = B[k] ? B[k] SUBSEP : ""
            for (i in A) {
                # push A[i] to C, (B[k],V[i]) to B 
                C[A[i]] = C[0]
                B[A[i]] = k V[i]
                C[0] = A[i]
            }
        } else if (j == "number") {
            X[B[k]] = V[k]
        } else if (j == "true") {
            X[B[k]] = 1
        } else if (j == "false") {
            X[B[k]] = 0
        } else if (j == "string") {
            X[B[k]] = V[k]
        } else {
            # null will satisfy ismissing()
            X[B[k]]
        }
        k = C[0]
    } while (k)
    return 0
}

