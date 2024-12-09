# just from looking at pt1, pt2 is clearly going to be a defragmentation task.
# as such, pt1 has a trivial way to do it based on representing the map as an "unpacked"
# set of items, but pt2 might be easier if we have a more sophisticated representation
# to begin with.

#facts about items: no "file" or "empty space" has more than 9 blocks, or fewer than 1 
# each item is, initially, a single "span". In the worst case, we can represent an item as 9 spans
# of length 1 each. (In the best case, we save 9x the space!)


#pt 1 algo, using spans:

for empty_span ∈ empty_spans
    while len(empty_span)>0
        fs = take_last_file_span_on_disk
        if len(fs) <= len(empty_span)
            fs.start = empty_span.start 
            #check for span merger (if fs.type == previous_fs.type then replace with 1)
            #update index of spans here (priority queue?)
            empty_span.start += len(fs)
            empty_span.len -= len(fs)
        else #chop fs span in two
            new_fs_span = fs_span(start+len(es), len(fs)-len(es))
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
checksum = mapreduce(+, file_spans) do span
    span.id*((2*span.start + span.len - 1)*span.len)÷2
end
