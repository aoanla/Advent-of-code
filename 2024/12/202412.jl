#this is a "trace the boundary" problem 
#probably it's most efficient to trace the edges ("add in 'edge dir' whilst different cells still in 'boundary dir'")
# because I am sure there's going to be some silly pt2

function parse_input(input_)
    grid = reduce(hcat, collect.('.'.*collect(readlines(input_)).*'.'))
    l = length(grid[:,1])
    dots = fill('.', l)
    [dots ;; grid ;; dots ]  #grid with 1 unit padding around each side for ease of scanning without boundary checks
end

grid = parse_input("input")
#print("$grid\n")

dirs = [(1,0), (-1,0), (0,1), (0,-1)]

function parse_grid(grid)
    limits = size(grid) .- 1  #avoid boundary
    clustermap = similar(grid, Tuple{Int64,Tuple{Int64,Int64,Int64,Int64}}) #cell-by-cell map of cluster id, edge memberships - hmm, up to 4 edges per cell actually...
    fill!(clustermap, (0,(0,0,0,0)))
    clusters = Vector{Set{Tuple{Int64,Int64}}}() #vector of sets of points in a cluster 
    edge_list = Vector{Set{Tuple{Int64,Int64}}}() #vector of sets of points in an edge 
    cluster_edges = Vector{Set{Int64}}() #vector of edges in a cluster 
    next_cluster = 1
    next_edge = 1
    for i ∈ 2:first(limits), j ∈ 2:last(limits)  #rightmost changes most rapidly
        #coord = (j,i)
        symbol = grid[j,i]
        this_cluster = 1
        (left,top) = (false, false)  #directions we're connected 
        if symbol == grid[j-1,i] #then we're in the same block as the previous cells
            left = true
            #add this coord to the cluster
            this_cluster = first(clustermap[j-1,i])
            clusters[this_cluster] = clusters[this_cluster] ∪ [(j,i)]
        end    
        if symbol == grid[j,i-1] #then we're touching the same block "above" (which may have just been connected by us)
            top = true
            top_cluster = first(clustermap[j,i-1])
            #check if top coord is in a previously "different" cluster that we've just connected & resolve 
            if ( left && top_cluster != this_cluster)
                #join them, by rewriting top cluster 
                cluster_edges[this_cluster] = cluster_edges[this_cluster] ∪ cluster_edges[top_cluster]
                clusters[this_cluster] = clusters[this_cluster] ∪ clusters[top_cluster]
                foreach(clusters[top_cluster]) do ij
                    clustermap[ij...] = (this_cluster, last(clustermap[ij...]))
                end
                clusters[top_cluster] = Set{Tuple{Int64,Int64}}() #zero out the cluster we're merging 
            elseif !left #we can just join cluster 
                #add this coord to the cluster
                this_cluster = top_cluster
                clusters[this_cluster] = clusters[this_cluster] ∪ [(j,i)]
            end 
        end 
        if !left && !top
            #make new cluster
            this_cluster = next_cluster 
            next_cluster += 1
            push!(clusters, Set([(j,i)]))
            push!(cluster_edges, Set([]))
        end     
        #edge detection
        these_edges = [0,0,0,0]
        edges = filter(x->grid[(dirs[x].+(j,i))...]!=symbol, 1:4)
        for edge ∈ edges #try to join up with "existing" edges in that orientation left or top
            if edge > 2  #horizontal edge (boundary on moving up or down)
                if left == true && last(clustermap[j-1, i])[edge] != 0
                    these_edges[edge] = last(clustermap[j-1,i])[edge]
                    edge_list[these_edges[edge]] = edge_list[these_edges[edge]] ∪ [(j,i)]
                else
                    these_edges[edge] = next_edge
                    next_edge += 1
                    push!(edge_list, Set([(j,i)]))
                end 
            else #edge < 3
                if top == true && last(clustermap[j, i-1])[edge] != 0#vertical edge (boundary on moving left or right)
                    these_edges[edge] = last(clustermap[j,i-1])[edge] 
                    edge_list[these_edges[edge]] = edge_list[these_edges[edge]] ∪ [(j,i)]
                else
                    these_edges[edge] = next_edge
                    next_edge += 1
                    push!(edge_list, Set([(j,i)]))
                end
            end
        end
        cluster_edges[this_cluster] = cluster_edges[this_cluster] ∪ filter(!=(0), these_edges)
        clustermap[j,i] = (this_cluster, Tuple(these_edges))
    end
    filt = map(x->length(x)>0,clusters)
    clusters_ = clusters[filt]
    cluster_edges_ = cluster_edges[filt]
    (clusters_,cluster_edges_, edge_list)
end

(c, c_e, e_l) = parse_grid(grid)

price(i,c,c_e,e_l) = length(c[i]) * mapreduce(e->length(e_l[e]),+,collect(c_e[i]))


prices = map(x->price(x,c,c_e,e_l), first(axes(c)))

print("\t pt1 sum is $(sum(prices))\n")

price2(i,c,c_e) = length(c[i]) * length(c_e[i])

prices2 = map(x->price2(x,c,c_e), first(axes(c)))

print("\t pt2 sum is $(sum(prices2))\n")