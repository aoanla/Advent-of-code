#"The A* one"
using Pkg
Pkg.activate(".")
using DataStructures #I really don't to write my own PriorityQueue

#I think A* is probably fine for this, if the heuristic encodes the cost of an overall angle of approach that makes it hard to "alternate directions"
# (That is: since we have to move 1 orthogonally for every 3 down, at least, paths which are "straight down" actually cost more since we have to go
#                                                                                                                   3 down, 1 left, 1 right [total cost 5]

d = read("input");
width = findfirst(==(UInt8('\n')), d);
matrix = (reshape(d, width, :)[begin:end-1, :]) .- UInt8('0');
println("$(size(matrix))")
bounds= size(matrix)
goal = CartesianIndex(bounds) #that's the last coordinate, so!


CI(x,y) = CartesianIndex((x,y))

dir_to_num = Dict([CI(0,1)=>1, CI(0,-1)=>2, CI(1,0)=>3, CI(-1,0)=>4]);
num_to_dir = [CI(0,1), CI(0,-1), CI(1,0), CI(-1,0)];


struct cell_data
    c::CartesianIndex{2} #the cell itself
    dir::Int
    count::Int #its history - how it was got to, and how many successive moves 
end


#note: check this is 1/3 and not 1/4 - the example shows chains of 4 squares in a row from 3 *movements* 
#           if 1/4 then 3->4 , 5*x÷3 -> (1 + 1/4 + 1/4) = 3*x÷2 ? 
""" h(posn)

    Return a suitable heuristic for the remaining distance (encoding the "no more than 3 steps in a straight line" rule)
""" 
function h(posn::cell_data)
    #improvement - use movehist to tweak this estimate (only really significant for short distances where it matters if we can't move 3 in one dir in one go)
    #return 0 # try with Dijkstra - okay, so the problem isn't h 
    d = goal - posn.c;
    #return d[1]+d[2]
    d == CI(0,0) && return 0
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
function accessible(c)
    #                       yes 4, thanks Julia for indexing at 1
    notaccessible = c.count == 3 ? [num_to_dir[c.dir], num_to_dir[c.dir]*-1] : [num_to_dir[c.dir]*-1]
    p = setdiff(possibles, notaccessible)
    filter(p) do pp 
        checkbounds(Bool, matrix, c.c+pp)
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

    prev = Dict{cell_data, cell_data}() #dictionary of previous points
    s_cell = cell_data(s, 1, 1); #count 1 == 0 really (thanks Julia!)

    #state space is [dir, amount] for each [location] - I really want to do this with a sparse DefaultDict or something but those seem slow
    goalscore = [ [typemax(1) for i in 1:4, j in 1:4] for k in 1:bounds[1], l in 1:bounds[2] ]  #cost s -> cell
    goalscore[s][1,1] = 0 #zero cost to not move at all!



    #not having this around seems to make it slow (even though we only use it to look up score, which is already stored in the PQ)
    fscore = [ [typemax(1) for i in 1:4, j in 1:4] for k in 1:bounds[1], l in 1:bounds[2] ] 
    fscore[s][1,1] = h(s_cell) #and our best guess for s is just h at the moment 



    openset = PriorityQueue{cell_data, Int}(s_cell => fscore[s][1,1] ) #

    while !isempty(openset)

        #note, there's something *screwy* with the documentation for PriorityQueue - 
        # Docs claim popfirst! gives the pair K->V 
        # Julia claims popfirst! is not implemented for PriorityQueue [at least a v0.18.15] and I need to use dequeue! (which is supposed to be deprecate)
        # and only gives K not V !
        cursor = dequeue!(openset) #the highest priority (lowest "value") node
        score = fscore[cursor.c][cursor.dir, cursor.count]; 
        cursor.c == g #=we got there!=# && begin
                                                println("$(reconstruct_path(prev, cursor))"); 
                                                return score # the total cost! (I think fscore[cursor] == goalscore[cursor] at this point?)
                                        end 
        
        #evaluate neighbours of cursor = which means we need to store the direction we entered cursor from and how long we'd been moving in that direction
        for i in accessible(cursor)
            di = dir_to_num[i]
            cand = cell_data(cursor.c+i, di, cursor.dir == di ? cursor.count+1 : 1)
            trialgoalscore = goalscore[cursor.c][cursor.dir, cursor.count] + matrix[cand.c];
            if trialgoalscore < goalscore[cand.c][di, cand.count]
                prev[cand] = cursor 
                goalscore[cand.c][di,cand.count] = trialgoalscore
                
                fscore[cand.c][di,cand.count] = trialgoalscore + h(cand)
 
                openset[cand] = fscore[cand.c][di,cand.count]
                
            end
        end
    end 

    return typemax(1)
end

println("$(A✴(CartesianIndex((1,1)), goal))");


