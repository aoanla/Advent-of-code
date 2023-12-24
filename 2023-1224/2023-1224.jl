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

function parallel(hails)
    for i in eachindex(hails), j in eachindex(hails)[i+1:end]
        #ratios 
        x = hails[i].raw[4] // hails[j].raw[4]
        y = hails[i].raw[5] // hails[j].raw[5]
        z = hails[i].raw[6] // hails[j].raw[6]
        if x == y && y == z
            println("parallel match: $(hails[i]), $(hails[j])")
        end
    end
    println("End of test")
end 

parallel(hails)

exit()
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

#Ah, no, I forgot: all our values are *integers*, so this is an *integer programming* problem. 
# There's lots of approaches to these - simulated annealing, say - or various parallel solution search things like GAs

function optimand(xₙ)
    t = xₙ[1:3]
    Rₒ = xₙ[4:6]
    R = xₙ[7:9]
    loss = 0
    for (tᵢ, hailsᵢ) in zip(t,hails)
        xx = R[1]*tᵢ + Rₒ[1] - hailsᵢ.raw[4]*tᵢ - hailsᵢ.raw[1]
        yy = R[2]*tᵢ + Rₒ[2] - hailsᵢ.raw[5]*tᵢ - hailsᵢ.raw[2]
        zz = R[3]*tᵢ + Rₒ[3] - hailsᵢ.raw[6]*tᵢ - hailsᵢ.raw[3]
        loss += abs(xx) + abs(yy) + abs(zz)
    end
    loss
end 

function d_optimand(xₙ)
    t = xₙ[1:3]
    Rₒ = xₙ[4:6]
    R = xₙ[7:9]
    loss = 0
    dt = [sum(R), sum(R), sum(R)]
    for i in eachindex(dt)
        dt[i] -= hails[i].raw[4] 
    end
    dRₒ = Int128[3,3,3] #always the same, it's a constant term in the loss 
    dR = Int128[sum(t), sum(t), sum(t)] #always dependant on the relevant tᵢ                    ]
    vcat(dt, dRₒ, dR)
end 

#function NRS(x₀)
#    xₙ = deepcopy(x₀)
#    Δ = ones(Rational{Int128}, 9)
#    while sum(abs.(Δ)) > 1  
#        Δ = round.(optimand(xₙ) / gradient(optimand, xₙ)[1]) #urg division by vectors
#        xₙ .-= Δ
#    end
                #Δ = xₙ - (gradient(optimand, xₙ))⁻¹ .optimand(xₙ)
                #v  #s        #v                       #s
#    xₙ
#end
    
#println("$(NRS(Rational{Int128}[30,30,30,1000000, 1000000, 1000000, 200,200,200]))")

function mutate!(xₙ)
    s = optimand(xₙ)
    ds = d_optimand(xₙ)
    println("Sumds = $(sum(ds))")
    option = ceil(rand()*sum(ds))
    println("Sumds = $(sum(ds))")
    select = 1
    for i in eachindex(ds)
        ds[i] > option && break
        select += 1
        option -= ds[i]
    end
    xₙ[select] -= round((s ÷ ds[select]) * rand())
end


function simulated_annealing(xₙ)

    loss = optimand(xₙ)
    count = 0 
    c_max = 1000000   
    while count < c_max
        #temp
        T = 1 - ((count+1)/c_max)
        xₘ = deepcopy(xₙ)
        mutate!(xₘ)
        new_loss = optimand(xₘ)
        if new_loss < loss
            xₙ = xₘ
            loss = new_loss
        else #conditional acceptance
            p = exp((new_loss-loss)/T )
            if  rand() < p
                xₙ = xₘ
                loss = new_loss
            end
        end
        count+=1
    end
    xₙ
end

#println("$(simulated_annealing(Int128[30,30,30,100000,1000000,10000,100,-100,40]))")

#or maybe we just need to do more maths

# the fact that all our hailstones are hit by our rock means that they pass through its line 

# R̲ₒ + R̲tᵢ = H̲₀ + H̲tₜ   =>  R̲ₒ = H̲₀ + (H̲-R̲)tₜ  for some tₜ (different for each hailstone)

# for two hailstones 
# this means that there are some tₜ tₛ respectively such that

# R̲ₒ = H̲₀ + (H̲-R̲)tₜ  =  H̲₀′ + (H̲′-R̲)tₛ
# 
# these are arbitrary hailstones, so we can assume that they're skew [we could test for this before doing the following] and their lines don't normally intersect

# but what the above says is that there's some linear offset we could apply that would make their *lines* intersect at a point, albeit at different times 
# (this feels like the answer Eric wants us to go for , since he had us intersecting lines with no time in pt 1 )
# (that offset is effectively R̲(tₜ-tₛ), right?  - rewrite thoses as

