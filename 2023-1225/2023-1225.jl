#this is the minimum-cut problem, with the advantage that we are given the size of the cut (3)
# which is often the hardest part (determining if the cut is minimal)

# IIRC, this is Karger's algorithm - which is probabalistic but since we *know* the cut size we can make it deterministic by repeating until k = 3

#make this a bit easier by allowing "conflated nodes" to just be a Set of nodes - so the base nodes are just a 1 elem Set of nodes

NODE = String

node_list, adj_matrix = open("input2") do f
    ns = NODE[]
    adj_matrix = Dict{NODE, Set{NODE}}()
    for line ∈ readlines(f)
        node, nodes = split(line, ": ")
        node = String(node)
        nodes = split(nodes, " ")
        push!(ns, node)
        if !haskey(adj_matrix, node)
            adj_matrix[node] = Set{NODE}()
        end
        for n ∈ nodes
            n_s = String(n)
            if n_s ∉ ns 
                push!(ns, n_s)
                adj_matrix[n_s] = Set{NODE}()
            end
            push!(adj_matrix[n_s], node)
            push!(adj_matrix[node], n_s)
        end
    end
    (ns, adj_matrix)
end

#EDGE = Set{NODE}
size = length(ns)

#min_cut_phase 
function min_cut_phase(ns, adj_matrix)
    A = a node in ns
    if length(A) != size
        #find most densely connected vertex to nodes in A 
        for nn in setdiff(ns, A) #nodes not in A 
            weight = sum( adj_matrix[nn]     )

function stoer_wagner(ns, adj_matrix)
    ns_ = deepcopy(ns)
    adj_matrix_ = deepcopy(adj_matrix)
    edges_ = deepcopy(edges)


    
end

n = 99
cuts = Set();
#while n != 3
    println("Trying a cut!")
    global n, cuts = contract(node_list, adj_matrix,edges)
#end 
print("$cuts")