#pt1 is just iterate over all the pairs of a given type, with some bounds checking

freq_locs = Dict{Char, Vector{Tuple{Int32,Int32}}}()

map_ = readlines("input")

boundary = (length(first(map_)), length(map_))

for (y,line) ∈ enumerate(map_)
    for (x,ch) ∈ enumerate(collect(line))
        ch == '.' && continue
        if haskey(freq_locs,ch)
            push!(freq_locs[ch],(x,y))
        else 
            freq_locs[ch] = [(x,y)]
        end
    end
end

sites = Set{Tuple{Int32,Int32}}()

for (k,v) ∈ pairs(freq_locs)
    for (i,vi) ∈ enumerate(v)
        for vii ∈ v[i+1:end]
            s1 = (vi.*2) .- vii
            s2 = (vii.*2) .- vi
            ((s1 .> (0,0)) .&& (s1 .<= boundary)) == (true, true) && push!(sites,s1)
            ((s2 .> (0,0)) .&& (s2 .<= boundary)) == (true, true) && push!(sites,s2)
        end
    end
end

print("$(length(sites))")

#pt2 is just doing some integer-division into the grid 
for (k,v) ∈ pairs(freq_locs)
    for (i,vi) ∈ enumerate(v)
        for vii ∈ v[i+1:end]
            dists = abs.(vi .- vii) #dist - which *could* be a multiple of the core divisors (if it's, say (6,3), then our line is actually (2,1))
            divs = dists .÷ gcd(dists...)
            #assuming boundary is square, find coords on the line where we hit 1 or boundary
            #divide through both spans, and take lowest value

            #  we do need to avoid double-counting - how do we find intersections of our lines? 
        end
    end
end