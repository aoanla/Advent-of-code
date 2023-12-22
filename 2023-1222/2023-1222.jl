#this is *YET ANOTHER RANGE INTERSECTION PUZZLE*
#I guess Eric thinks we're actually building libraries in the earlier days rather than trying to solve each puzzle from scratch 
#if we were doing that, this wouldn't be so vaguely repetitive?

#Anyway, 2d ranges like in Day 19 (which I still need to finish in Rust)
# brick lands on brick below if intersection of ranges. Iterate down the list until you hit one or more at same level
# tag all the bricks you land on with the *number* of bricks total you landed on 

#brick can be destroyed if none of its tags are 1 


#a "1wide" interval is of course okay - these are inclusive so 1,1 = just 1
mutable struct Interval 
    low:: UInt16
    high:: UInt16
end 


mutable struct Brickterval
    x:: Interval
    y:: Interval
    z:: Interval
    support::Set{Brickterval} #Set of *essential* bricks supporting its chain- reset by being on an essential brick directly
    essential::Bool #is this brick essential [does it have supports == 1 anywhere in that lit]
    count::Int #power count for essential bricks "how many bricks fall if I go away"
end 

function intersect(r1::Interval, r2::Interval)
     ( (r1.low >= r2.low) && (r1.low <= r2.high) ) || ( (r1.high >= r2.low) && (r1.high <= r2.high) ) || ( (r2.high >= r1.low) && (r2.high <= r1.high) ) || ( (r2.low >= r1.low) && (r2.low <= r1.high) )
end


#must intersect x and y to collide 
function plane_intersect(brick1, brick2)
    intersect(brick1.x, brick2.x) & intersect(brick1.y, brick2.y)
end

sort_tuple(x) = x[1] > x[2] ? (x[2], x[1]) : (x[1], x[2])

#absolutely not assuming these are ordered pairs!
function parse_to_brickterval(s::String)
    lows, highs = split(s, '~')
    ints = collect(map(sort_tuple, zip( parse.(UInt16, split(lows,',')), parse.(UInt16, split(highs, ',') )) ))

    Brickterval( Interval(ints[1]...), Interval(ints[2]...), Interval(ints[3]...), Set{Brickterval}(), false, 1)
end

bricks = open("input2") do f
    map(parse_to_brickterval, readlines(f)) 
end 

low_z(brick) = brick.z.low
high_z(brick) = brick.z.high

#now, we need to order these bricks by their height, because somehow Elves don't just work up or down stream of falling bricks logically 
sort!(bricks, by=low_z)


#okay, so now we can start intersecting the bricks - this will be easiest if we insert them into a Vector ordered by height that we build dynamically
# so lookup for "height = n" is faster - the wrinkle here is that we need to insert at high_z(brick) because that's the bit they'll hit first

function settle!(bricks)
    highest_brick_z = high_z(bricks[end])

    brick_stack = [ Brickterval[] for i in 1:highest_brick_z ]
    essential_bricks = Set{Brickterval}() #vector of the essential bricks now
    moved =0

    for brick in bricks
        #println("BRICK: $brick") 
        hit = false

        for layer in low_z(brick)-1:-1:1 #can't collide with bricks "above" us and the stack isn't that big anyway - colliding "down the list" 
            intersectors = []
            for l_brick_i in eachindex(brick_stack[layer]) #check each collision    
                if plane_intersect(brick_stack[layer][l_brick_i], brick)
                    push!(intersectors, l_brick_i)
                end
            end 
            println("CONSIDERED: $brick")
            isempty(intersectors) && continue #no intersection at this height, try lower 
            #else hits 
            hit = true
            sups = length(intersectors)

            if (layer+1) < brick.z.low
                moved+=1
                println("\tMOVED: $brick")
            end
            
            z_heigh = brick.z.high - brick.z.low 
            brick.z.low = layer+1
            brick.z.high = layer + 1 + z_heigh 
        
            #if our direct support is not essential, essential supports for this brick are the union of the essential supports for our direct supports  
            # this is important for when we walk the tree to get "total falling bricks" = removing an essential brick does not necessarily drop everything above it
            #                                                                                (a brick could bridge two essentials higher up)

            if sups == 1#this brick is essential because it's critical to our brick
                brick_stack[layer][intersectors[begin]].essential = true 
                push!(essential_bricks, brick_stack[layer][intersectors[begin]] ) 
                brick.support = Set(brick_stack[layer][intersectors]) #set will turn our vec into a set okay even with 1 elem
            else #sups is bigger
                brick.support = mapreduce(x->x.support , ∪, brick_stack[layer][intersectors])
            end

            push!(brick_stack[brick.z.high], brick) #add to stack one up

            break #remember to stop checking now! 
        end
        if hit == false #hit the ground 
            z_heigh = brick.z.high - brick.z.low 
            brick.z.low = 1 
            brick.z.high = z_heigh + 1 
            push!(brick_stack[brick.z.high], brick)
        end 
    end
    (brick_stack, essential_bricks, moved)
