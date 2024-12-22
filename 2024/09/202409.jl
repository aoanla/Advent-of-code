using DataStructures   #for SortedDict

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
file_spans_ = Dict{Int32,f_span}()
empty_spans_ = Dict{Int32,Int32}()
#Pt2 - this is probably a dequeue for the empty spans (we need to pop and push from the front)
# a deque for each length of empty_span (0-9)
empty_span_queues = [ Deque{Int32}() for i ∈ 1:9 ] #each length of empty_span is a list of start positions

max_empty_len = 0 #fast check
read("input") |> Base.Fix1(map, x->x-zero_) |> Base.Fix2(Base.Iterators.partition,2) |>  enumerate |> Base.Fix1((op,iter)->foldl(op,iter; init=0), (n,(i,f))->begin
    file_spans_[n]=f_span(i-1,first(f))
    if length(f) == 2
        empty_spans_[n+first(f)] = last(f)
        last(f) != 0 && push!(empty_span_queues[last(f)], n+first(f))  #push! == pushlast
        #if max_empty_len < last(f) 
        #    max_empty_len = last(f)
        #end
    end
    n + sum(f) #next position
end)
#now we have span vectors, which should probably be priority queues

for i ∈ 1:9
    push!(empty_span_queues[i], typemax(Int32)) #Deques must be non-empty, so lets give them a "default" position that's at the limit of distance
end

#print("$file_spans\n")
#print("$empty_spans\n")
#pt 1 algo, using spans:
file_spans = deepcopy(file_spans_)
empty_spans = deepcopy(empty_spans_)
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
            
            file_spans[new_start_fs] = fs #and move to new location

            len -= fs.len
            len == 0 && break 
        else #chop fs span in two
            rem_f_span = f_span(fs.id, fs.len-len) #yes, we remove from the end, sigh
            empty_spans[start_fs+rem_f_span.len] = len #make our new empty space 
            file_spans[start_empty] = f_span(fs.id, len) #fill empty span
            file_spans[start_fs] = rem_f_span #this is what's left
            break #no more need to iterate file spans
        end
        
    end
    delete!(empty_spans,tmp)
end

#keys(file_spans) |> collect |> sort! |> Base.Fix1(foreach, x->print("P$x - id: $(file_spans[x].id) len: $(file_spans[x].len)\n"))
#for file_span ∈ file_spans
    #total value is file_span_id * (sum of all positions in span)
    # sum_of_all_positions from start to start+len is (2*start + len - 1)*len / 2 [Gaussian sum]
#    tot += 
checksum(file_spans) = mapreduce(+, keys(file_spans) ) do start
    span = file_spans[start]
    span.id*((2*start + span.len - 1)*span.len)÷2

end

print("Pt1: $(checksum(file_spans))\n")

##okay, so I overestimated the complexity of pt2 from looking at pt1
# this is just iterating over my reverse_order_file_spans list, finding the 
# left-most space big enough to hold it
# it might be reasonable to maintain a max_empty_span var on parsing the list
# so we can early-reject moving a span if no empty spans can take it. 
# (we could also maintain a dict of vectors of empty_spans keyed by size too)


#todo - min_index, insert_into

#pt2 basically
for fs_posn ∈ keys(file_spans_) |> collect |> (x-> sort!(x; rev=true)) 
    fs = file_spans_[fs_posn]
    #each span gets tried against the stuff available when it is checked.
    #fs.len > max_empty_len && continue #early exit if we never had a gap large enough
    
    (empty_posn,empty_len) = findmin(first.(empty_span_queues[fs.len:end])) #find the earliest span that is long enough
    empty_len += fs.len - 1 #correct for offset in sample 
    empty_posn > fs_posn && continue #the earliest useful span is past this file, so we can't use it 
    popfirst!(empty_span_queues[empty_len]) #removes it for us

    file_spans_[empty_posn] = fs
    delete!(file_spans_, fs_posn)

    if empty_len > fs.len #push back remaining elem, maintaining sort order
        buffer = Stack{Int64}()
        posn =  empty_posn+fs.len
        len = empty_len - fs.len
        while first(empty_span_queues[len]) < posn
            push!(buffer, popfirst!(empty_span_queues[len]))
        end
        pushfirst!(empty_span_queues[len], posn)
        for item ∈ buffer
            pushfirst!(empty_span_queues[len], item)
        end
    end

end

print("Pt2: $(checksum(file_spans_))\n")