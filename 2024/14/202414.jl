#isn't this just modulo arithmetic (possibly with a prime-factors twist, given the space boundaries are all prime)

parser = r"p=([-]?\d+),([-]?\d+) v=([-]?\d+),([-]?\d+)"

robots = readlines("inputtest") |> Base.Fix1(map, x->parse.(Int64,match(parser, x).captures)) 

testlims = (11,7)
reallims = (101,103)

quads = Dict([[x,y]=>0 for x ∈ (true,false), y ∈ (true, false)])
pt1posns = map(robots) do r
    lims = testlims 
    p = mod.((r[1:2] .+ (r[3:4].*100)), lims) 
    p == lims .÷ 2 && return 
    quads[p .< (lims.÷2)] += 1 
end


print("$(values(quads)) -> $(reduce(*, values(quads)))")