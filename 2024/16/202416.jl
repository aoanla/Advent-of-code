#this looks like just classic Dijkstra's algorithm (or A* if we're being fancy?), with just a wrinkle on distance calculation.
# as such I'm not sure how *interesting* this is.

#the key trick here is that each node (which is a "crossway") adds two nodes to the graph - a "left-right" node and an "up-down" node. The two are connected by 
# an edge of weight 1000 (the rotation weight). Obviously, lr and ud nodes connect then directly to the corresponding paths that form edges to other node pairs. 

#this of course includes the start node (which is an lr node (the Reindeer starts facing E), paired with a ud node
#                   and the end nodes (both lr and ud versions are valid end states)
using DataStructures


map_ = readlines("input")
grid = map(!=('#'), reduce(vcat, permutedims.(collect.(map_))))
s = size(grid)

#the s and e are on opposite corners 
g_loc = (2,s[2]-1)
s_loc = (s[1]-1,2)
#s_e = Set(g_loc, s_loc)

print("Target = $g_loc\n")

struct Node 
    cell::Tuple{Int64,Int64}
    dir::Tuple{Int64,Int64}
end

#h will be the Metropolis distance between s and g, +1000 for the one 90° turn it would need
h(loc,g) = begin
    diff = abs.(loc.cell .- g.cell)
    sum(diff)
    #all(diff.!=0) ? 1000 : 0 #for the turn needed at some point to do x and y movement 
    #and then account for orientation relative to direction... 
    #sum((loc.cell.-g.cell)) + 1000 +  ( (loc.dir == (-1,0) || loc.dir == (0,1) ) ? 0 : 1000) #the extra turn needed if we're facing west or s
end
                 #  E     S
possibles = Set([(0,1), (1,0), (0,-1), (-1,0) ]);


#this reconstructs *a* path (if there are multiple, it reconstructs the one we found first)
#luckily, our E has only one possible approach [from the West], so we don't need to worry about reconstructing multiple cursors 
#we do need to worry about what we're storing - the original version of this stored breadcrumbs of cells, whilst here we need to store path_segments themselves
function reconstruct_path(prev, cursor)
    totalpath = Set([cursor]) #this isn't true now as when we start, we don't have a *segment* just a starting point 
    while cursor ∈ keys(prev)
        cursor_set = prev[cursor]

        pushfirst!(totalpath, cursor)
    end
    totalpath
end


deltas = Dict([ (0,1)=>[( (0,1), 1), ((-1,0),1001), ((1,0), 1001) ], 
                (0,-1)=>[( (0,-1), 1), ((-1,0),1001), ((1,0), 1001) ],
                (1,0)=>[( (1,0), 1), ((0,-1),1001), ((0,1), 1001) ],
                (-1,0)=>[( (-1,0), 1), ((0,-1),1001), ((0,1), 1001) ],
])

free(cell, s, grid) = grid[(cell.+s)...] #just store booleans! 


#I actually don't think I need to do this recursively, given that A✴ only ever cares about the next set of accessible nodes 
#this should actually be what *accessible* call gives - the list of nodes (and costs) accessible from s_node 
function accessible(s_node, grid, s_e)
    nodes = Vector{Tuple{Node, Int64}}()
    #turning left or right
    lr = deltas[s_node.dir]
    push!(nodes, ( Node(s_node.cell, lr[2][1]), 1000) ) #left turn 
    push!(nodes, ( Node(s_node.cell, lr[3][1]), 1000) ) #right turn 

    #straight ahead:  - check we don't bump into something immediately (in which case this isn't possible)
    if free(s_node.cell, s_node.dir, grid)
        cost = 1 #cost to leave first cell 
        (cell, dir) = (s_node.cell.+s_node.dir, s_node.dir)
        possibles = filter(c->free(c[1],cell,grid), deltas[dir])
        while length(possibles) == 1 && cell ∉ s_e #still going along a line, didn't hit our S or E cells
            cost += possibles[1][2]
            dir = possibles[1][1]
            cell = cell .+ dir
            possibles = filter(c->free(c[1],cell,grid), deltas[dir])
            #ell[2] > 10 && exit()
        end 
        #if we get here, we're at a node - we *can* eliminate the node if length(possibles) == 0 *AND* cell ∉ s_e 
        ahead_node = Node(cell, dir) #second component is orientation
        push!(nodes, (ahead_node, cost))        
    end
    nodes     
end

s = Node(s_loc, (0,1))
g = Node(g_loc, (0,0)) #we actually don't care about the dir for g

#A✴ algorithm from a 2023 puzzle so I don't need to sort it out properly again
function A✴(s::Node, g::Node, grid)  #more than one end point, since we don't care about orientation when you arrive

    prev = Dict{Node, Set{Tuple{Node,Cost}}}() #dictionary of previous points, as sets

    #state space is dir for each location, as part of Node
    #in this case, the state space is much smaller, since it only contains nodes - this needs to be a map
    goalscore = Dict{Node, Int64}()  #cost s -> cell
    goalscore[s] = 0 #zero cost to not move at all!

    #not having this around seems to make it slow (even though we only use it to look up score, which is already stored in the PQ)
    fscore = Dict{Node, Int64}() 
    fscore[s] = h(s,g) #and our best guess for s is just h at the moment 

    s_e = Set([s.cell, g.cell])

    openset = PriorityQueue{Node, Int64}(s => fscore[s] ) #

    #Make
    cc = 0;
    while !isempty(openset)

            cursor = dequeue!(openset) #the highest priority (lowest "value") node
            cc += 1;

            score = fscore[cursor]; 
            cursor.cell == g.cell #=we got there!=# && begin
                                                #pth = reconstruct_path(prev, cursor);
                                                return score # the total cost! (I think fscore[cursor] == goalscore[cursor] at this point?)
                                            end 
        
            #evaluate neighbours of cursor = which means we need to store the direction we entered cursor
            for (cand,cost) ∈ accessible(cursor, grid, s_e)
                
                trialgoalscore = get(goalscore,cursor,typemax(1)) + cost;
                if trialgoalscore <= get(goalscore,cand,typemax(1))
                    prev[cand] = get(prev, cand, Set{Tuple{Node,Cost}}()) ∪ (cursor,cost)  #a cell can have several previous candidates, and we do need to store the costs
                    goalscore[cand] = trialgoalscore
                
                    fscore[cand] = trialgoalscore + h(cand, g)
 
                    openset[cand] = fscore[cand]
                
                end
            end
        end 
    #end
    return typemax(1)
end

print("$(A✴(s,g, grid))\n")


#Pt2 thoughts - Dijkstra, at least, *does* find multiple paths (because it identifies the distance to all possible nodes
#                                                                so you just need to trace back all "equally good" distances at each point)
# I think A✴ can also do this, if we don't just stop as soon as we find the goal?

#the number of tiles on any path segment is the cost of that path segment % 1000 (unless it's longer than 1000 cells long, which I doubt happens in a 139x139 maze)
#so, if we can find all the path segments on an optimal path, the number of tiles is just mapreduce(x->x%1000, +, cost_of_segments)