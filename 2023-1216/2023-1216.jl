

d = read("input");

#items, fun with Unicode
nl = UInt8('\n')
⮀ = UInt8('-')
⮁ = UInt8('|')
⬛ = UInt8('.')
◿ = UInt8('/')
◺ = UInt8('\\')

width = findfirst(==(nl), d);
matrix = reshape(d, width, :)[begin:end-1, :];


bounds = size(matrix)
println("$bounds")



#bitmatrix = falses(bounds); #litness
#first dimension is lr
#second is ud

u = (Int8(0),Int8(-1))
d = (Int8(0), Int8(1))
l = (Int8(-1), Int8(0))
r = (Int8(1),Int8(0))
ud(x) = x[1] == Int8(0)
lr(x) = x[2] == Int8(0)

trans◿(entrydir) = [(-entrydir[2], -entrydir[1])]
trans◺(entrydir) = [(entrydir[2], entrydir[1])]
trans⬛(entrydir) = [entrydir]
trans⮁(entrydir) = ud(entrydir) ? [entrydir] : [u, d]
trans⮀(entrydir) = lr(entrydir) ? [entrydir] : [l,r]

transform = Dict( [
        (⮀ => trans⮀),
        (⮁ => trans⮁),
        (⬛ => trans⬛),
        (◿ => trans◿),
        (◺ => trans◺)        ]);

#memoisation dict just in case we need it (pos, dir) -> litmap (now a set of lit points)
memo = Dict{Tuple{Tuple{Int8,Int8}, Tuple{Int8,Int8}}, Set{Tuple{Int8, Int8}}}()

#splitter memoisation dicts for exit/entry points 
                         #splitter pos, dir                      #exit/entry point in edge
splitter_memo = Dict{Tuple{Tuple{Int8,Int8}, Tuple{Int8,Int8}}, Tuple{Int8, Int8}}()
                        #exit/entry point          #splitter pos, dir
rev_splitter_memo = Dict{Tuple{Int8,Int8}, Tuple{Tuple{Int8,Int8}, Tuple{Int8, Int8}}}()

#efficient set to store places, directions we've been already
crumbs() = Set{Tuple{Tuple{Int8, Int8}, Tuple{Int8, Int8}}}() 

posn_clamp(x) = clamp.(x, Int8(1), bounds);

neg(x) = Int8(-1) .* x  
                                    #these combinations are insensitive to direction sign on entry
memoise(pos, dir, item, litmap) = (item == ⮁ && lr(dir)) || (item == ⮀ && ud(dir)) ? begin 
                                                                                        memo[(pos, dir)] = litmap
                                                                                        memo[(pos, neg(dir) )] = litmap
                                                                                    end : memo[(pos, dir)] = litmap


                                                                                    #needs to be general enough to take path specific breadcrumbs (as bc)
drop_crumb(pos, dir, item, bc) = (item == ⮁ && lr(dir)) || (item == ⮀ && ud(dir)) ? begin 
                                                                                    push!(bc, (pos, dir))
                                                                                    push!(bc, (pos, neg(dir) ))
                                                                                end : push!(bc, (pos, dir)) 
                            
memoise_splitter(last_splitter, pos) = isnothing(last_splitter) || begin splitter_memo[last_splitter] = pos ; rev_splitter_memo[pos] = last_splitter; end


