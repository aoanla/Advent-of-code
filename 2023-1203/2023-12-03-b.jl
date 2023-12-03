
#part 2

#ranges are *matching ranges* so they're 1 before and 1 after the actual number to get diagonals
ex_range(match) = (pstart=match.offsets[1]-1, pend = match.offsets[1] + length(match.captures[1]), content=match.captures[1])
ex_off(match) = (match.offset,UInt[])

function check_symbols(s, pots) #where p is a potential match
    list = UInt[]
    #sindex = 1
    for p in pots    
        if s < p.pstart || s > p.pend
            continue;
            #sindex += 1 #move symbol match window so we don't waste time
        end
        #if we're here then it must be in the range!
        push!(list, parse(UInt, p.content))
    end

    list
end       



open("input") do f
    gearvals = 0    
    old_symbols = []
    old_potentials = []
    prev_matches = []
    for line in eachline(f) 
        
        potentials = collect(ex_range.(eachmatch(r"([0-9]+)", line)))  #the numbers in this line as ranges and content 
        symbols = Dict(ex_off.(eachmatch(r"([*])", line))) #the locations of the asterisks on this line and their associated numbers

        for k in keys(symbols)
            symbols[k] = check_symbols(k, potentials ∪ old_potentials)  #check our symbols against candidates on this and above line
        end

        for k in keys(old_symbols)
            append!(old_symbols[k],check_symbols(k, potentials)) #check the symbols from the above line against candidates on this line
            if length(old_symbols[k]) == 2 #"gears" are symbols with two values [this could be a filter but I don't think it matters]
                gearvals += old_symbols[k][1]*old_symbols[k][2]
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
    