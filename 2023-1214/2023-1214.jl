
#part 1 - fancy "don't actually move anything" version

open("input") do f
    data = readlines(f);
    linenum = length(data);
    next_row_to_fill = fill(linenum, length(data[begin])) ; #our counter of next O values (starting from linenum)
    Orows = 0;
    for line in data
        ll = collect(line);
        #   so - for each line, the "final position" of a O is either: the (final position of the previous O in that col) - 1, or the (last # in the col)-1 whichever happened last    
        Os =  'O' .== ll ;  #<-- selector used for summing Os and also decrementing next row to fill [we're counting down from the top]
        Hs = '#' .== ll;

        Orows += sum(next_row_to_fill[Os]); #okay, I love mask indexing
        next_row_to_fill[Os] .-= 1; # each to increment this
        linenum -= 1;
        next_row_to_fill[Hs] .= linenum # '#' set the next row for their col to the one after them via selector
        #println("$next_row_to_fill");
    end

    println("$Orows");
end

#for part 2, we obviously need to find the cycles that get "stuck" so we can skip ahead
#we should also properly represent the data in a nicely iterable format in rows and cols first


function get_data(f) 
    ff = open(f); 
    data = readlines(f);
    reduce(hcat, collect.(data))
end

data = get_data("input");

""" shift!(array, axis, rev)
    "shifts" Os in the 2d array along axis as if tilted to slide them in that direction
        rev reverses direction of sliding (defaults to sliding "up" to lower indices)
"""
function shift!(data, axis, rev)
    other_axis = 3 - axis; #2->1, 1->2
    d_axes = axes(data);
    linenum = d_axes[axis][rev ? end : begin];
    next_row_to_fill = fill( linenum , d_axes[other_axis]);
    iter = rev ? reverse(eachslice(data, dims=axis)) : eachslice(data, dims=axis);
    step = 1 - 2*rev; #rev ? -1 : 1; but branchless

    for ll in iter
        #   so - for each line, the "final position" of a O is either: the (final position of the previous O in that col) - 1, or the (last # in the col)-1 whichever happened last    
        Os =  'O' .== ll ;  #<-- selector used for summing Os and also decrementing next row to fill [we're counting down from the top]
        Hs = '#' .== ll; 
    # zero out the 'O's in the current row [so they can be filled by the next step]
        ll[Os] .= '.';
    # put an 'O' in each next_row_to_fill[Os] ; - need to select the same "perp-to-axis" index as Os and Os value in the axis direction
    #need to select only the "cols" in data we want to set... 
        setindex!.(eachslice(data, dims=other_axis)[Os], 'O', next_row_to_fill[Os]);
        next_row_to_fill[Os] .+= step; # each to increment this
        linenum += step;
        next_row_to_fill[Hs] .= linenum # '#' set the next row for their col to the one after them via selector 
    end
end

get_load(data) =  mapreduce(  x->x[1]*count(==('O'), x[2]) , + ,  enumerate(reverse(eachslice(data,dims=2)))  ) ;

#pt 1 if you wanted to do it
#shift!(data, 2, false);
#println("$(get_load(data))"); #hopefully == 136 ? 


function spin_cycle!(data)
    shift!(data, 2, false); #N  #assuming 2 is the right axis that I'm thinking of...
    shift!(data, 1, false)  #W
    shift!(data, 2, true)  #S
    shift!(data, 1, true)  #E
end


#we're using a hash different to just the load because I'm not convinced the load is a good hash in itself (it's probably fine to use it but I am paranoid)
""" find_cycles!(data)
        (destructively) performs the spin_cycle operation (shift! with N, W, S, E directions in sequence) until it detects a cycle in the pattern of results
        returns ( list_of_hashes_generated, list_of_loads_generated, element_where_cycle_starts, length_of_cycle)
        get_hash_at can then be used to get the hash or load index for a given iteration, greater than cycle_start
"""
function find_cycles!(data)
    hashes = [hash(data)];  #assume hash here just calculates the "load" value
    loads = [get_load(data)]
    cyclestart = nothing
    while isnothing(cyclestart)
        spin_cycle!(data);
        newhash = hash(data);
        cyclestart = findfirst(==(newhash), hashes);
        push!(hashes, newhash);
        push!(loads, get_load(data));
    end
    cycleduration = length(hashes) - cyclestart;
    println("Found cycle, starts at offset: $cyclestart , duration $cycleduration");
    (hashes, loads,cyclestart, cycleduration)
end

(hashes, loads,cyclestart, cycleduration) = find_cycles!(data);

# Nth cycle at hash position N+1 due to Julia indexing
                #        loop position                   #and offset into loop
get_hash_at(x) = ( (x + 1 - cyclestart) % cycleduration ) + cyclestart;  

#the answer!
println("$(loads[get_hash_at(1000000000)])");