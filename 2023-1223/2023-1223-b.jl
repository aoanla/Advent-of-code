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


d = read("input")
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
#
#
function contract_edges!(Edges)
    #find cases where a node has only two edges (to E1, E2), and replace the node and the edges with single edge E1->E2
        #!!!! could be problematic if an edge E1-E2 already exists!!!
    contractable = filter(p->length(p[2])==2, collect(pairs(Edges)) )
    println("Contracting: $contractable")
    while !isempty(contractable)
        for (k,v) ∈ contractable
            far_nodes = collect(keys(v))
            dist = sum(values(v)); #distance is the sum (dist to each from here)
            #delete old edges
            delete!(Edges[k], far_nodes[1])
            delete!(Edges[k], far_nodes[2])
            delete!(Edges[far_nodes[1]], k)
            delete!(Edges[far_nodes[2]], k)
            #add new edge
            Edges[far_nodes[1]][far_nodes[2]] = dist 
            Edges[far_nodes[2]][far_nodes[1]] = dist 
        end
        contractable = filter(p->length(p[2])==2, collect(pairs(Edges)) )
        #try again incase now another node is contractable
    end 
end
#

#okay, let's go for a more memory-efficient representation
Node_v = collect(values(Nodes))
v_Node = Dict{CartesianIndex{2}, Int}()
for (i,n) ∈ enumerate(Node_v)
    v_Node[n] = i
end
nNodes = length(Node_v)

Edge_i = zeros(UInt64, length(Node_v))

#contract_edges!(Edges);

#=
println("Nodes: $Nodes")
println("")
println("Edges: $Edges")
println("")
println("Exit: $e_node")
=#

### TODO: Longest Path via Dijkstra . State vector is (NODE, FROMNODE) at any point because this also lets us remove that edge as state change

#I think my state vector is too big - do I need to store the previous paths in such a big structure? Also, I think I should be able to use Dijkstra - 
# even though the first attempt used up all 16GB on my machine!
Edge_i = zeros(UInt64, length(Node_v))

const Edge_v = Tuple{CartesianIndex{2},CartesianIndex{2}}
const State = Tuple{Int8, BitArray{2}}

#OKAY, Dijkstra - nope, this does not fit into my RAM - does the state need to store this stuff?
function longest_dist(start, Edges, exit_n)
    
    dist = Dict{State,Int}()
    soln = 0
                                #node                       #available edges                                Distance
    queue = PriorityQueue{State, Int}(Base.Order.Reverse)
    enqueue!(queue, (v_Node[start], trues(nNodes,nNodes)), 0 )

    while !isempty(queue)  #keep going until we can't get a better soln from a candidate on the front
        state, s_dist = dequeue_pair!(queue)

        #Edges   #from this node                 
        for next_node ∈ filter(x->state[2][state[1],v_Node[x]], keys(Edges[Node_v[state[1]]]) ) #can't take already taken edges
            #println("\tCandidate: $next_node")
            cand_dist = s_dist + Edges[Node_v[state[1]]][next_node]
            cand_edges = deepcopy(state[2])
            cand_edges[state[1],v_Node[next_node]] = false
            cand_edges[v_Node[next_node],state[1]] = false
            cand_state = (v_Node[next_node], cand_edges)
            #println("State: $cand_state")
            if !haskey(dist, cand_state) || dist[cand_state] < cand_dist
                dist[cand_state] = cand_dist 
                queue[cand_state] = cand_dist
                if next_node == exit_n && soln < cand_dist 
                    soln = cand_dist
                end
            end
        end
    end
    soln
end 
#        state[1] == exit_n && return s_dist 
#        push!(explored, state);


dists =  longest_dist(start, Edges, e_node )

                #the dist             #the node
#pttwo =  maximum(map(p->p[2], filter(p->p[1][1]==e_node, collect(pairs(dists))  ) )  )

println("$(dists)")


    
