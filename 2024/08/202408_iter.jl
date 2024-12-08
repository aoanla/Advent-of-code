using IterTools
#for subsets

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

for v ∈ values(freq_locs)
    for s ∈ subsets(v,Val{2}()) 
        d = s[2] .- s[1]
        cs = (s[2].+d, s[1].-d)
        foreach(x -> ((x .> (0,0)) .&& (x .<= boundary)) == (true, true) && push!(sites,x), cs )
    end
end


print("Pt1 = $(length(sites))\n")

#δ == 0 -> Inf 
#δ > 0 -> floor(boundary-x / δ) 
#δ < 0 -> floor(x-1 / δ)
limit(δ,x) = begin
    δ == 0 && return first(boundary) #so big we won't pick it
    dist = δ > 0 ? first(boundary) - x : 1-x
    dist÷δ 
end

for v ∈ values(freq_locs)
    for s ∈ subsets(v,Val{2}())

        d = (s[2] .- s[1])
        d = d .÷ gcd(d...)
        #"closest to zero" of each of the negative and positive integers n for s[2] .+ n.*d that are 1 or boundary -> srt, end_ 
        srt = minimum(limit.(d.*(-1),s[2])) .* (-1)
        end_ = minimum(limit.(d,s[2]))
        foreach(x->push!(sites, s[2].+(x.*d)),srt:end_)
        end
#    )
end


print("\nPt2 = $(length(sites))\n")