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
    α::Union{Rational,Float64}
    β::Union{Rational,Float64}
    γ::Union{Rational,Float64} 
    δ::Union{Rational,Float64}
    raw::Vector{Int128}
end 

hails = open("input2") do f
    hails = Hail[]
    re = r"(-?[0-9]+),\s+(-?[0-9]+),\s+(-?[0-9]+)\s+@\s+(-?[0-9]+),\s+(-?[0-9]+),\s+(-?[0-9]+)"
    for line in readlines(f)
        A,B,C,D,E,F = parse.(Int128, match(re, line).captures) #wow we need 128 bit integers!
        push!(hails, Hail(A-(D*B//E), D//E, 1//D, A//D, [A,B,C,D,E,F]) )
    end 
    hails
end

function intersect(h1::Hail,h2::Hail)
    h1.β == h2.β && return nothing #no intersection if parallel - safe as rationals

    y =  typeof(h1.α) == Rational ? (h1.α - h2.α) // (h2.β - h1.β) : (h1.α - h2.α) / (h2.β - h1.β) 
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
            println("Intersection of $(hails[i]) and $(hails[j]) @ $x,$y ")
            #also need to check if t is negative!
            counter += 1
    end
    counter 
end

println("$(intersect_range(hails,  7, 27))")

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

#parallel(hails)

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

#...oh, my, god, after just sitting in the bath for a bit, I actually tried visualising the problem.
#
#
# If you imagine the rock ray's viewpoint, looking in the direction it is flying, *all of the trajectories of the hailstones intersect at the same point* 
# (because from it's point of view, that point is the "origin" projected on the plane perpendicular to it, and it doesn't move in that plane, so anything it hits must alsi
# be at that point in the same projected plane)
# 
# So, the *direction* of R is the unique direction that, when we rotate space so that z points in that direction, all hailstone trajectories intersect at the same x,y coordinates
# (and the times they intersect are the times that R hits them, so we can solve for it's actual velocity and then its position by back calculating.)
# as this is a *direction*, it has only 2 degrees of freedom, which means the search space is easier too.

#and this must be what Eric intended, given part 1...

# if v is our vector we want to put along z, and v is normalised then we calculate the rotation matrix by:

# v.z = cos angle between v and z right now  = cθ
# v×z = the vector we need to rotate around (perp to v and z) to get that rotation = ux uy uz 

#rotation about an arbitrary axis is :

#    Γ  cθ+ux^2(1-cθ)           uxuy(1-cθ)-uzsθ     uxuz(1-cθ)+uysθ
#R = |  uyux(1-cθ) + uzsθ       cθ + uy^2(1-cθ)
#    L  uzux(1-cθ) - uysθ    ....
#
# doing this with matrix maths since this is Julia  R = cθ I̲ + sθ [u]ₓ + (1-cθ) u⨷u   (where ux is the cross product matrix and ⊗ is outer product) 
#
# I guess if we do this in float64 we might be okay if we just get things that are close to ints at the end?




#take three hailstones, and make them more tractable by transforming them so that one of them has its start point at the origin
# (hopefully this makes *all* of them smaller and less awful)

three_hails = deepcopy(hails[1:3])
for e in three_hails
    println("$e   $(hails[1])")
    e.raw[1] -= hails[1].raw[1]
    e.raw[2] -= hails[1].raw[2]
    e.raw[3] -= hails[1].raw[3]
end
#we need to *undo* this afterward to get back into the "normal" coordinate space!

for rx ∈ -3:-2, ry ∈ 0:1, rz ∈ 1:2
    rx == 0 && ry == 0 && continue #can't be parallel with z if we're doing this! 
    println("****************************************")
    println("$rx $ry $rz")
    #n = [rx,ry,rz] / sqrt(rx^2 + ry^2 + rz^2)
    #cθ = n[3] #easy dot product
    #sθ = sqrt(1-cθ^2)  #less pleasant  
    #u = [n[2], -n[1], 0] #also easy cross product
    #rotation = [  [ cθ+n[2]*n[2]*(1-cθ)   n[2]n[1](cθ-1)  -n[1]sθ ] ; [n[2]n[1](cθ-1)  cθ+n[1]n[1](1-cθ) -n[2]sθ] ; [n[1]sθ  n[2]sθ   cθ] ]   #check orientation
    #
    #rotated_hails = rotate(rotation, three_hails) #need a better representation for them so I can easily rotate them

    ## sigh, I was obviously v tired last night because:
    # firstly: you don't need a rotation matrix to get the perpendicular components to n, if n normalised.
    # you just project onto two unit vectors perpendicular to n and to each other (so, say, n × x  and n × x × n )

    #n × z
    perpx = Float64[ry, -rx, 0]#[n[2], -n[1], 0] 
    perpx ./= sqrt(sum(perpx.^2))
    #n x z x n
    perpy = Float64[-rx*rz,  -ry*rz, ry*ry+rx*rx] 
    perpy ./= sqrt(sum(perpy.^2))

    #secondly, though, we don't even need to project here, because I was missing the obvious thing staring me in the face from earlier:
    #### # R̲ₒ = H̲₀ + (H̲-R̲)tₜ  =  H̲₀′ + (H̲′-R̲)tₛ  ###
    # means that if we subtract R from H, ∀ hailstones, they now have new velocities V such that their *trajectories intersect* at Rₒ (although the
    # individual hailstones don't enter that point on their trajectories at the same times - but we don't care about the ts really)    

    #so, rather than projecting, we can just calculate V for our hailstones by subtracting H and then go from there 

    #dot products for projection
    th = []
    for e in three_hails
        A = sum(e.raw[1:3] .* perpx)
        B = sum(e.raw[1:3] .* perpy)
        C = 0 #irrelevant
        D = sum(e.raw[4:6] .* perpx)
        E = sum(e.raw[4:6] .* perpy)
        F = 0 #irrelevant
        push!(th, Hail(A-(D*B/E), D/E, 1.0/D, A/D, [0,0,0,0,0,0]) )
    end
    
    #(we do need to ensure our resulting Vs arent parallel though, because we want them to intersect at a *single* point, Ho, not everywhere)
    #function intersect(h1::Hail,h2::Hail)
    #    h1.β == h2.β && return nothing #no intersection if parallel - safe as rationals
    # 
    #    y = (h1.α - h2.α) // (h2.β - h1.β)
    #    x = h1.α + h1.β*y
    #    (x,y)
    #end
    h1h2 = intersect(th[1], th[2])
    h1h3 = intersect(th[1], th[3])
    (h1h2 == nothing || h1h3 == nothing) && continue #parallel rays :(
    (abs(h1h2[1] - h1h3[1]) > 0.01 || abs(h1h2[2] - h1h3[2]) > 0.01 )  && continue #not our match, as these rays are not all mutually intersecting at same point
    x,y = h1h2
    println("Intersection @ $h1h2  $h1h3  with $th")
    #ans = check_2dintersections(th) #if they all intersect at (close to) same point, hurrah!
    #ans == nothing && continue #there was no triple insection
    #x,y, t1,t2,t3 = ans  #Get times of intersection + place (=x,y coords of start of rock)
    
    t1 = th[1].γ*x - th[1].δ
    t2 = th[2].γ*x - th[2].δ
    #if isnan(t1)
    #    println("NAN: $rx $ry $rz   $perpx $perpy $th")
    #    continue
    #end
    (t1 < 0 || t2 < 0) && continue #in the past collision 
    println("Time is t1 @ $t1,, t2 @ $t2")
    #once we have the times these also give us when things happen in the *untransformed* frame so:
    #simplifiying because we transformed such that three_hails[1] starts at origin

    vel = (three_hails[2].raw[1:3] .+ three_hails[2].raw[4:6].*t2 .- three_hails[1].raw[4:6].*t1) ./ (t2-t1) 
    
    #so, tracing back from origin of three_hails[1] by t1 seconds
    println("Transforming from $(hails[1].raw[1:3])")

    ##################RELATIVE VELOCITY!!!!! 
    true_start = hails[1].raw[1:3] .+ (three_hails[1].raw[4:6] .- vel).*t1 #remember to undisplace by hails[1]'s coords to undo the first transform outside the loop

    int_start = round.(true_start)
    println("Found at $int_start velocity: $vel")
    println("$(sum(int_start))")
    #break
end
