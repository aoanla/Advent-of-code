#this is *YET ANOTHER RANGE INTERSECTION PUZZLE*
#I guess Eric thinks we're actually building libraries in the earlier days rather than trying to solve each puzzle from scratch 
#if we were doing that, this wouldn't be so vaguely repetitive?

#Anyway, 2d ranges like in Day 19 (which I still need to finish in Rust)
# brick lands on brick below if intersection of ranges. Iterate down the list until you hit one or more at same level
# tag all the bricks you land on with the *number* of bricks total you landed on 

#brick can be destroyed if none of its tags are 1 


#a "1wide" interval is of course okay - these are inclusive so 1,1 = just 1
struct Interval 
    low:: UInt16
    high:: UInt16
end 


struct Brickterval
    x:: Interval
    y:: Interval
    z:: Interval
    supports::UInt16 #number of bricks sitting on it 
end 

function intersect(r1::Interval, r2::Interval)
     ( (r1.low > r2.low) && (r1.low < r2.high) ) || ( (r1.high > r2.low) && (r1.high < r2.high) )
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

    Brickterval( Interval(ints[1]...), Interval(ints[2]...), Interval(ints[3]...), UInt16(0))
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

brick_stack = Set{Brickterval}[]