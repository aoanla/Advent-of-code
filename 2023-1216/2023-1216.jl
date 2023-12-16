

d = read("input");

#items, fun with Unicode
nl = UInt8('\n')
⮀ = UInt8('-')
⮁ = UInt8('|')
⬛ = UInt8('.')
◿ = UInt8('/')
◺ = UInt8('\\')

width = findfirst(==(nl), d);
matrix = transpose(reshape(d, width, :)[begin:end-1, :]);
bounds = size(matrix)
bitmatrix = falses(bounds); #litness
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
trans⮂(entrydir) = ud(entrydir) ? [entrydir] : [u, d]
trans⮁(entrydir) = lr(entrydir) ? [entrydir] : [l,r]

transform = Dict( [
        (⮀ => trans⮂),
        (⮁ => trans⮁),
        (⬛ => trans⬛),
        (◿ => trans◿),
        (◺ => trans◺)        ]);

#memoisation dict just in case we need it (pos, dir) -> litmap
memo = Dict{Tuple{Tuple{Int8,Int8}, Tuple{Int8,Int8}}, typeof(bitmatrix)}()
#efficient set to store places, directions we've been already
breadcrumbs = Set{Tuple{Tuple{Int8, Int8}, Tuple{Int8, Int8}}}() 

posn_clamp(x) = clamp.(x, 0, bounds);

                                    #these combinations are insensitive to direction sign
memoise(pos, dir, item, litmap) = (item == ⮁ && lr(dir)) || (item == ⮀ && ud(dir)) ? begin 
                                                                                        memo[(pos, dir)] = litmap
                                                                                        memo[(pos, -.(dir) )] = litmap
                                                                                    end : memo[(pos, dir)] = litmap

                                                                                    #needs to be general enough to take path specific breadcrumbs (as bc)
drop_crumb(pos, dir, item, bc) = (item == ⮁ && lr(dir)) || (item == ⮀ && ud(dir)) ? begin 
                                                                                    push!(bc, (pos, dir))
                                                                                    push!(bc, (pos, -.(dir) ))
                                                                                end : push!(bc, (pos, dir)) 


#*starting from* pos, entered with direction dir [so we've not lit pos yet]
trace_path(pos, dir, breadcrumbs, unmemoised_start, last_splitter)
    #memoisation win!                                                                                
    haskey(memo, (pos,dir)) && return memo[(pos,dir)]
    litmap = falses(bounds); #new litmap to work with
    #check boundaries - this would be nicer if I had a clamp I guess - we also memoise the last splitter we passed through for path reversal
    !checkbounds(Bool, matrix, pos...) && begin memoise_splitter(last_splitter, posn_clamp(pos)); return litmap;
    (pos, dir) in breadcrumbs && return litmap # early return because we crossed our path - what do we return as lightmap set?
    
    #we got to here, so this isn't memoised from a previous path, and it's not a loop in our current path
    litmap[pos...] |= true ; #light the position
    item = matrix[pos...];
    drop_crumb(pos, dir, item, breadcrumbs); #specially treats passing through a splitter orthogonally (as approaching from the opposite dir is the same)
    
    #if we haven't yet associated our start position with a splitter, then check if this is the splitter to memoise with
    if !isnothing(unmemoised_start)
        #we can't memoise a reversed path that hits a splitter orthogonally (and is split), because that's an irreversible transform
        # (a splitter can never be a *source* in orthogonal directions)
        (item == ⮁ && ud(dir)) || (item == ⮀ && lr(dir)) && begin 
                                                                memoise_splitter( (pos, dir) , unmemoised_start)  ;
                                                                unmemoised_start = nothing;
                                                                true
                                                            end
    end
    
    nexts = transform[item](dir); #next directions to step in

    #if we hit a splitter we need to be careful about how to memoise - hitting it orthogonally also generates the paths 
    #that pass "through" it in both directions, so if we're splitting, start the rays *here* so they memoise the split paths at the splitter too
    if length(nexts) == 2    
        for d in nexts #bfs
            litmap .|= trace_path(pos, d, breadcrumbs, unmemoised_start, last_splitter) #all the interior positions are lit as well
        end
    else #otherwise this is a single path - but if this cell is a splitter we need to record it as the "last splitter" so we can memoise the exit point if we hit it
        item in [⮀, ⮁] && last_splitter = (pos, -.(dir) ) #invert direction because this is a *source*

        #TODO if we are still going in the same direction, fast forward through dots until we aren't
        if nexts[1] == dir
           pos_n = pos .+ dir
           while matrix[pos_n] == ⬛
            !checkbounds(Bool, matrix, pos_n...) && begin memoise_splitter(last_splitter, posn_clamp(pos_n)); return litmap;
            litmap[pos_n...] |= true;
            drop_crumb(pos_n, dir, ⬛, breadcrumbs); #do I need to drop crumbs everywhere, or just on interesting nodes?
            pos_n .+= dir;
           end
           pos = pos_n; #first "interesting" point
        end
        #
        litmap .|= trace_path(pos .+ nexts[1], nexts[1], breadcrumbs, unmemoised_start, last_splitter) 
    end

    memoise(pos, dir, item, litmap);
    return litmap 
end


#Braindump of insights when I was away doing other things:

#We can fast-forward through .s to the next node that does a thing.
#Corrollary: the only things we really care about memoising (or possibly even breadcrumbing) are the non "." nodes (which form a graph of course)

#Splitters are the only interesting bits of the space in terms of memoisation - every path that *leaves* a splitter and exits the space without 
# being split again can be reversed as a path *entering* from that space [hitting the splitter] + the path that leaves the splitter in the opposite direction.

#Similarly a path split by a splitter is equal to the path passing through the splitter "unsplitting" direction (so if we have that...)

#The litmaps are probably too heavy to memoise when we can just memoise the set of all points we passed through (regardless of direction)
# or even just memoise the breadcrumbs which are a superset of that info.