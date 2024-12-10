#using DataStructures   #for SortedDict

# just from looking at pt1, pt2 is clearly going to be a defragmentation task.
# as such, pt1 has a trivial way to do it based on representing the map as an "unpacked"
# set of items, but pt2 might be easier if we have a more sophisticated representation
# to begin with.

#facts about items: no "file" or "empty space" has more than 9 blocks, or fewer than 1 
# each item is, initially, a single "span". In the worst case, we can represent an item as 9 spans
# of length 1 each. (In the best case, we save 9x the space!)

struct f_span 
    id::Int32
    len::Int32 #in fact, this is a maximum of 9!
end

struct e_span
    len::Int32 #this *could* be big, if we're taking from the end and making big spaces 
end 

zero_ = UInt8('0')

#parse input 
file_spans = Dict{Int32,f_span}()
empty_spans = Dict{Int32,Int32}()
read("input") |> Base.Fix1(map, x->x-zero_) |> Base.Fix2(Base.Iterators.partition,2) |>  enumerate |> Base.Fix1((op,iter)->foldl(op,iter; init=0), (n,(i,f))->begin
    file_spans[n]=f_span(i-1,first(f))
    if length(f) == 2
        empty_spans[n+first(f)] = last(f)
    end
    n + sum(f) #next position
end)
#now we have span vectors, which should probably be priority queues

#print("$file_spans\n")
#print("$empty_spans\n")
#pt 1 algo, using spans:

#exit()

#poplast!(d::SortedDict{T,V}) where T,V = pop!(lastindex(d)) 

empty_spans_keys = keys(empty_spans) |> collect |> sort! 
for start_empty ∈ empty_spans_keys
    #print("filling $start_empty\n")
    len = empty_spans[start_empty]
    len == 0 && continue 
    tmp = start_empty
    inverse_file_spans = keys(file_spans) |> collect |> (x-> sort!(x; rev=true)) |> Base.Fix1(filter, >=(start_empty))
    for (idx,start_fs) ∈ enumerate(inverse_file_spans)
        fs = file_spans[start_fs]
        if fs.len <= len
            #create new empty span where fs is now
            empty_spans[start_fs] = fs.len #this should do an empty span merger if possible (to right is easiest) 
            
            new_start_fs = start_empty 
            start_empty += fs.len #update our empty span here because we might overwrite fs later 

            delete!(file_spans,start_fs) #remove file_span
            
            #STUFF FOR PT2
            #check for merge not 
            #nxt = last_thing_we_mvd
            #if start + file_spans[nxt].len == new_start_fs && file_spans[nxt].id == fs.id
                #merge
            #end 
            file_spans[new_start_fs] = fs #and move to new location
            #check for span merger (if fs.type == previous_fs.type then replace with 1)
            #update index of spans here (priority queue?)
            #/STUFF FOR PT2
            len -= fs.len
            len == 0 && break 
        else #chop fs span in two
            rem_f_span = f_span(fs.id, fs.len-len) #yes, we remove from the end, sigh
            empty_spans[start_fs+rem_f_span.len] = len #make our new empty space 
            file_spans[start_empty] = f_span(fs.id, len) #fill empty span
            file_spans[start_fs] = rem_f_span #this is what's left
            #STUFF FOR PT2
            #check for span merger (if fs.type == previous_fs.type then replace with 1)
            #STUFF FOR PT2

            #update span index with new fs_span location and new_fs_span in general
            break #no more need to iterate file spans
        end
        
    end
    delete!(empty_spans,tmp)
    #STUFF FOR PT2
    #check for span merger between the final fs we moved and the *next* fs [which must be adjacent to us now]
    #nxt = last_fs_start + last_fs_len
    #has_key(file_spans, nxt) && file_spans[nxt].id = last_fs_id && #merge right 
    #/STUFF FOR PT2
end

#keys(file_spans) |> collect |> sort! |> Base.Fix1(foreach, x->print("P$x - id: $(file_spans[x].id) len: $(file_spans[x].len)\n"))
#for file_span ∈ file_spans
    #total value is file_span_id * (sum of all positions in span)
    # sum_of_all_positions from start to start+len is (2*start + len - 1)*len / 2 [Gaussian sum]
#    tot += 
checksum = mapreduce(+, keys(file_spans) ) do start
    span = file_spans[start]
    #print("Sum: starting at $(start) to $(start+span.len-1), mul by $(span.id)... ")
    res = span.id*((2*start + span.len - 1)*span.len)÷2
    #print("$res \n")
    res
end

print("$checksum")

##okay, so I overestimated the complexity of pt2 from looking at pt1
# this is just iterating over my reverse_order_file_spans list, finding the 
# left-most space big enough to hold it
# it might be reasonable to maintain a max_empty_span var on parsing the list
# so we can early-reject moving a span if no empty spans can take it. 
# (we could also maintain a dict of vectors of empty_spans keyed by size too)
