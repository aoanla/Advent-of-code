
#part 1
using Base.Iterators

struct Lookup 
    dest_s::Int64
    dest_e::Int64
    source_s::Int64
    source_e::Int64
    offset::Int64 #what you need to add to a value in source to get dest value
end

struct SeedRange
    s::Int64
    e::Int64
end


(seeds, seed_r, map_vec) =open("input") do f   
        f_iter = Iterators.Stateful(eachline(f)); 
        seeds = parse.(Int64, split(popfirst!(f_iter)[8:end], ' '))
        
        #part 2 seed ranges
        seed_r = sort(map(sr-> SeedRange(sr[1],sr[1]+sr[2]-1), collect(partition(seeds,2))), by=x->x.s)

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
                push!(v, Lookup(dest,dest+len-1, source,source+len-1,dest-source));
            end
            push!(map_vec,sort(v, by=x->x.source_e));
        end
    (seeds,seed_r, map_vec)    
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

"""
    reduce_range(v_range, lookups)
    Apply the lookup to the range list, splitting as necessary
    DESTRUCTIVE to all inputs
    Assumes inputs are sorted by their "source" ranges
"""
function reduce_range!(v_range, lookups)
    out = Vector{SeedRange}();
    while !isempty(v_range) 

        if isempty(lookups) #we consumed all the lookups already
            append!(out,v_range) ;#so just dump the rest of our input into out and break
            break;
        end

        vr = popfirst!(v_range);
        while !isempty(lookups)
            l = popfirst!(lookups);
            if vr.e < l.source_s #vr is early so we push l back, push vr to the output and break for a new vr which might intersect l
                push!(out,vr);
                pushfirst!(lookups,l);
                break;
            end
            if vr.e <= l.source_e #vr intersects with l to the left    #OFFSET ERROR HERE SOMEWHERE
                if vr.s < l.source_s # [aa[xx]bb]
                    push!(out, SeedRange(vr.s, l.source_s-1)); #left of the intersection is kept in this case
                end # [b[xx]b] *works*
                push!(out, SeedRange(vr.s+l.offset, vr.e+l.offset)) ;#the intersection is kept
                vr.e != l.source_e && pushfirst!(lookups, Lookup(vr.e+1+l.offset, l.dest_e, vr.e+1, l.source_e, l.offset)) ;#the remainder of l is pushed back
                break; #because vr is consumed entirely and we need to repop
            end
            if vr.s <= l.source_e #vr intersects with l to the right, including containing l entirely 
                if vr.s < l.source_s #vr contains l
                    push!(out, SeedRange(vr.s, l.source_s-1)); #the left of vr
                end
                push!(out, SeedRange(vr.s+l.offset, l.dest_e)); #the intersection  - *works*
                vr = SeedRange(l.source_e+1, vr.e) #the right *works*
            end
            #if we're here then vr > l
            isempty(lookups) && pushfirst!(v_range,vr) #push back the vr so it gets picked up in next loop in the big addition    
        end
                    
    end
    sort(out, by=x->x.s)
end

final_locations = foldl(map_vec; init=seeds) do s,m
    sort(map(ss -> apply_lookup(ss,m),s))
end

println("$(minimum(final_locations))");

loc_ranges = map(x->x.s,foldl(reduce_range!, map_vec; init=seed_r));

println("$(minimum(loc_ranges))");

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