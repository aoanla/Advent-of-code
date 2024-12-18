using DataStructures #for PriorityQueue

#this is another pathfinding == A🌟 problem

bounds = (71+2, 71+2) 
#bounds = (7+2,7+2) #allow for boundary
s = (2,2) #1,1 is top corner in Julia, and we also have a boundary of trues 
g = bounds .- (1,1) #inside the boundary of trues 

potentials = map(x->Tuple(parse.(Int64, split(x,","))) .+ (2,2), readlines("input")) #1 for Julia indexing, 1 for our boundary

function mkgrid(bounds, potentials, elems)
    grid = falses(bounds)
    grid[1,:] .= true 
    grid[end,:] .= true 
    grid[:,1] .= true 
    grid[:,end] .= true 
    for i ∈ potentials[1:elems] 
        grid[i...] = true
    end
    grid 
end

grid = mkgrid(bounds, potentials, 1024)


#print("$grid\n")

dirs = [(0,1),(1,0),(0,-1),(-1,0)]

accessible(coord, grid) = filter(c->grid[c...]!=true, map(x->coord.+x, dirs)) 
h(coord, goal) = sum((goal.-coord))

#A✴ algorithm from a 2023 puzzle so I don't need to sort it out properly again
function A✴(s, g, grid)

    prev = Dict{Tuple{Int64,Int64}, Tuple{Int64,Int64}}() #dictionary of previous points
    #s_cell = cell_data(s); #count 1 == 0 really (thanks Julia!)

    goalscore = fill(typemax(1), bounds)  #cost s -> cell
    goalscore[s...] = 0 #zero cost to not move at all!


    #not having this around seems to make it slow (even though we only use it to look up score, which is already stored in the PQ)
    fscore = fill(typemax(1), bounds)
    fscore[s...] = h(s,g) #and our best guess for s is just h at the moment 

    openset = PriorityQueue{Tuple{Int64,Int64}, Int}(s => fscore[s...]) #I don't actually need to keep the paths but...

    #Make
    cc = 0;
    while !isempty(openset)

            cursor = dequeue!(openset) #the highest priority (lowest "value") node
            cc += 1;

            score = fscore[cursor...]; 
            cursor == g #=we got there!=# && return score # the total cost! (I think fscore[cursor] == goalscore[cursor] at this point?)
                                            
            #evaluate neighbours of cursor = which means we need to store the direction we entered cursor from and how long we'd been moving in that direction
            for cand ∈ accessible(cursor,grid)
                trialgoalscore = goalscore[cursor...] + 1;
                if trialgoalscore < goalscore[cand...]
                    prev[cand] = cursor 
                    goalscore[cand...] = trialgoalscore
                
                    fscore[cand...] = trialgoalscore + h(cand,g)
 
                    openset[cand] = fscore[cand...]
                
                end
            end
        end 
    #end
    return typemax(1)
end

print("Pt1: A* = $(A✴(s,g, grid))\n")

#Pt2 - find the value of elems where we stop finding an exit.
#       this is a simple binary search, bounded by 1024 at the lower point, and length(potentials) at the top end 

function bin_search(potentials, bounds)
    max_ = length(potentials)
    min_ = 1 #1024
    while max_ - min_ > 1
        test = (max_ + min_) ÷ 2
        grid = mkgrid(bounds, potentials, test)
        if A✴(s,g, grid) == typemax(1) #failure 
            max_ = test 
        else
            min_ = test 
        end 
    end 
    max_
end

pt2 = bin_search(potentials, bounds)

print("First blocker at $pt2 , $(potentials[pt2].-(2,2))\n") #remembering to correct for our internal grid offsets