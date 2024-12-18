#this looks like just classic Dijkstra's algorithm (or A* if we're being fancy?), with just a wrinkle on distance calculation.
# as such I'm not sure how *interesting* this is.

#the key trick here is that each node (which is a "crossway") adds two nodes to the graph - a "left-right" node and an "up-down" node. The two are connected by 
# an edge of weight 1000 (the rotation weight). Obviously, lr and ud nodes connect then directly to the corresponding paths that form edges to other node pairs. 

#this of course includes the start node (which is an lr node (the Reindeer starts facing E), paired with a ud node
#                   and the end nodes (both lr and ud versions are valid end states)



#h will be the Metropolis distance between s and g, +1000 for the one 90° turn it would need
h(loc,g) = sum( (loc.-g)...) + 1000


possibles = Set([(0,1), (1,0), (0,-1), (-1,0) ]);

function accessible(c)
    
    p = setdiff(possibles, notaccessible)
    filter(p) do pp 
        checkbounds(Bool, matrix, c.c+pp) #not needed if we're in a boxed grid - notaccessible here will just id a boundary or something 
    end     
end


#this reconstructs *a* path (if there are multiple, it reconstructs the one we found first)
function reconstruct_path(prev, cursor)
    totalpath = [cursor]
    while cursor in keys(prev)
        cursor = prev[cursor]
        pushfirst!(totalpath, cursor)
    end
    totalpath
end


deltas = Dict([ (0,1)=>[( (0,1), 1), ((-1,0),1001), ((1,0), 1001) ], 
                (0,-1)=>[( (0,-1), 1), ((-1,0),1001), ((1,0), 1001) ],
                (1,0)=>[( (1,0), 1), ((0,-1),1001), ((0,1), 1001) ],
                (-1,0)=>[( (-1,0), 1), ((0,-1),1001), ((0,1), 1001) ],
])

free(cell, s, grid) = grid[(cell.+s)...] == "."

function measure_recursive_path(s_node,s_dir, grid)
    cost = 0
    (cell, dir) = (s_node[1].+s_dir, s_dir)
    possibles = filter(c->free(c,cell,grid), deltas[dir])
    while length(possibles) == 1 #still going along a line
        cost += possibles[1][2]
        dir = possibles[1][1]
        cell = cell .+ dir
    end 
    #if we get here, we're at a node (which is terminal, if len=0)
    node = (cell, dir[1]==0) #second component is orientation
    orthonode = (cell, dir[1]!=0) #the orthogonal node pair
    #check if node or orthonode already exists as a termination condition for a branch of this recursion
    #(avoiding loops)
    #else add_nodes(node, orthonode)
    add_edges(s_node, node, cost) #adds bidirectional edge here from start
    add_edges(node, orthonode, 1000)
    if dir ∈ possibles 
        measure_recursive_path(node, dir, grid)
    end
    for dir1 ∈ filter(!=(dir), possibles)
        measure_recursive_path(orthonode, dir1, grid)
    end
end

#A✴ algorithm from a 2023 puzzle so I don't need to sort it out properly again
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

    #Make
    cc = 0;
    while !isempty(openset)

            cursor = dequeue!(openset) #the highest priority (lowest "value") node
            cc += 1;

            score = fscore[cursor.c][cursor.dir, cursor.count]; 
            cursor.c == g #=we got there!=# && begin
                                                pth = reconstruct_path(prev, cursor);
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
    #end
    return typemax(1)
end
