#this is a topological sorting task
#if we assume the topological ordering of the requirements graph is unique (it possibly is, given how long it is)
#then we can just toposort that (into a dict of k->position pairs) and then check each candidate vector is ordered according to the dict directly 

 input = read("input", String)

 (topo, lists) = split(input,"\n\n")
 topo = split(topo, '\n')
 lists = split(lists, '\n')

#function topo_sort!(nodes, inedges, startnodes_)
#    order = Dict{Int32, Int32}() #node -> order mapping
#    count_ = 1
#    while !isempty(startnodes_)
#        s = pop!(startnodes_)
#        order[s] = count_
#        count_+=1
#        if !haskey(nodes, s)
#            continue
#        end
#        for v ∈ nodes[s]
#            inedges[v] -= 1
#            if inedges[v] == 0
#                push!(startnodes_, v)
#            end
#        end
#    end
#    order
#end

 function parse_topo(topo)
    nodes = Dict{Int32,Set{Int32}}() #nodes
    for pair ∈ topo
        in_, out_ = parse.(Int32, split(pair,'|'))
        if haskey(nodes,in_)
            push!(nodes[in_],out_)
        else 
            nodes[in_] = Set(out_)
        end
    end
    nodes
end

function check_sort(list, nodes)
    #we need to get the subset of nodes in list and then topo_sort it and compare
    nodes_ = Dict{Int32, Set{Int32}}()
    inedges_ = Dict([li=>0 for li ∈ list])
    for li ∈ list
        if haskey(nodes,li)
            vals = nodes[li] ∩ list #can't count nodes that aren't in the list as dest
            for v ∈ vals
                inedges_[v] += 1
            end
            nodes_[li] = vals
        else
            nodes_[li] = Set{Int32}()
        end
    end
    for li ∈ list 
        inedges_[li] != 0 && return 0 #not a valid list, so contributes 0 
            #for pt2, we know the list was sorted up to the above point, so we only need to sort
            #the parts from this node onwards (and only until we get to the middle!)
        for v ∈ nodes_[li]
            inedges_[v] -= 1
        end
    end
    #this should now return a tuple of (alreadysorted,neededsorting) so we can sum over it properly with broadcasting
    return list[(length(list)+1)÷2]
end
        
function check_lists(lists,order)
    tot = 0
    for l ∈ lists
        ll = parse.(Int32, split(l,','))
        tot += check_sort(ll, nodes)
    end
    tot
end


nodes = parse_topo(topo)
#print("$ordering")
pt1 = check_lists(lists,nodes)
print("Pt1 = $pt1")
