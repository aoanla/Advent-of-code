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

values(freq_locs) |> collect |> (x -> subsets(x,Val{2}())) |> collect |> (s -> foreach(s) do 
    d = s[2] .- s[1]
    cs = (s[2].+d, s[1].-d)
    foreach(x -> ((x .> (0,0)) .&& (x .<= boundary)) == (true, true) && push!(sites,x), cs )
end
)


print("Pt1 = $(length(sites))\n")

#δ == 0 -> Inf 
#δ > 0 -> floor(boundary-x / δ) 
#δ < 0 -> floor(x-1 / δ)
limit(δ,x) = begin
    δ == 0 && return boundary #so big we won't pick it
    dist = δ > 0 ? boundary - x : x - 1
    floor(dist/δ) 
end

values(freq_locs) |> collect |> (x -> subsets(x,Val{2}())) |> collect |> (s -> foreach(s) do 
    d = (s[2] .- s[1])
    d = d .÷ gcd(d...)
    #"closest to zero" of each of the negative and positive integers n for s[2] .+ n.*d that are 1 or boundary -> srt, end_ TODO
    srt = -minimum(limit.(-d,s[2]))
    end_ = minimum(limit.(d,s[2]))
    foreach(x->push!(sites, s[2].+(n.*d)),srt:end_)
end
)





print("\nPt2 = $(length(sites))\n")