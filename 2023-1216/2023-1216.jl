

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
bitmatrix = falses(size(matrix)); #litness
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
trace_path(pos, dir, breadcrumbs)
    #memoisation win!                                                                                
    haskey(memo, (pos,dir)) && return memo[(pos,dir)]
    litmap = falses(size(bitmatrix)); #new litmap to work with
    (pos, dir) in breadcrumbs && return litmap # early return because we crossed our path - what do we return as lightmap set?
    
    #we got to here, so this isn't memoised from a previous path, and it's not a loop in our current path
    if 
    litmap[pos...] |= true ; #light the position
    item = matrix[pos];

    nexts = transform[item](dir);
    for d in nexts #bfs
        litmap .|= trace_path(pos.+d, d, breadcrumbs) #all the interior positions are lit as well
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