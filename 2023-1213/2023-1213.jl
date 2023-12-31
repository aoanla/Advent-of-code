#the secret here is just to encode to bitmaps (row and col sets)
# then iterate through xoring the row [or col] until either: we get 0 [in which case we had a perfectly repeating sequence so mirror is at pos/2]
#                                           or, we run out of rows - in which case we check which previous value we match (at l)
#                                                                      (which is the "start" of the mirrored section, so mirror is at (tot-l)/2]


#parsing
#sets are delimited by blank lines

# Part 2 - since we're already xoring things, we can use the xor maps to find cases where the xor has value 1 not 0 (which have "one smudge")

d = read("input");
#b(x) = UInt8(x);
nl = UInt8('\n');
hash = UInt8('#');


function get_puzzle(d, offset)
    linelength = findnext(==(nl), d, offset) - offset ;  #remove newline itself (actual line length with newline is end - start + 1)
    colbits = zeros(UInt64, linelength); #one col per elem,
    rowbits = Vector{UInt64}(); #empty to start with  
    end_of_line = offset + linelength;
    cbit = 0x0000000000000001;
    while offset < length(d) && d[offset] != nl #the blank line
@views  row = d[offset:end_of_line] 
        rowbits_l = UInt64(0) 
        #  rowbits = row .== hash   as UInt64
        rbit = 0x0000000000000001;
        for r in 1:linelength
            if row[r] == hash 
                colbits[r] |= cbit;    #somehow colbits is missing elements [the furthest "right"/highest order ones on the first item at least]
                rowbits_l |= rbit;
            end
            rbit <<= 1; 
        end
        push!(rowbits, rowbits_l);
        offset = end_of_line + 1; #newline again
        end_of_line = offset + linelength ;
        cbit <<= 1;
    end

    return (offset+1, linelength, rowbits, colbits); #+1 on offset to remove the *next* newline?
end

function validate(seq, i, fudge) #i is the left-of-the mirror-line, fudge is a fudge factor for number of misses (for part 2)
    #println("$((i>1) && ((i+2) < length(seq)))");
    test = count_ones(seq[i] ⊻ seq[i+1]) <= fudge;
    #println("Validation $test on $i $(i+1)")
    if ((i>1) && ((i+2) < length(seq)))
        test &= count_ones(seq[i-1] ⊻ seq[i+2])<=fudge;
    end
    test #((i>1) && ((i+2) < length(seq))) ? test && count_ones(seq[i-1] ⊻ seq[i+2])<=fudge : test
end

function find_mirror_sequence(seq, fudge)
    accum = seq[1] ; 
    #println("Starting scan $(bitstring(accum))");
    memo = similar(seq);
    memo[1] = accum;
    for i in 2:length(seq)
        accum ⊻= seq[i] ;
        #println("$(bitstring(accum))      <---- $(bitstring(seq[i]))");
        count_ones(accum) == fudge && validate(seq, i ÷ 2, fudge) && return i ÷ 2 ; #found sequence starting on the left
        memo[i] = accum ; #memoise for search from right
    end
    #and from the right (not doing memoisation any more)
    accum = seq[end]
    #println("Length = $(length(seq))");
    for i in length(seq)-1:-1:1
        #println("$i")
        accum ⊻= seq[i] ;
        #println("$(bitstring(accum))      <---- $(bitstring(seq[i]))");
        #print
        count_ones(accum) == fudge && validate(seq, (length(seq) + i) ÷ 2, fudge) && return (length(seq) + i) ÷ 2  ; #found sequence starting on the left
        #memo[i] = accum ; #memoise for search from right
    end
    return 0; #no match
end

find_any_mirror(sequences) = maximum(find_mirror_sequence.(sequences));

function solve(d)
    next = 1;  
    h_accum = 0;
    h_accum2 = 0;
    v_accum = 0;
    v_accum2 = 0;
    while next <= length(d)
        println("Solving puzzle at offset: $next")
        oldnext = next;
        (next, linelength_, rowbits, colbits) = get_puzzle(d, next);
    #    println("Vertical scan:")
        v = find_mirror_sequence(rowbits, 0);
        v2 = find_mirror_sequence(rowbits, 1); #part 2
    #    println("Horizontal scan")
        h =  find_mirror_sequence(colbits, 0); #
        h2 = find_mirror_sequence(colbits, 1); #part 2
            #remove the "pt1 solution" from the "pt2 set"
        h2 =  h == h2 ? 0 : h2;
        v2 = v == v2 ? 0 : v2;
        if (h != 0) & (v != 0)
            println("Error: two mirrors @ \n$(String(d[oldnext:next]))")
        end
        if (h == h2) & (v == v2)
            println("Error: found same values for part 1 and 2 @ \n$(String(d[oldnext:next]))");
        end
        if (h2 != 0) & (v2 != 0)
            println("Error: two mirrors pt 2 @ \n$(String(d[oldnext:next]))")
        end
        if (h2 == 0) & (v2 == 0)
            println("Error: no alternate soln found @ \n$(String(d[oldnext:next]))");
        end
        if (h == 0) & (v == 0)
            println("Error: no soln found @ \n$(String(d[oldnext:next]))");
        end


        h_accum += h;
        v_accum += v;
        h_accum2 += h2;
        v_accum2 += v2;
        println("$v, $h");
        println("$v2, $h2");
    end

    (v_accum * 100 +  h_accum, v_accum2*100 + h_accum2)

end

println("$(solve(d))");
