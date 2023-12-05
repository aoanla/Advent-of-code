
#part 1
using Base.Iterators

struct Lookup 
    dest_s::Int64
    dest_e::Int64
    source_s::Int64
    source_e::Int64
    len::Int64
    offset::Int64 #what you need to add to a value in source to get dest value
end



(seeds, map_vec) =open("input") do f   
        f_iter = Iterators.Stateful(eachline(f));

        seeds = sort(parse.(Int64, split(popfirst!(f_iter)[8:end], ' ')))
        popfirst!(f_iter); #whitespace

        #map_dict = Dict{String, Vector{Lookup}}();
        map_vec = Vector{Vector{Lookup}}(); #dict is slow and we can just order her
        while ! isempty(f_iter)
            v = Vector{Lookup}();
            popfirst!(f_iter); #name
            #map_name = split(popfirst!(f_iter),' ')[1];
            #push!(map_vec,map_name); #for order sequencing
            for line in f_iter
                isempty(line) && break ;
                (dest,source,len) = parse.(Int64,split(line,' '));
                push!(v, Lookup(dest,dest+len-1, source,source+len-1,len, dest-source));
            end
            push!(map_vec,sort(v, by=x->x.source_e));
        end
    (seeds,map_vec)    
end

"""
    apply_lookup(val, lookups)
"""
function apply_lookup(v, aton)
    for l in aton
        v >= l.source_s && v <= l.source_e && return v+l.offset
    end
    v
end

final_locations = foldl(map_vec; init=seeds) do s,m
    sort(map(ss -> apply_lookup(ss,m),s))
end

println("$(minimum(final_locations))")
#=

"""
    reduce_lookups(first, second)

    Takes two vectors of lookup tables a->b, b->c and produces a coalesed a->c table
    Needs to split ranges
    Possible cases:
    a->b entirely within b->c range => [b->c][a->b.b->c][b->c] , can stop checking a->b now
    b->c entirely within a->b range => [a->b][a->b.b->c][a->b] , need to replace a->b with split pair for remaining search
    a->b starts before but ends within b->c => [a->b][a->b.b->c][b->c] , need to replace a->b with truncated left for remaining search
    a->b starts within but ends after b->c => [b->c][a->b.b->c][a->b] , need to replace a->b with truncated right for remaining search
    * and add "remainder" of [a->b] to mapping at the end (if no intersections, this will be the original a->b mapping)
"""
function reduce_lookups(atob, btoc) 
    atob_ = deepcopy(atob); #need to modify recursively
    btoc_ = deepcopy(btoc)
    for l in atob
        for ll in btoc
            

    end

seed_to_location = reduce(reduce_lookups,map_vec)

minimum(apply_lookup.(seeds,seed_to_location))

=#