

d = read("input");

#items, fun with Unicode
nl = UInt8('\n')
⮀ = UInt8('-')
⮁ = UInt8('|')
⬛ = UInt8('.')
◿ = UInt8('/')
◺ = UInt8('\\')

width = findfirst(==(nl), d);
matrix = reshape(d, width, :)[begin:end-1, :]; #cut off the newlines


bounds = size(matrix)
println("$bounds")

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
#yes I really do just need to make some of these into structs now it's getting silly
memo = Dict{Tuple{Tuple{Int8,Int8}, Tuple{Int8,Int8}}, Tuple{Set{Tuple{Int8, Int8}}, Tuple{Tuple{Int8,Int8}, Tuple{Int8,Int8}}}}()


#efficient set to store places, directions we've been already
crumbs() = Set{Tuple{Tuple{Int8, Int8}, Tuple{Int8, Int8}}}() 

posn_clamp(x) = clamp.(x, Int8(1), bounds);

neg(x) = Int8(-1) .* x  
                                                                                    #needs to be general enough to take path specific breadcrumbs (as bc)
drop_crumb(pos, dir, item, bc) = (item == ⮁ && lr(dir)) || (item == ⮀ && ud(dir)) ? begin 
                                                                                    push!(bc, (pos, dir))
                                                                                    push!(bc, (pos, neg(dir) ))
                                                                                end : push!(bc, (pos, dir)) 

rev_dir(x) = (x[1], neg(x[2]) );

global cursor = nothing ; #Global cursor hack to set what the far end of our memoisation target is
      #posn, direction entered from, EDGE or SPLIT                                                                           

EDGE = true;
SPLIT = false;

#we want to memoise to *reverse* the chain we've been passed for the edge elements, so we're going to invert some directions here
                 #far end of chain  #chain       #near end of chain - a splitter                                                      
function memoise_at(cursor,         tmp_litmap, pos, d)
    if cursor[3] == EDGE 
        memo[rev_dir(cursor[1:2])] = (tmp_litmap, rev_dir((pos, d))); 
    else #SPLIT  here we do want to roll *forwards*
        memo[cursor[1:2]] = (tmp_litmap, ((0,0),(0,0))) ; #in this case, we don't care about the end point, for now
        x = 0; #null op for now to see if this works at all
    end
end


#*starting from* pos, entered with direction dir [so we've not lit pos yet]
function trace_path(pos, dir, breadcrumbs)
    
    #eventually, this will work *for splitters* in some cases, see TODO later on in this function                                                                                
    #haskey(memo, (pos,dir)) && return memo[(pos,dir)];
    litmap = Set{Tuple{Int8, Int8}}();
    #check boundaries - this would be nicer if I had a clamp I guess - we also set the cursor so we can memoise the edge we left at
    if !checkbounds(Bool, matrix, pos...) 
        global cursor = (pos .- dir, dir, EDGE); #the point we left the edge 
        return litmap; 
    end
    if (pos, dir) in breadcrumbs
        global cursor = nothing #I don't think we can use a valid cursor if we end due to loop detection 
        return litmap # early return because we crossed our path 
    end
    #we got to here, so this isn't memoised from a previous path, and it's not a loop in our current path
    push!(litmap, pos); #light the position
    item = matrix[pos...]; #find out what's in our cell
    
    #we're now only dropping crumbs on interesting spots (not ⬛ s)
    drop_crumb(pos, dir, item, breadcrumbs); #specially treats passing through a splitter orthogonally (as approaching from the opposite dir is the same)
    
    nexts = transform[item](dir); #next directions to step in
    
    #if we hit a splitter we need to be careful about how to memoise - hitting it orthogonally also generates the paths 
    #that pass "through" it in both directions, so if we're splitting, start the rays *here* so they memoise the split paths at the splitter too
    if length(nexts) == 2 
        #this is also the point we "collect" a memoisation for a cursor, and blank the cursor
        cursors = [];
        for d in nexts #bfs
            tmp_litmap  = trace_path(pos, d, breadcrumbs)  #all the interior positions are lit as well
            if !isnothing(cursor)
                memoise_at(cursor, tmp_litmap, pos, d);
                push!(cursors, deepcopy(cursor)); #valid path to this point, tracing back
                global cursor = nothing;
            end
            union!(litmap, tmp_litmap);
        end
        if length(cursors) == 2  #*if* we have a complete history up to here, we can pull it back further, 
            #we should be able to extend the two memoisations we just did to add them to each other             
            c1 = rev_dir(cursors[1][1:2])
            c2 = rev_dir(cursors[2][1:2])
            memo[c1] = (litmap , cursors[2][1:2]);
            memo[c2] = (litmap , cursors[1][1:2]); 
            global cursor = (pos, dir, SPLIT);
            #and we *should also be able to build a further chain that works back to the next splitter to memoise the paths between splitters... 
            #TODO
        end
    else 
        #if we are still going in the same direction, fast forward through ⬛  until we aren't
        pos_out = pos;
        if nexts[1] == dir
           
            pos_n = pos .+ dir
            if !checkbounds(Bool, matrix, pos_n...) 
                global cursor = (pos .- dir, dir, EDGE);
                return litmap; 
            end
            while matrix[pos_n...] == ⬛
                push!(litmap, pos_n); #|= true;

                pos_n = pos_n .+ dir;
                if !checkbounds(Bool, matrix, pos_n...) 
                    global cursor = (pos .- dir, dir, EDGE);
                    return litmap; 
                end
            end
            pos_out  = pos_n .- dir; #first "interesting" point, remembering to subtract off the last step
        end
        #
        union!(litmap, trace_path(pos_out .+ nexts[1], nexts[1], breadcrumbs) )
    end

    return litmap 
end



function try_entry_point(pos) #start off grid to give us direction for free
    dir =   pos[1] == 0 ? r : 
            pos[1] == bounds[1]+1 ? l : 
            pos[2] == 0 ? d : u;

    pos = pos .+ dir
    points = Set{Tuple{Int8, Int8}}();
    #we already traced this path "out" of a splitter so we can reverse it
    if haskey(memo, (pos, dir))
            (memo_map, memo_splitter) = memo[(pos, dir)]; #this is now the direction we need to start off in the splitter 
            union!(points, memo_map); #start off with the points we should have
            union!(points, trace_path(memo_splitter[1], memo_splitter[2], crumbs()))
    else #otherwise we have to do all the work ourselves
       points = trace_path(pos, dir, crumbs());
    end
    length(points)
end

#lr, ud coords
@time println("$( try_entry_point((0, 1)) )")

#this could be prettier!
function maximise_energize()
    best = 0;
    best_val = (0,0);
    for i in 1:bounds[1]
        attempt = try_entry_point( (i, 0) );
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
        attempt = try_entry_point( (0, i) );
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

@time println("$(maximise_energize())")
#@time println("$(maximise_energize())")
#Braindump of insights when I was away doing other things:

#We can fast-forward through .s to the next node that does a thing. *
#Corrollary: the only things we really care about memoising (or possibly even breadcrumbing) are the non "." nodes (which form a graph of course)

#Splitters are the only interesting bits of the space in terms of memoisation - every path that *leaves* a splitter and exits the space without 
# being split again can be reversed as a path *entering* from that space [hitting the splitter] + the path that leaves the splitter in the opposite direction.

#Similarly a path split by a splitter is equal to the path passing through the splitter "unsplitting" direction (so if we have that...)

#The litmaps are probably too heavy to memoise when we can just memoise the set of all points we passed through (regardless of direction)
# or even just memoise the breadcrumbs which are a superset of that info.