#the secret here is just to encode to bitmaps (row and col sets)
# then iterate through xoring the row [or col] until either: we get 0 [in which case we had a perfectly repeating sequence so mirror is at pos/2]
#                                           or, we run out of rows - in which case we check which previous value we match (at l)
#                                                                      (which is the "start" of the mirrored section, so mirror is at (tot-l)/2]


#parsing
#sets are delimited by blank lines

d = read("input");
b(x) = UInt8(x);
nl = b('\n');
hash = b('#');

function get_puzzle(d, offset)
    linelength = findnext(==(nl), d, offset) - offset -1 ;  #remove newline itself
    colbits = zeros(UInt64, linelength); #one col per elem,
    rowbits = Vector{UInt64}(); #empty to start with  
    newoffset = offset + linelength;
    cbit = 0x1;
    rbit = 0x1;
    while d[offset] != nl #the blank line
@views  row = d[offset:newoffset] 
        rowbits_l = UInt64(0x0) 
        #  rowbits = row .== hash   as UInt64
        for r in 1:linelength
            if row[r] == hash 
                colbits[r] |= cbit;
                rowbits_l |= rbit;
            end
            rbit <<= 1; 
        end
        push!(rowbits, rowbits_l);
        offset = newoffset + 1; #newline again
        newoffset = offset + linelength;
        cbit <<= 1;
    end

    return (newoffset, linelength, rowbits, colbits);
end


function find_mirror_sequence(seq)
    accum = 0::UInt64 ; 
    memo = similar(seq);
    for i in 1:length(seq)
        accum \xor= seq[i] ;
        accum == 0 && return i \div 2 ; #found sequence starting on the left
        memo[i] = accum ; #memoise for search from right
    end
    #if here, subseq starts "into" the seq so find the memoised copy matching our final value to find the start
    for i in 1:length(memo)
        memo[i] == accum && return (length(memo) - i) \div 2 ; #might be off by one
    end
end