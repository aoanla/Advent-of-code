
#part 1

ex_cap(match) = match.captures[1]
ex_off(match) = match.offset

function check_line(p, symbols) #where p is a potential match
    pstart = p.offsets[1] - 1 #because we could be diagonally across from input
    pend = p.offsets[1] + length(p.captures[1])    
    #sindex = 1
    for s in symbols    
        if s < pstart
            continue;
            #sindex += 1 #move symbol match window so we don't waste time
        end
        if s > pend
            return false
        end
        #if we're here then it must be in the range!
        return true
    end
    false
end       



open("input") do f
    linevals = 0    
    old_symbols = []
    old_potentials = []
    prev_matches = []
    for line in eachline(f) 
        
        currmatches = ex_cap.(eachmatch(r"[^.0-9]([0-9]+)", line)) ∪ ex_cap.(eachmatch(r"([0-9]+)[^.0-9]", line))
        potentials = collect(eachmatch(r"(?:[.]|^)([0-9]+)(?=[.]|$)", line))  #the numbers in this line which don't start/end with a symbol on the same line

        accept = filter(p -> check_line(p, old_symbols), potentials)
                   
        union!(currmatches, ex_cap.(accept) )
        setdiff!(potentials, accept)
            
        symbols = ex_off.(eachmatch(r"[^.0-9]", line)) #the locations of the symbols on this line
        accept = filter(p -> check_line(p, symbols), old_potentials)

        union!(prev_matches, ex_cap.(accept) )

        

        linevals += sum(parse.(UInt, prev_matches))
        old_potentials = potentials
        old_symbols = symbols
        prev_matches = currmatches

        #println("$prev_matches")

    end
    linevals += sum(parse.(UInt, prev_matches)) #get the last line!
    #println("$accum")
    println("$linevals");
end
    



#parsefile("input")