#this is the minimum-cut problem, with the advantage that we are given the size of the cut (3)
# which is often the hardest part (determining if the cut is minimal)

# IIRC, this is Karger's algorithm - which is probabalistic but since we *know* the cut size we can make it deterministic by repeating until k = 3

#make this a bit easier by allowing "conflated nodes" to just be a Set of nodes - so the base nodes are just a 1 elem Set of nodes

NODE = String

node_list, adj_matrix = open("input") do f
    ns = Set{NODE}()
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

edges(a_m) = collect(Iterators.flatten(map(collect(pairs(a_m))) do p
    k,v=p
    [(k,vv) for vv ∈ v]
end ) )

#Karger's algorithm

function contract(nodes, a_m)
    ns = deepcopy(nodes)
    am = deepcopy(a_m)

    while length(ns) > 2
        k = rand(edges(am))
        k_n = k[1] * k[2]
        #remove k from ns, am by contraction
        pop!(ns, k[1])
        pop!(ns, k[2])
        push!(ns, k_n)
        k_nlist =  union(am[k[1]], am[k[2]])
        pop!(k_nlist, k[1])
        pop!(k_nlist, k[2])
        pop!(am, k[1])
        pop!(am, k[2])
        for kk ∈ k_nlist
            if k[1] ∈ am[kk]
                pop!(am[kk],k[1])
            end
            if k[2] ∈ am[kk]
                pop!(am[kk], k[2])
            end
            push!(am[kk], k_n)
        end
        am[k_n] = k_nlist
    end 
    setA,setB = values(ns)
    #println("$setA $setB")
    nodes_a = String.(collect(Iterators.partition(setA, 3)))
    nodes_b = Set(String.(collect(Iterators.partition(setB, 3))))
    cuts = []
    len = 0
    #println("$(keys(a_m))")
    for node ∈ nodes_a
        nodebs = (a_m[node] ∩ nodes_b)
        len += length(nodebs)
        #for nb ∈ nodebs
        #    push!(cuts,(node, nb))
        #end
    end
    res = length(setA)*length(setB) // 9

   (len, res)     
end

n = 99
res = 0;
while n != 3
    #println("Trying a cut!")
    global n, res = contract(node_list, adj_matrix)
end 
print("$res")