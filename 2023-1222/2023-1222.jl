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
    supports::Vector{Tuple{Int, Int}} #vector of bricks sitting on it as (stack index, posn in that layer) tuples
    essential::Bool #is this brick essential [does it have supports == 1 anywhere in that lit]
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

    Brickterval( Interval(ints[1]...), Interval(ints[2]...), Interval(ints[3]...), UInt16[], false)
end

bricks = open("input") do f
    map(parse_to_brickterval, readlines(f)) 
end 

low_z(brick) = brick.z.low
high_z(brick) = brick.z.high

#now, we need to order these bricks by their height, because somehow Elves don't just work up or down stream of falling bricks logically 
sort!(bricks, by=low_z)


#okay, so now we can start intersecting the bricks - this will be easiest if we insert them into a Vector ordered by height that we build dynamically
# so lookup for "height = n" is faster - the wrinkle here is that we need to insert at high_z(brick) because that's the bit they'll hit first

highest_brick_z = high_z(bricks[end])

brick_stack = [ Brickterval[] for i in 1:highest_brick_z ]
essential_bricks = Set{Tuple(Int,Int)}() #tuple of coords of the essential bricks now

for brick in bricks 
    hit = false
    for layer in low_z(brick)-1:-1:1 #can't collide with bricks "above" us and the stack isn't that big anyway - colliding "down the list" 
        intersectors = []
        for l_brick_i in eachindex(brick_stack[layer]) #check each collision    
            if plane_intersect(brick_stack[layer][l_brick_i], brick)
                push!(intersectors, l_brick_i)
            end
        end 
        isempty(intersectors) && continue #no intersection at this height, try lower 
        z_heigh = brick.z.high - brick.z.low 
        brick.z.low = layer+1
        brick.z.high = layer + 1 + z_heigh 
        push!(brick_stack[brick.z.high], brick) #add to stack one up
        hit = true
        sups = length(intersectors)
        for i in intersectors #add coords of the brick we support to the list 
            push!(brick_stack[layer][i].supports, (brick.z.high, length(brick_stack[brick.z.high])) )
        end
        if sups == 1#this brick is essential 
            brick_stack[layer][intersectors[begin]].essential = true 
            push!(essential_bricks, (layer, intersectors[begin]) ) 
        end

        break #remember to stop checking now! 
    end
    if hit == false #hit the ground 
        z_heigh = brick.z.high - brick.z.low 
        brick.z.low = 1 
        brick.z.high = z_heigh + 1 
        push!(brick_stack[brick.z.high], brick)
    end 
end 

#println("$brick_stack")

#println("$(length(essential_bricks))")

println("$(length(bricks) - length(essential_bricks))")


lookup(st_i) = brick_stack[st_i[1]][st_i[2]]

tot = 0 
for e_brick_i in essential_bricks
    power = length(e_brick_i.supports ) # start with the length of the supports list for this brick
    stck = []
    append!(stck, e_brick_i.supports )
    while !isempty(stck)
        node = lookup(pop!(stck))
        power += length(node.supports)  #this does not work if there's overlap in the sets of supported things of course - maybe we should just build this as we go initially
        append!(stck, node.supports)
    end
    global tot += power
end 