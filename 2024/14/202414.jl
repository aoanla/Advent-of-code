#isn't this just modulo arithmetic (possibly with a prime-factors twist, given the space boundaries are all prime)
using UnicodePlots

parser = r"p=([-]?\d+),([-]?\d+) v=([-]?\d+),([-]?\d+)"

robots = readlines("input") |> Base.Fix1(map, x->parse.(Int64,match(parser, x).captures)) 

#lims = (11,7)
const lims = (101,103)
const hlims = lims .÷ 2

pt(r, n) = mod.((r[1:2] .+ (r[3:4].*n)), lims)

function pt1(n)
    quads = Dict([[x,y]=>0 for x ∈ (true,false), y ∈ (true, false)]) 
    map(robots) do r
        #lims = testlims 
        p = pt(r,n)
        any(p .== hlims) && return 
        quads[p .< hlims] += 1 
    end
    reduce(*, values(quads))
end

print("Pt1 = $(pt1(100))\n")

#pt2 is one of those stupid pointless questions that needs you to look at the input to work out what precisely it means by "Christmas Tree" shape.

#some thoughts:
# height, width are coprime (in fact, they're prime-prime!). So, all of the robots will visit *every* point over lcm(height,width) = height*width steps
# so there's "only" ~10^4 possible configurations.

#Problem
#we don't know what it means by "picture of a Christmas tree". Is this a picture across the entire grid? A picture in one quadrant (maybe we just look for "all robots in one quad")
# a smaller picture than that?

#I guess the unsatifying approach would be to output 10^4 frames and watch them [at 10frames/sec that will take 1000 seconds, or 17 or so minutes, if we need to watch all of them]

# the other argument may be that pt1 is supposed to be relevant - the "detecting numbers in quadrants" suggests that maybe the picture *is* going to be in one quadrant.
#  -> maybe we need solutions with a significant imbalance of robots in one quadrant relative to all the others (because I assume that's what "most of the robots form a picture" means)

# the product of all the quads is maximised by an equal distribution (that is, if N total, max(a*b*c*(N-a-b-c)) is when a=b=c=N/4 -> N^4/256) if N >> 4
# and minimised by an unequal distribution with all in one quad (as that's zero) or a few in 3 and most in one (~N)

function pt2()
    d = Dict([n=>pt1(n) for n ∈ 1:prod(lims)])
    k_ordered = sort(collect(keys(d)); by=x->d[x])
    k_ordered[1:1000]
end

wait_for_key(prompt) = (print(stdout, prompt); read(stdin, 1); nothing)


for k ∈ pt2()
    pts = map(r->pt(r,k), robots)
    print("n = $k\n")
    p = scatterplot(first.(pts), last.(pts))
    display(p)
    print("****************************\n")
    wait_for_key("next?")

end

#rint("Pt2: $(pt2())\n")
