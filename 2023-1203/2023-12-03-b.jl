
#part 1

ex_cap(match) = match.captures[1]
ex_off(match) = (match.offset,UInt[])

function check_symbols(s, pots) #where p is a potential match
    list = UInt[]
    #sindex = 1
    for p in pots
        pstart = p.offsets[1] - 1 #because we could be diagonally across from input
        pend = p.offsets[1] + length(p.captures[1])     
        if s < pstart || s > pend
            continue;
            #sindex += 1 #move symbol match window so we don't waste time
        end
        
        #if we're here then it must be in the range!
        push!(list, parse(UInt, p.captures[1]))
    end

    list
end       



open("input") do f
    gearvals = 0    
    old_symbols = []
    old_potentials = []
    prev_matches = []
    for line in eachline(f) 
        
        potentials = collect(eachmatch(r"([0-9]+)", line))  #the numbers in this line 
        symbols = Dict(ex_off.(eachmatch(r"([*])", line))) #the locations of the asterisks on this line and their associated numbers

        for k in keys(symbols)
            symbols[k] = check_symbols(k, potentials ∪ old_potentials)
        end

        for k in keys(old_symbols)
            append!(old_symbols[k],check_symbols(k, potentials))
        end

        for (k,v) in pairs(old_symbols)
            if length(v) == 2
                gearvals += v[1]*v[2]
            end
        end

        old_potentials = potentials
        old_symbols = symbols

    end

    #get the last line!
    for (k,v) in pairs(old_symbols)
        if length(v) == 2
            gearvals += v[1]*v[2]
        end
    end

    println("$gearvals");
end
    