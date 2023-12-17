#"The A* one"

#I think A* is probably fine for this, if the heuristic encodes the cost of an overall angle of approach that makes it hard to "alternate directions"
# (That is: since we have to move 1 orthogonally for every 3 down, at least, paths which are "straight down" actually cost more since we have to go
#                                                                                                                   3 down, 1 left, 1 right [total cost 5]

d = read("input");
width = findfirst(==(UInt8('\n')), d);
matrix = (reshape(d, width, :)[begin:end-1]) .- UInt8('0');

goal = size(matrix); #that's the last coordinate, so!

#note: check this is 1/3 and not 1/4 - the example shows chains of 4 squares in a row from 3 *movements* 
#           if 1/4 then 3->4 , 5*x÷3 -> (1 + 1/4 + 1/4) = 3*x÷2 ? 
""" h(posn)

    Return a suitable heuristic for the remaining distance (encoding the "no more than 3 steps in a straight line" rule)
""" 
function h(posn)
    d = goal .- posn
    (bigger, smaller) = d[1] > d[2] ? (d[1], d[2]) : (d[2], d[1])
    slope = bigger ÷ smaller;
    #we're within the range where we can jink around and still get there within Metropolis distance
    slope < 3 && return d[1]+d[2]
    #otherwise, we'd have to make up the excess by going back and forth - a cost equivalent to doing a 3:1 slope and then "running back" the excess distance orthogonally
    #in fact bigger > 3smaller here, 1/3 bigger > smaller!
    #bigger +  bigger ÷ 3  #=3:1=# + bigger ÷ 3 - smaller #=excess we need to also "do"=#
    5bigger ÷ 3  - smaller
end

