#isn't this just modulo arithmetic (possibly with a prime-factors twist, given the space boundaries are all prime)

parser = r"p=([-]?\d+),([-]?\d+) v=([-]?\d+),([-]?\d+)"

robots = readlines("input") |> Base.Fix1(map, x->parse.(Int64,match(parser, x).captures)) 

#lims = (11,7)
const lims = (101,103)
const hlims = lims .÷ 2

quads = Dict([[x,y]=>0 for x ∈ (true,false), y ∈ (true, false)])
pt1posns = map(robots) do r
    #lims = testlims 
    p = mod.((r[1:2] .+ (r[3:4].*100)), lims) 
    any(p .== hlims) && return 
    quads[p .< hlims] += 1 
end


print("Pt1 = $(reduce(*, values(quads)))\n")

#pt2 is one of those stupid pointless questions that needs you to look at the input to work out what precisely it means by "Christmas Tree" shape.