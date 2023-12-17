#"The A* one"
using Pkg
Pkg.activate(".")
using DataStructures #I really don't to write my own PriorityQueue

#I think A* is probably fine for this, if the heuristic encodes the cost of an overall angle of approach that makes it hard to "alternate directions"
# (That is: since we have to move 1 orthogonally for every 3 down, at least, paths which are "straight down" actually cost more since we have to go
#                                                                                                                   3 down, 1 left, 1 right [total cost 5]

d = read("input2");
width = findfirst(==(UInt8('\n')), d);
matrix = (reshape(d, width, :)[begin:end-1, :]) .- UInt8('0');
println("$(size(matrix))")
bounds= size(matrix)
goal = CartesianIndex(bounds) #that's the last coordinate, so!
#bounds = bounds(matrix)

#note: check this is 1/3 and not 1/4 - the example shows chains of 4 squares in a row from 3 *movements* 
#           if 1/4 then 3->4 , 5*x÷3 -> (1 + 1/4 + 1/4) = 3*x÷2 ? 
""" h(posn)

    Return a suitable heuristic for the remaining distance (encoding the "no more than 3 steps in a straight line" rule)
""" 
function h(posn::CartesianIndex{2}, movehist::Tuple{CartesianIndex{2}, UInt8})
    #improvement - use movehist to tweak this estimate (only really significant for short distances where it matters if we can't move 3 in one dir in one go)
    return 0 # try with Dijkstra
    d = goal - posn
    #return d[1]+d[2]
    d == CartesianIndex((0,0)) && return 0
    (bigger, smaller) = d[1] > d[2] ? (d[1], d[2]) : (d[2], d[1])
    slope = smaller != 0 ? bigger ÷ smaller : bigger ; 
    #we're within the range where we can jink around and still get there within Metropolis distance
    slope < 4 && return d[1]+d[2]
    #otherwise, we'd have to make up the excess by going back and forth - a cost equivalent to doing a 3:1 slope and then "running back" the excess distance orthogonally
    #in fact bigger > 3smaller here, 1/3 bigger > smaller!
    #bigger +  bigger ÷ 3  #=3:1=# + bigger ÷ 3 - smaller #=excess we need to also "do"=#
    #5bigger ÷ 3  - smaller
    3bigger ÷ 2 - smaller
end

possibles = Set(CartesianIndex.([(0,1), (1,0), (0,-1), (-1,0) ]) );

""" return a list of locations accessible from c with its current move history annotation
    - we can't get the node "back" from movehist 
    - we can't get the node *forward* from movehist if count == 3
    - we can't violate bounds!
"""
function accessible(c, movehist)
    notaccessible = movehist[2] == 3 ? [movehist[1], movehist[1]*-1] : [movehist[1]*-1]
    p = setdiff(possibles, notaccessible)
    filter(p) do pp 
        checkbounds(Bool, matrix, c+pp)
    end     
end

function reconstruct_path(prev, cursor)
    totalpath = [cursor]
    while cursor in keys(prev)
        cursor = prev[cursor]
        pushfirst!(totalpath, cursor)
    end
    totalpath
end


function A✴(s::CartesianIndex{2}, g::CartesianIndex{2})

    prev = Dict{CartesianIndex{2}, CartesianIndex{2}}() #dictionary of previous points

    goalscore = fill(typemax(1), bounds)  #cost s -> cell
    goalscore[s] = 0 #zero cost to not move at all!

    #we need to note where we last entered each node from and now many times we'd done that exact direction 
    movehistory = Dict{CartesianIndex{2}, Tuple{CartesianIndex{2}, UInt8}}([s=>(CartesianIndex(0,0), 0)]);

    fscore = fill(typemax(1), bounds) #f, our heuristic estimate for s->g via cell 
    fscore[s] = h(s, movehistory[s]) #and our best guess for s is just h at the moment 



    openset = PriorityQueue{CartesianIndex{2}, Int}(s => fscore[s] ) #need to sort out *what* we can use as a priority queue in Julia

    while !isempty(openset)

        #note, there's something *screwy* with the documentation for PriorityQueue - 
        # Docs claim popfirst! gives the pair K->V 
        # Julia claims popfirst! is not implemented for PriorityQueue [at least a v0.18.15] and I need to use dequeue! (which is supposed to be deprecate)
        # and only gives K not V !
        cursor = dequeue!(openset) #the highest priority (lowest "value") node
        score = fscore[cursor]; 
        cursor == g #=we got there!=# && begin
                                                println("$(reconstruct_path(prev, cursor))"); 
                                                return score # the total cost! (I think fscore[cursor] == goalscore[cursor] at this point?)
                                        end 
        hist = movehistory[cursor]
        #evaluate neighbours of cursor = which means we need to store the direction we entered cursor from and how long we'd been moving in that direction
        for i in accessible(cursor, hist)
            cand = cursor + i;
            trialgoalscore = goalscore[cursor] + matrix[cand];
            if trialgoalscore < goalscore[cand]
                prev[cand] = cursor 
                goalscore[cand] = trialgoalscore
                movehistory[cand] = i == hist[1] ? (i, hist[2]+1) : (i, 1)  #accrue straight lines - it's okay for this to change if cand leaves and re-enters the open set
                fscore[cand] = trialgoalscore + h(cand, movehistory[cand])
                #if haskey[openset] #update priority (which *can* change here I think!)
                #    openset cand priority = fscore[cand]
                #else 
                openset[cand] = fscore[cand]
                #end
            end
        end
    end 

    return typemax(1)
end

println("$(A✴(CartesianIndex((1,1)), goal))");


