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
read("inputtest") |> Base.Fix1(map, x->x-zero_) |> Base.Fix2(Base.Iterators.partition,2) |>  enumerate |> Base.Fix1((op,iter)->foldl(op,iter; init=0), (n,(i,f))->begin

    file_spans[n]=f_span(i-1,first(f))
    if length(f) == 2
        empty_spans[n+first(f)] = last(f)
    end
    n + sum(f) #next position
end)
#now we have span vectors, which should probably be priority queues

print("$file_spans\n")
print("$empty_spans\n")
#pt 1 algo, using spans:

exit()

poplast!(d::SortedDict{T,V}) where T,V = pop!(lastindex(d)) 

empty_spans_keys = keys(empty_spans) |> sort 
for start_empty ∈ empty_spans_keys
    len = empty_spans[start_empty]
    inverse_file_spans = keys(file_spans) |> (x-> sort(x; rev=true)) |> collect
    for (idx,start_fs) ∈ enumerate(inverse_file_spans)
        fs = file_spans[start_fs]
        if fs.len <= len
            #create new empty span where fs is now
            empty_span[start_fs] = fs.len #this should do an empty span merger if possible (to right is easiest) 
            new_start_fs = start_empty 
            delete!(file_spans,start_fs) #remove file_span
              
            #check for span merger (if fs.type == previous_fs.type then replace with 1)
            #update index of spans here (priority queue?)
            empty_span.start += fs.len
            len -= len_fs
            len == 0 && break 
        else #chop fs span in two
            new_fs_span = fs_span(fs.id, fs.len-len) #yes, we remove from the end, sigh
            fs_span.start = empty_span.start
            fs_span.len = len(es)
            #check for span merger (if fs.type == previous_fs.type then replace with 1)
            #update span index with new fs_span location and new_fs_span in general
        end
    end
    #check for span merger between the final fs we moved and the *next* fs [which must be adjacent to us now]
    # if fs.type == next_fs.type then replace with 1
end

#for file_span ∈ file_spans
    #total value is file_span_id * (sum of all positions in span)
    # sum_of_all_positions from start to start+len is (2*start + len - 1)*len / 2 [Gaussian sum]
#    tot += 
checksum = mapreduce(+, file_spans) do (start,span)
    span.id*((2*start + span.len - 1)*span.len)÷2
end
