#this is going to be a cliques one in pt2 I can feel it - Eric loves his cliques in graph theory questions

edges = Dict{String, Set{String}}()
nodes_ = Set{String}() #for easy insertion without worrying about dupes, then we can sort it later for the proper list 
ts = Set{String}() #the t nodes 

#parse 

triples = Set{Tuple{String, String, String}}(())
nodes = sort(collect(nodes_)) 
for i,node ∈ enumerate(nodes)
    adj = sort(collect(edges[node]))
    for node_2 ∈ adj #this way we don't double count - we could also pop of course
        #for each edge, test the second node's edges for nodes with an edge with (first) node 
        for node_3 ∈ edges[node_2]
            node_3 ∈ adj && push!(triples, (node,node_2,node_3))
        end
    end
end 

#get ts
filter(triples) do t
    map(x->first[x]=='t', t) |> any
end 