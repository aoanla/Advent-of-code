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

function validate(seq, i) #i is the left-of-the mirror-line
    test = seq[i]==seq[i+1];
    return (i>1) && (i+2) <length(seq) ? test && seq[i-1] == seq[i+2] : test
end

function find_mirror_sequence(seq)
    accum = UInt64(0) ; 
    #println("Starting scan $(bitstring(accum))");
    memo = similar(seq);
    for i in 1:length(seq)
        accum ⊻= seq[i] ;
    #    println("$(bitstring(accum))      <---- $(bitstring(seq[i]))");
        accum == 0 && validate(seq, i ÷ 2) && return i ÷ 2 ; #found sequence starting on the left
        memo[i] = accum ; #memoise for search from right
    end
    #if here, subseq starts "into" the seq so find the memoised copy matching our final value to find the start
    #println("Scanning memo left:")
    for i in 1:length(memo)-2  #don't scan the last item as it obviously matches!
    #    println("$(bitstring(memo[i]))  -->  $(bitstring(memo[i] ⊻ accum))    <--- $(bitstring(accum))");        
        memo[i] == accum && validate(seq,  (length(memo)+i+1) ÷ 2 ) && begin 
    #    println("Match at $i !")
        #match at i (which is the start) + (l - i +1 ) remaining tiles which add 1/2 -> l/2 + i/2 + 0.5
        return (length(memo) + i + 1) ÷ 2 ; #+1 because we need to include the start cell itself
        end
    end
    return 0; #no match
end

find_any_mirror(sequences) = maximum(find_mirror_sequence.(sequences));

function solve(d)
    next = 1;  
    h_accum = 0;
    v_accum = 0;
    while next <= length(d)
    #    println("Solving puzzle at offset: $next")
        oldnext = next;
        (next, linelength_, rowbits, colbits) = get_puzzle(d, next);
    #    println("Vertical scan:")
        v = find_mirror_sequence(rowbits);
    #    println("Horizontal scan")
        h =  #=(v > 0) ? 0 : =# find_mirror_sequence(colbits); #no need to test v if we already found an h [assuming only 1 mirror per puzzle]
        if (h != 0) & (v != 0)
            println("Error: two mirrors @ \n$(String(d[oldnext:next]))")
        end
        h_accum += h;
        v_accum += v;
        println("$v, $h")
    end

    (v_accum * 100 +  h_accum)
end

println("$(solve(d))");