# H̲₀ -R̲tₜ + H̲tₜ  =  H̲₀′ -R̲tₛ + H̲′tₛ
# H̲₀ -R̲tₜ+R̲tₛ + H̲tₜ  =  H̲₀′ + H̲′tₛ
# H̲₀ -R̲(tₜ-tₛ) + H̲tₜ  =  H̲₀′ + H̲′tₛ   ... let (-R̲(tₜ-tₛ)) => κ̲
# H̲₀+κ̲ + H̲tₜ  =  H̲₀′ + H̲′tₛ 

#so this is now a problem of finding an (integer) κ̲ for pairs of lines that are skew, such that they aren't skew any more

# obviously there's an infinite number of such κ, depending on what point we want them to intersect at . 

# the condition for two lines to intersect in (more than 2d) is
# (H̲×H̲′)⋅(H̲ₒ-H̲ₒ′+κ̲) = 0

# and our κ must be a modification to the difference in the dot product to make this true, and it must have all integer components (although those components may be large)
# However - the velocities are generally quite constrained compared to the positions in this problem (they've generally been -1000...1000 or better)
# even better, if tₜ and tₛ are both integer as well, all three components of κ̲ will be a multiple of (tₜ-tₛ) which is quite unusual!

#That's still a lot of searching...

#...is there anything we can do with the fact that we don't just have pairs that do this - *all* of our hailstones can be made to = R̲ₒ with a presumably integer offset of R̲ 
#
# R̲ₒ = H̲₀ + (H̲-R̲)tₜ  =  H̲₀′ + (H̲′-R̲)tₛ = H̲₀′′ + (H̲′′-R̲)tᵣ  ... and so on

#if we assume all these ts are integral what does that get us?
#there's some integral R̲ and sets of integral κ such that... all of our lines intersect if we offset them appropriately.

#is this a *modulo arithmetic* thing? It's super suspicious that this is all integer multiples of R̲ 
# *can* we do modulo arithmetic line intersections? 
# that's not going to work if H != H′ right? *do* we have any parallel lines? 

# if we did then 
# R̲ₒ = H̲₀ + (H̲-R̲)tₜ  =  H̲₀′ + (αH̲-R̲)tₛ  
# (assuming parallel and not the same speed)
# ... but if they're *parallel* then the (const) distance between the lines is always a multiple of R, right? (because here R(tₜ-tₛ) *is* the translation vector between them)
# and since R is integer, and the ⧋t is also an integer (we assume...)

#but first we need to find two parallel lines... 
#... reader, we do not have any parallel lines

#... but can we do this in the different axes separately? I keep treating this as a whole vector problem, but if we constrain it to hailstones with identical velocities

# Rₓₒ = Hₓ₀ + (Hₓ-Rₓ)tₜ  =  Hₓ₀′ + (Hₓ-Rₓ)tₛ
# and so on for all x,y,z 

# So, if there's two hailstones with just x-components of their velocities that are the same, it's true that

# Hₓ₀ + (Hₓ-Rₓ)tₜ  =  Hₓ₀′ + (Hₓ-Rₓ)tₛ
# but these are *always the same distance apart* in x - doesn't this provide a constraint in Rₓ ? 
#subtract the two lines:

# (Hₓ₀-Hₓ₀′) = (Hₓ-Rₓ)(tₛ-tₜ)
# 
# if δt is an integer... this implies that (Hₓ-Rₓ) divides (Hₓ₀-Hₓ₀′) perfectly - aha, there's our modulo :D 

# so find candidate Rₓ such that (for two things with the same x speed) (Hₓ₀-Hₓ₀′) % (Hₓ-Rₓ) = 0
# there's not too many possible Rₓ to check [since as observed, the velocities seem to be +/-1000]

function parallel(hails)
    for i in eachindex(hails), j in eachindex(hails)[i+1:end]
        #ratios 
        if hails[i].raw[4] == hails[j].raw[4]
            println("parallel match X: $(hails[i]), $(hails[j])")
        end
        if hails[i].raw[5] == hails[j].raw[5]
            println("parallel match Y: $(hails[i]), $(hails[j])")
        end
        if hails[i].raw[5] == hails[j].raw[5]
            println("parallel match Z: $(hails[i]), $(hails[j])")
        end
    end
    println("End of test")
end 

#parallel(hails)

#we also don't have any x,y,z shared velocities :(

#I think we're going to have to go back to our original idea back up the page and search for suitable integer Rs that make lines intersect. But it's late now and I don't have
#time to write the code.