end 

(brick_stack, essential_bricks, _) = settle!(bricks)

#println("$bricks")
println("$(length(bricks) - length(essential_bricks))")


#sort for highest essential brick first which is important for efficiency
es_vec = sort(collect(essential_bricks), by = x->x.z.high, rev=true)

function part2!(ess_bricks, brick_stack)
    tot = 0 
    for e_brick_i ∈ eachindex(ess_bricks)

        e_brick = ess_bricks[e_brick_i]

        layer = e_brick.z.high #don't scan layers *below* this brick!
        dep_essent = Set([e_brick])
        #the essential bricks dependant solely on this essential brick... 
        dependant_essentials = filter(x->issetequal(x.support, dep_essent) , ess_bricks[begin:e_brick_i-1])
        start_power = 0 #mapreduce(x->x.count, + , dependant_essentials) #start with the power of those essentials - no, just assign this to them in the stack
        #bricks will fall if their set of essentials supports is a subset of the supports we remove with this one essential, which is union us+our own dependant_essentials
        union!(dep_essent, dependant_essentials)
        #safe as to be essential a brick must have at least 1 thing above it
        #this hack is because it seems to be super difficult to overwrite a whole row of an array like this without using element indices, even with @views
        for s_layer ∈ (layer+1):length(brick_stack)
            bricks_to_consider = filter(x->x.support ⊆ dep_essent,  brick_stack[s_layer] ) 

            start_power += mapreduce(x->x.count, +, bricks_to_consider; init = 0) #essential bricks have count > 1 for their dependencies
            #count them, and then remove them from brick_stack layer: 
            brick_stack[s_layer] = filter(x->x.support ⊈ dep_essent, brick_stack[s_layer]) #iterating over just the slices doesn't work due to assignment
 
        end

        tot+=start_power #bricks that fall *if this brick is deleted*
        e_brick.count = start_power + 1 #because if *this brick /falls/* it goes down and so does eveything on it (so start_power +1 )
    end
    tot
end

#println("$(part2!(es_vec, brick_stack))") #also too low :(


#we could just brute-force this by doing the "falling thing" again with the "sorted" list of bricks after we settle them once (but removing the "essential" brick each time)
#
sort!(bricks, by=low_z)

function brick_eq(ba,bb)
    ba.x.low != bb.x.low || ba.x.high != bb.x.high || ba.y.low != bb.y.low || ba.z.low != bb.z.low || bb.y.high != bb.y.high
end

function brute_force(es_vec, bricks)
    counter =0
    for eb in es_vec
        println("...............................................")
        println("REMOVING $eb")

        f_bricks = deepcopy(collect(filter(x->brick_eq(x,eb), bricks)))
        _, _, count = settle!(f_bricks)
        println("Count: $count")
        counter+=count
    end
    counter 
end

println("$(brute_force(es_vec, bricks))") #this is *also* not the right answer somehow... what am I missing here? Somehow we're never considering stuff against the first item of the list?