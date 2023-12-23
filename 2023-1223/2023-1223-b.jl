#This is the longest path problem on an Undirected Graph, with cycles broken by each edge being usable only once. 
#Nodes nodes are . with <>^v adjacent to them orthogonally. We can follow > to another > into another node. 
# (weight is obv. "# of .s", remembering that we also need to count the >^v< and the node's dot itself [which we'll count on the edges *out* from that node])

#Generally, the longest path problem on a general undirected graph is NP, and I can't see that this graph is *obviously* one of the special cases.
#We can probably prune out some nodes if they only have 2 edges (since that's the same as just an edge between those two nodes) to reduce the complexity?
#                       ^ do any such nodes exist? ^

#In the absence of a better idea, then, this is Dijkstra's Algorithm again but with the path state including the edge we entered each node from so we don't go back. 

using Pkg
Pkg.activate(".")
using DataStructures #I really don't to write my own PriorityQueue


#TODO: Dijkstra rather than [Toposort, DAG longest path]

Nodes = Set{CartesianIndex{2}}()
                #out                    in              len
Edges = Dict{CartesianIndex{2}, Dict{CartesianIndex{2}, Int}}()


d = read("input2")
width = findfirst(==(UInt8('\n')), d);
matrix = transpose(reshape(d, width, :)[begin:end-1, :]);

dot = UInt8('.')
hash = UInt8('#')
left = UInt8('<')
right = UInt8('>')
up = UInt8('^')
down = UInt8('v')

println("items: dot = $dot\nhash= $hash\nleft= $left, right =$right\nup =$up, down=$down")
dirs = Set{CartesianIndex{2}}(CartesianIndex.([(1,0),(0,1), (-1,0), (0,-1)]))

CI(x,y) = CartesianIndex((x,y))
ch_to_dir = Dict{UInt8, CartesianIndex{2}}([left=>CI(0,-1), right=>CI(0,1), up=>CI(-1,0), down=>CI(1,0), hash=>CI(0,0)])

is_outbound(x, from_dir) =  ch_to_dir[x] == from_dir #we're outbound if we point in the direction we entered from

#checking this is the start - lr is column (2nd) index
println("$(matrix[1,2] == dot)")

start = CartesianIndex((1,2))
pos_vectors = setdiff(dirs, Set(up)) #can't go up from start



function follow_line(here, pos_vectors)
    dist = 1
    exit_node = false 
    while matrix[here] == dot && !exit_node
        for cs ∈ pos_vectors         
            if !checkbounds(Bool, matrix, here+cs) #exit node - we're leaving the map
                exit_node = true
                break
            end
            if matrix[here+cs] != hash #destination - including any entry points to a node
                here += cs 
                pos_vectors = setdiff(dirs, Set([-cs])) #and don't consider going back next
                dist += 1
                break
            end
        end
    end
    (here, dist, exit_node) 
end


function build_graph!(Nodes, Edges)
    nodes_q = CartesianIndex{2}[]
    exit_node = nothing
    start = CartesianIndex((1,2))
    push!(Nodes, start)
    Edges[start] = Dict{CartesianIndex{2},Int}()
    first_node_entry, dist, _ = follow_line(start, setdiff(dirs, Set([ch_to_dir[up]])))
    first_node = first_node_entry + ch_to_dir[matrix[first_node_entry]]
    push!(nodes_q, first_node)
    Edges[start][first_node] = dist -1; #S doesn't count as a step apparently - also, this is still effectively one directional (we can't go "back" from this node)

    while !isempty(nodes_q)
        new_node = pop!(nodes_q)

        new_node ∈ Nodes && continue ; #already processed

        push!(Nodes, new_node) 
        #we only explore *outbound* edges - the map returns us (first dot after an outbound, outbound_directions) tuples
        #this is also fine for us with an undirected graph - it does simplify traversal logic a bit and we can just add the other direction as well 
        out_nodes = map(d->(new_node + 2d, setdiff(dirs, Set([-d]))), collect(filter(d->is_outbound(matrix[new_node+d], d), dirs)) )
        if !haskey(Edges, new_node) 
            Edges[new_node] = Dict{CartesianIndex{2}, Int}()
        end
        for on in out_nodes 
            end_node_entry, dist, exit_n = follow_line(on...) 
            if exit_n #we found the exit
                exit_node = end_node_entry 
                push!(Nodes, exit_node)
                Edges[new_node][exit_node] = dist+2
                Edges[exit_node] = Dict{CartesianIndex{2}, Int}()
                continue #the exit has no exits... 
            end
            #normal node
            end_node = end_node_entry + ch_to_dir[matrix[end_node_entry]]
            Edges[new_node][end_node] = dist+2; #dist +2 because we include the . on new node and the outbound >^v<
            if !haskey(Edges, end_node)
                Edges[end_node] = Dict{CartesianIndex{2}, Int}()
            end
            Edges[end_node][new_node] = dist+2;
            #if the node we found hasn't been traced yet, add it to the queue
            end_node ∉ Nodes && push!(nodes_q, end_node) ;
            
        end
    end
    exit_node
end

e_node = build_graph!(Nodes, Edges) 

#honestly, I can't see any edges that could be contracted... also there's only 36 nodes anyway!
#=
function contract_edges!(Edges)
    #find cases where a node has only two edges (to E1, E2), and replace the node and the edges with single edge E1->E2
        #!!!! could be problematic if an edge E1-E2 already exists!!!
    contractable = filter(p->length(p[2])==2, pairs(Edges) )
    while !isempty(contractable)
        for (k,v) ∈ contractable
            new_edges = keys(v)
            dist = sum(values(v)); #distance is the sum (dist to each from here)
            #delete old edges 
            #add new edge
        end
        contractable = filter(p->length(p[2])==2, pairs(Edges) )
        #try again incase now another node is contractable
    end 
end
=#

#=
println("Nodes: $Nodes")
println("")
println("Edges: $Edges")
println("")
println("Exit: $e_node")
=#

### TODO: Longest Path via Dijkstra . State vector is (NODE, FROMNODE) at any point because this also lets us remove that edge as state change

const EdgeDict = Dict{CartesianIndex{2}, Dict{CartesianIndex{2}, Int}}
const State = Tuple{CartesianIndex{2}, Dict{CartesianIndex{2}, Dict{CartesianIndex{2}, Int}} }

#OKAY, Dijkstra's memory bounds are awful, yess. Let's try UCS 
function longest_dist(start, Edges, exit_n)
    
    explored = Set{State}()
                                #node                       #available edges                                Distance
    front = PriorityQueue{State, Int}(Base.Order.Reverse)
    enqueue!(front, (start, Edges), 0 )
    while !isempty(front)
        state, s_dist = dequeue_pair!(front)
        state[1] == exit_n && return s_dist 
        push!(explored, state);

        #Edges   #from this node                 
        for (next_node,next_dist) ∈ pairs(state[2][state[1]] ) 
            cand_dist = s_dist + next_dist
            cand_edges = deepcopy(state[2]) #the edges for this candidate are removed as we go down them if we do this
            delete!(cand_edges[state[1]], next_node)
            delete!(cand_edges[next_node], state[1])
            cand_state = (next_node, cand_edges)
            cand_state ∈ explored && continue            
            if !haskey(front, cand_state) || front[cand_state] < cand_dist  
                front[cand_state] = cand_dist
            end
        end
    end
    nothing
end 

dists =  longest_dist(start, Edges, e_node )

                #the dist             #the node
#pttwo =  maximum(map(p->p[2], filter(p->p[1][1]==e_node, collect(pairs(dists))  ) )  )

println("$(dists)")


    
