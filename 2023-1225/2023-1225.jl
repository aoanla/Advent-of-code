#this is the minimum-cut problem, with the advantage that we are given the size of the cut (3)
# which is often the hardest part (determining if the cut is minimal)

# IIRC, this is Karger's algorithm - which is probabalistic but since we *know* the cut size we can make it deterministic by repeating until k = 3

#make this a bit easier by allowing "conflated nodes" to just be a Set of nodes - so the base nodes are just a 1 elem Set of nodes

NODE = Set{String}

node_list, adj_matrix = open("input2") do f
    ns = Set{NODE}()
    adj_matrix = Dict{NODE, Set{NODE}}()
    for line ∈ readlines(f)
        node, nodes = split(line, ": ")
        node = Set([String(node)])
        nodes = split(nodes, " ")
        push!(ns, node)
        if !haskey(adj_matrix, node)
            adj_matrix[node] = Set{NODE}()
        end
        for n ∈ nodes
            n_s = Set([String(n)])
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

EDGE = Set{NODE}

edges = Set{EDGE}()
for n1 ∈ keys(adj_matrix)
    for n2 ∈ adj_matrix[n1]
        push!(edges, Set([n1,n2]))
    end
end

#okay, there's some serious weirdness going on here with "isdisjoint"
function contract(ns, adj_matrix, edges)
    ns_ = deepcopy(ns)
    adj_matrix_ = deepcopy(adj_matrix)
    edges_ = deepcopy(edges)

    while length(ns_) > 2
        #println("nodes: $(ns_)")
        #println("Length is $(length(ns_))")
        #println("Remaining edges: $edges_")
        #randomly pick an edge:
        e = rand(edges_)
        #println("Remove $e")
        e_n = Set(Iterators.flatten(e)) #new e is the set of all the "nodes" in it
        #contract it 
        pop!(edges_, e)
        #also pop all other edges_ where ei are one part of the edge, *and* update the edges to point at e!
        for ee ∈ edges_
            isdisjoint(ee,e) && continue #<--- this is apparently not reliable, as I get cases where ee *is not* disjoint to e and we still trigger this.
            println("in edge removal: $ee is not disjoined to $e - en is $e_n")
            pop!(edges_, ee)
            #update!
            println("popped: $ee")
            push!(edges_, union(setdiff(ee, e), Set([e_n])))
            println("pushed: $(union(setdiff(ee, e), Set([e_n])))")            
        end  
        println("new list: $edges_")    
        tmp = Set{NODE}() 
        for ei ∈ e
            #println("ei is $ei")
        #    println("Nodes before: $ns_")
            pop!(ns_, ei) #<----- this isn't ever popping anything?
        #    println("Popped $ei")
        #    println("Nodes after: $ns_")
            union!(tmp, adj_matrix_[ei])
        end
        push!(ns_, e_n)
        #println("Nodes final: $ns_")
        adj_matrix_[e_n] = setdiff!(tmp, e)
        for n ∈ adj_matrix_[e_n] #and update the nodes we point to to point to e_n
            setdiff!(adj_matrix_[n], e) #remove the nodes separately (relying on setdiff's 2nd arg to be a *set* of items to remove)
            push!(adj_matrix_[n], e_n) #and add as a combined node (relying on push operating on a single "item")
        end
    end 
    
    count = 1
    cut_list = EDGE[]
    #get the size of this cut:
    nodes = collect(values(ns_))
    for n ∈ nodes[begin] #we only have two "nodes" so just pick one as our thing to find connections from
        n_set = Set([n])
        for other_ns ∈ nodes[end]
            if n_set ∈ adj_matrix[Set([other_ns])]
                count+=1
                push!(cut_list, Set([n_set, Set([other_ns])])) 
            end
        end
    end
    println("count = $count, edgelist is $cut_list")
    (count, cut_list)
end

n = 99
cuts = Set();
#while n != 3
    println("Trying a cut!")
    global n, cuts = contract(node_list, adj_matrix,edges)
#end 
print("$cuts")