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

#to check time we can just check time for x 
# x = A + Dt -> t = (x-A)/D = (1/D)x - A/D = γx - δ

#pt 2
using Zygote

struct Hail
    α::Rational
    β::Rational
    γ::Rational 
    δ::Rational
    raw::Tuple{Int, Int, Int, Int, Int, Int}
end 

hails = open("input") do f
    hails = Hail[]
    re = r"(-?[0-9]+),\s+(-?[0-9]+),\s+(-?[0-9]+)\s+@\s+(-?[0-9]+),\s+(-?[0-9]+),\s+(-?[0-9]+)"
    for line in readlines(f)
        A,B,C,D,E,F = parse.(Int128, match(re, line).captures) #wow we need 128 bit integers!
        push!(hails, Hail(A-(D*B//E), D//E, 1//D, A//D, (A,B,C,D,E,F)) )
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
    hails = filter(hails) do h #positive time hail
        !( (h.raw[1] < minr && h.raw[4] < 0) || (h.raw[1] > maxr && h.raw[4] > 0) || (h.raw[2] < minr && h.raw[5] < 0) || (h.raw[2] > maxr && h.raw[5] > 0) )
        #starts with x less than r and going down || starts with x gt than r and going up ; same for y  
        #we still have some segments which *start* in the interval and leave it, or enter the interval midway
        # so we still need to check intersection time, but hopefully this winnows out the impossible cases 
    end
    for i in eachindex(hails), j in eachindex(hails)[i+1:end]
            res = intersect(hails[i], hails[j])
            isnothing(res) && continue 
            x,y = res
            (hails[i].γ*x - hails[i].δ <= 0 || hails[j].γ*x - hails[j].δ <= 0 ) && continue #past for one or both 
            (x < minr || x > maxr || y < minr || y > maxr) && continue 
            #println("Intersection of $(hails[i]) and $(hails[j]) @ $x,$y ")
            #also need to check if t is negative!
            counter += 1
    end
    counter 
end

println("$(intersect_range(hails,  200000000000000, 400000000000000))")

#part 2 - this seems *weirdly* over specified.

# we have to find  R̲₀ + R̲t such that we intersect all the hailstones.
# but! 
# R̲₀ has 3 unknowns. R̲ has 3 unknowns. 6 unknowns total
# each hailstone provides 3 simultaneous equations, and adds 1 unknown (time of intersection tᵢ)
# so, after 3 hailstones we already have 0 net unknowns remaining... so we're just solving a relatively small matrix math problem?

#ah, the wrinkle is that this is a non-linear problem (the product of two unknowns - R̲ and tᵢ is present in each)

# equations are of the form
#
#  Rₓ tᵢ + Rₒₓ - Vₓᵢ tᵢ - Oₓᵢ = 0  , where x ∈ {x,y,z} and i ∈ {1,2,3} (such that "Oₓ₁" is "A" for hailstone 1) 
# nonlinear in the leftmost term (unknowns {R}s, {t}s)

# I guess we could use multi-dimensional Newton-Raphson-Seki for this? Numerical stability seems concerning though. 

#(I assume what Eric actually wants us to do is to solve the whole system in an "AI" like way, with backprop and ADAM or something
# but let's see if good-old differentiable programming can do this for us here in Julia)



function optimiand(t,Rₒ,R)
    loss = 0
    for (tᵢ, hailsᵢ) in zip(t,hails)
        xx = R[1]*tᵢ + Rₒ[1] - hailsᵢ.raw[4]*tᵢ - hailsᵢ[1]
        yy = R[2]*tᵢ + Rₒ[2] - hailsᵢ.raw[5]*tᵢ - hailsᵢ[2]
        zz = R[3]*tᵢ + Rₒ[3] - hailsᵢ.raw[6]*tᵢ - hailsᵢ[3]
        loss += xx*xx + yy*yy + zz*zz
    end
    loss
end 

function NRS()
    Δ = xₙ - optimand(xₙ) / gradient(optimand, xₙ) #urg division by vectors
end
    