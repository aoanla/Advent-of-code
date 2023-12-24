# We've given sets of linear equations in t for x,y,z
# but we need to intersect just the lines (regardless of t) in x,y
## so need to make parametric in x,y

# Row     A, B, C @ D, E, F 

# x = A + Dt ; y = B + Et ; z = C + Ft 
# => x = A + (D/E)( y-B) = (A- D*B/E) + D/E (y) = α + βy

#
# then intersections between two sets are easy, just equate xs and solve for y
# x = α+βy , x'=α'+β'y  => α+βy = α'+β'y  iff β≠β' (parallel) -> y = (α-α')/(β'-β)
# (and x via either starting equation)
# check either x or y in the range we consider, and done

struct Hail
    α::Rational
    β::Rational 
    raw::Tuple{Int, Int, Int, Int, Int, Int}
end 

hails = open("input2") do f
    hails = Hail[]
    re = r"(-?[0-9]+),\s+(-?[0-9]+),\s+(-?[0-9]+)\s+@\s+(-?[0-9]+),\s+(-?[0-9]+),\s+(-?[0-9]+)"
    for line in readlines(f)
        println("$line")
        A,B,C,D,E,F = parse.(Int, match(re, line).captures)
        push!(hails, Hail(A-(D*B//E), D//E, (A,B,C,D,E,F)) )
    end 
    hails
end

function intersect(h1::Hail,h2::Hail)
    h1.β == h2.β && return nothing #no intersection if parallel - safe as rationals

    y = (h1.α - h2.α) // (h2.β - h1.β)
    x = h1.α + h1.β*y
    (x,y)
end

function intersect_range(hails, minr, maxr)
    counter = 0
    for i in eachindex(hails), j in eachindex(hails)[i+1:end]
            res = intersect(hails[i], hails[j])
            isnothing(res) && continue 
            x,y = res
            #println("Intersection of $(hails[1]) and $(hails[2]) @ $x,$y")
            (x < minr || x > maxr || y < minr || y > maxr) && continue 
            println("Intersection of $(hails[i]) and $(hails[j]) @ $x,$y")
            #also need to check if t is negative!
            counter += 1
    end
    counter 
end

println("$(intersect_range(hails, 7, 27))")