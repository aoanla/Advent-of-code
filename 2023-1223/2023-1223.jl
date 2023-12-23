#This is the longest path problem on a DAG, with the main problem being parsing the DAG
#DAG nodes are . with <>^v adjacent to them orthogonally. We can follow > to another > into another node. 
# (weight is obv. "# of .s", remembering that we also need to count the >^v< and the node's dot itself [which we'll count on the edges *out* from that node])

#Then topological sort and linear time longest path.

Nodes = Set{CartesianIndex{2}}()
                #out                    in              len
Edges = Dict{CartesianIndex{2}, Set{Tuple{CartesianIndex{2}, Int}}}()
            #in                         out                 len
InEdges = Dict{CartesianIndex{2}, Set{Tuple{CartesianIndex{2}, Int}}}()

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


function build_graph!(Nodes, Edges, InEdges)
    nodes_q = CartesianIndex{2}[]
    exit_node = nothing
    start = CartesianIndex((1,2))
    push!(Nodes, start)
    Edges[start] = Set{Tuple{CartesianIndex{2},Int}}()
    first_node_entry, dist, _ = follow_line(start, setdiff(dirs, Set([ch_to_dir[up]])))
    first_node = first_node_entry + ch_to_dir[matrix[first_node_entry]]
    push!(nodes_q, first_node)
    push!(Edges[start], (first_node, dist -1) ) #S doesn't count as a step apparently

    while !isempty(nodes_q)
        new_node = pop!(nodes_q)

        new_node ∈ Nodes && continue ; #already processed

        push!(Nodes, new_node) 
        #we only explore *outbound* edges - the map returns us (first dot after an outbound, outbound_directions) tuples
        out_nodes = map(d->(new_node + 2d, setdiff(dirs, Set([-d]))), collect(filter(d->is_outbound(matrix[new_node+d], d), dirs)) )
        Edges[new_node] = Set{Tuple{CartesianIndex{2}, Int}}()
        for on in out_nodes 
            end_node_entry, dist, exit_n = follow_line(on...) 
            if exit_n #we found the exit
                exit_node = end_node_entry 
                push!(Nodes, exit_node)
                push!(Edges[new_node], (exit_node, dist+2))
                Edges[exit_node] = Set{Tuple{CartesianIndex{2}, Int}}()
                continue #the exit has no exits... 
            end
            #normal node
            end_node = end_node_entry + ch_to_dir[matrix[end_node_entry]]
            push!(Edges[new_node], (end_node, dist+2)) #dist +2 because we include the . on new node and the outbound >^v<
            #if the node we found hasn't been traced yet, add it to the queue
            end_node ∉ Nodes && push!(nodes_q, end_node) ;
            
        end
    end

    for (out_v,v) ∈ pairs(Edges)
        for (in_v,dist) ∈ v
            if !haskey(InEdges, in_v)
                InEdges[in_v] = Set{Tuple{CartesianIndex{2},Int}}()
            end
            push!(InEdges[in_v], (out_v, dist))
        end
    end
    

    exit_node
end

e_node = build_graph!(Nodes, Edges, InEdges) 

#=
println("Nodes: $Nodes")
println("")
println("Edges: $Edges")
println("")
println("Exit: $e_node")
=#

#topo visit
function topo_visit(v, mark_set, tmp_mark_set, sorted_vec)
    v ∈ mark_set && return true
    v ∈ tmp_mark_set && return false #loop!

    push!(tmp_mark_set, v)
    for (vv, _) ∈ Edges[v] 
        topo_visit(vv, mark_set, tmp_mark_set, sorted_vec)
    end

    pop!(tmp_mark_set, v)
    push!(mark_set, v)
    pushfirst!(sorted_vec, v)
    return true
end 


#topo sort 
function topo_sort!(Nodes, Edges)
    sorted_vec = CartesianIndex{2}[]
    mark_set = Set{CartesianIndex{2}}()
    tmp_mark_set = Set{CartesianIndex{2}}()
    while !isempty(Nodes)
        v = pop!(Nodes)
        topo_visit(v, mark_set, tmp_mark_set, sorted_vec)
    end
    Nodes = mark_set #we should have marked everything
    (Nodes, sorted_vec) #sorted nodes
end 

(Nodes, sorted) = topo_sort!(Nodes, Edges)

function longest_dist(start, sorted_nodes, Edges, exit_n)
    dists = Dict{CartesianIndex{2}, Int}()
    for k ∈ sorted_nodes
        dists[k] = 0
    end
    idx = findfirst(==(start), sorted_nodes)
    for u ∈ sorted_nodes[idx:end]
        for (v,d) ∈ Edges[u]
            if  dists[v] < dists[u]+d
                dists[v] = dists[u] + d 
            end
        end
    end
    dists[exit_n]
end 

println("$(longest_dist(start, sorted, Edges, e_node))")

println("Number of nodes: $(length(Nodes))")
    
