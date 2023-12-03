
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
        
        potentials = collect(eachmatch(r"([0-9]+)", line))  #the numbers in this line 
        symbols = ex_off.(eachmatch(r"[^.0-9]", line)) #the locations of the symbols on this line

        accept = filter(p -> check_line(p, sort(old_symbols ∪ symbols) ), potentials) ##current line, old+current symbols                   
        currmatches = ex_cap.(accept) 
        setdiff!(potentials, accept)
            
        accept = filter(p -> check_line(p, symbols), old_potentials) ##prev line, current symbols
        append!(prev_matches, ex_cap.(accept) )

        linevals += sum(parse.(UInt, prev_matches)) #sum "completed prev line matches"
        old_potentials = potentials
        old_symbols = symbols
        prev_matches = currmatches

    end
    linevals += sum(parse.(UInt, prev_matches)) #get the last line!

    println("$linevals");
end
    