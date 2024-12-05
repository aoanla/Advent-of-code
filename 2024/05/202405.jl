#this is a topological sorting task
#if we assume the topological ordering of the requirements graph is unique (it possibly is, given how long it is)
#then we can just toposort that (into a dict of k->position pairs) and then check each candidate vector is ordered according to the dict directly 

 input = read("input", String)

 (topo, lists) = split(input,"\n\n")
 topo = split(topo, '\n')
 lists = split(lists, '\n')

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
    mid = (length(list)+1)÷2
    val = -1
    for (n,li) ∈ enumerate(list) 
        #not a valid list, so contributes 0
        if inedges_[li] != 0 
            val != -1 && return [0,val] #already found the midpoint and know this isn't fully sorted so can return early  
            #otherwise, sort the list until we get to the midpoint, starting from correct entry
            elems = Set(list[n:end])
            tops = filter(li->inedges_[li]==0,elems)
            while !isempty(tops) 
                li_ = pop!(tops)
                n == mid && return  [0,li_] #early return
                for v ∈ nodes_[li_]
                    inedges_[v] -= 1
                    inedges_[v] == 0 && push!(tops, v) #we can probably assume for this that tops is always 1 element in size and just assign to var, but this is robust
                end
                n+=1
            end
        end
        for v ∈ nodes_[li]
            inedges_[v] -= 1
        end
        if n == mid 
            val = li #we found our 
        end
    end
    #this should now return a tuple of (alreadysorted,neededsorting) so we can sum over it properly with broadcasting
    return [val,0]
end
        
function check_lists(lists,order)
    tot = [0,0]
    for l ∈ lists
        ll = parse.(Int32, split(l,','))
        tot .+= check_sort(ll, nodes)
    end
    tot
end


nodes = parse_topo(topo)
#print("$ordering")
pt1 = check_lists(lists,nodes)
print("Pt1,Pt2 = $pt1")
