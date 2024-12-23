#this is going to be a cliques one in pt2 I can feel it - Eric loves his cliques in graph theory questions
function parse_graph(file)
    edges = Dict{String, Set{String}}()
    nodes_ = Set{String}() #for easy insertion without worrying about dupes, then we can sort it later for the proper list 
    #ts = Set{String}() #the t nodes  
    for line ∈ readlines(file)  
        edge = split(line, "-")
        push!.(Ref(nodes_), edge)
        edges[first(edge)] = get(edges,first(edge), Set{String}()) ∪ [last(edge)]
        edges[last(edge)] = get(edges,last(edge), Set{String}()) ∪ [first(edge)] 
    end
    (nodes_, edges)
end  

(nodes_, edges) = parse_graph("input")
#
function get_triples(nodes_, edges)
    triples = Set{Tuple{String, String, String}}(())
    nodes = deepcopy(nodes_) 
    while length(nodes) > 0
        node = pop!(nodes)
        adj = edges[node] ∩ nodes  
        while length(adj) > 0 
            node_2 = pop!(adj)
            #this way we don't double count - we could also pop of course
            #for each edge, test the second node's edges for nodes with an edge with (first) node 
            for node_3 ∈ edges[node_2] ∩ adj
                node_3 ∈ adj && push!(triples, (node,node_2,node_3))
            end
        end
    end
    triples
end  


triples = get_triples(nodes_, edges)
#get ts
ttriples = filter(triples) do t
    map(x->first(x)=='t', t) |> any
end 

print("Pt1: $(length(ttriples))   = total nodes - $(length(nodes_)) \n")

#pt2 is the maximal clique problem which is well-known in graph theory. 
#technically, there's some complex algorithms for finding the specifically *maximum* maximal clique quickly, but this graph isn't huge so we 
# can probably afford to use Bron-Kerbosch and take max length clique

function BronKerbosch(R, P, X, edges)
    length(P) == 0 && length(X) == 0 && return(Set([R]))
    P = deepcopy(P)
    X = deepcopy(X)
    cliques = Set{Set{String}}()
    for v ∈ P 
        cliques = cliques ∪ BronKerbosch( R ∪ [v], P ∩ edges[v], X ∩ edges[v], edges)
        P = setdiff(P, [v])
        X = X ∪ [v]
    end 
    cliques
end

cliques = BronKerbosch(Set{String}(), nodes_, Set{String}(), edges)
output = argmax(x->length(x), collect(cliques)) |> collect |> sort |> Base.Fix2(join, ',')
print("Pt2: $output\n")