#*starting from* pos, entered with direction dir [so we've not lit pos yet]
function trace_path(pos, dir, breadcrumbs, unmemoised_start, last_splitter)
    
    #memoisation is somehow broken - we definitely get *lower* answers than without it [so there's some off by one or something in the memoisation]                                                                                
    haskey(memo, (pos,dir)) && return memo[(pos,dir)];
    litmap = Set{Tuple{Int8, Int8}}();
    #check boundaries - this would be nicer if I had a clamp I guess - we also memoise the last splitter we passed through for path reversal
    if !checkbounds(Bool, matrix, pos...) 
        memoise_splitter(last_splitter, posn_clamp(pos)); 
        return litmap; 
    end
    (pos, dir) in breadcrumbs && return litmap # early return because we crossed our path - what do we return as lightmap set?
    
    #we got to here, so this isn't memoised from a previous path, and it's not a loop in our current path
    push!(litmap, pos); #light the position
    item = matrix[pos...]; #find out what's in our cell
    
    #we're now only dropping crumbs on interesting spots (not ⬛ s)
    drop_crumb(pos, dir, item, breadcrumbs); #specially treats passing through a splitter orthogonally (as approaching from the opposite dir is the same)
    
    #if we haven't yet associated our start position with a splitter, then check if this is the splitter to memoise with
    if !isnothing(unmemoised_start)
        #we can't memoise a reversed path that hits a splitter orthogonally (and is split), because that's an irreversible transform
        # (a splitter can never be a *source* in orthogonal directions)
        (item == ⮁ && ud(dir)) || (item == ⮀ && lr(dir)) && begin #memoisable
                                                                memoise_splitter( (pos, dir) , unmemoised_start)  ;
                                                                unmemoised_start = nothing;
                                                                true
                                                            end
        (item == ⮁ && lr(dir)) || (item == ⮀ && ud(dir)) && begin unmemoised_start = nothing; true end #this path is no longer reversible
    end
    
    nexts = transform[item](dir); #next directions to step in
    
    #if we hit a splitter we need to be careful about how to memoise - hitting it orthogonally also generates the paths 
    #that pass "through" it in both directions, so if we're splitting, start the rays *here* so they memoise the split paths at the splitter too
    if length(nexts) == 2 
        
        for d in nexts #bfs
            union!(litmap, trace_path(pos, d, breadcrumbs, unmemoised_start, last_splitter) ) #all the interior positions are lit as well
        end
    else #otherwise this is a single path - but if this cell is a splitter we need to record it as the "last splitter" so we can memoise the exit point if we hit it
        item in [⮀, ⮁] && begin last_splitter = (pos, neg(dir) ); true end #invert direction because this is a *source*

        #TODO if we are still going in the same direction, fast forward through ⬛  until we aren't
        pos_out = pos;
        if nexts[1] == dir
           
            pos_n = pos .+ dir
            if !checkbounds(Bool, matrix, pos_n...) 
                memoise_splitter(last_splitter, posn_clamp(pos_n)); 
                return litmap; 
            end
            while matrix[pos_n...] == ⬛
                push!(litmap, pos_n); #|= true;
                #drop_crumb(pos_n, dir, ⬛, breadcrumbs); #do I need to drop crumbs everywhere, or just on interesting nodes?
                pos_n = pos_n .+ dir;
                if !checkbounds(Bool, matrix, pos_n...) 
                    memoise_splitter(last_splitter, posn_clamp(pos_n)); 
                    return litmap; 
                end
            end
            pos_out  = pos_n .- dir; #first "interesting" point, remembering to subtract off the last step
        end
        #
        union!(litmap, trace_path(pos_out .+ nexts[1], nexts[1], breadcrumbs, unmemoised_start, last_splitter) )
    end

    #println("Memoising $litmap @ $pos $dir"); #I think this memoisation is broken *except* at branch points at splitters
    #nope still broken in the same way even from splitters
    if (item == ⮁ && ud(dir)) || (item == ⮀ && lr(dir)) 
        memoise(pos, dir, item, deepcopy(litmap));  #fastforward probably ensures we don't waste *too* much space with ⬛ memoisation
    end
    return litmap 
end

rev_dir(x) = (x[1], neg(x[2]) );

function try_entry_point(pos) #start off grid to give us direction for free
    dir =   pos[1] == 0 ? r : 
            pos[1] == bounds[1]+1 ? l : 
            pos[2] == 0 ? d : u;

    points = Set{Tuple{Int8, Int8}}();
    #we already traced this path "out" of a splitter so we can reverse it
    #this won't work unless memoisation as a whole works [which it seems not to]
    #something further weird is happening as the two memoisation sets seem to disagree with each other, so I'm missing a condition
    if haskey(rev_splitter_memo, pos)
       splitter = rev_splitter_memo[pos .+ dir];
       if haskey(memo, splitter)
            points = memo[splitter] ∪ memo[rev_dir(splitter)];
       else #don't have reverse direction
            points = trace_path(splitter[1], splitter[2], crumbs(), splitter[1], nothing) ∪ memo[rev_dir(splitter)];
       end
    else #otherwise we have to do all the work ourselves
       points = trace_path(pos .+ dir, dir, crumbs(), pos, nothing);
    end
    length(points)
end

#lr, ud coords
@time println("$( try_entry_point((0, 1)) )")

function maximise_energize()
    best = 0;
    best_val = (0,0);
    for i in 1:bounds[1]
        #println("Attempting at $(i) 0")
        attempt = try_entry_point( (i, 0) );
        #println("$attempt")
        if attempt > best
            best = attempt
            best_val = (i, 1);
        end
        attempt = try_entry_point( (i, bounds[2]+1) );
        if attempt > best
            best = attempt
            best_val = (i, bounds[2]);
        end
    end
    for i in 1:bounds[2]
        #println("Attempting at 0 $(i)")
        attempt = try_entry_point( (0, i) );
        #println("$attempt")
        if attempt > best
            best = attempt
            best_val = (1, i);
        end
        attempt = try_entry_point( (bounds[1]+1, i) );
        if attempt > best
            best = attempt
            best_val = (bounds[1], i);
        end
    end
    (best, best_val)
end


#println("$( try_entry_point((4, 0)) )")

@time println("$(maximise_energize())")
@time println("$(maximise_energize())")
#Braindump of insights when I was away doing other things:

#We can fast-forward through .s to the next node that does a thing. *
#Corrollary: the only things we really care about memoising (or possibly even breadcrumbing) are the non "." nodes (which form a graph of course)

#Splitters are the only interesting bits of the space in terms of memoisation - every path that *leaves* a splitter and exits the space without 
# being split again can be reversed as a path *entering* from that space [hitting the splitter] + the path that leaves the splitter in the opposite direction.

#Similarly a path split by a splitter is equal to the path passing through the splitter "unsplitting" direction (so if we have that...)

#The litmaps are probably too heavy to memoise when we can just memoise the set of all points we passed through (regardless of direction)
# or even just memoise the breadcrumbs which are a superset of that info.