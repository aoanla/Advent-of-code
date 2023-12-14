
#part 1

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
        println("$next_row_to_fill");
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

data = get_data("input2");


function shift!(data, axis, step)
    next_row_to_fill = fill( begin or end based on direction, (size perp to iteration axis))
    for ll in data iterate across axis in direction 
        #   so - for each line, the "final position" of a O is either: the (final position of the previous O in that col) - 1, or the (last # in the col)-1 whichever happened last    
        Os =  'O' .== ll ;  #<-- selector used for summing Os and also decrementing next row to fill [we're counting down from the top]
        Hs = '#' .== ll;
    #  not needed - #'s donot move  put a '#' in each Hs position in the current row 
    # zero out the 'O's in the current row [so they can be filled by the next step]
      ll[Os] .= '.''
    # put an 'O' in each next_row_to_fill[Os] ; 
      ??
        next_row_to_fill[Os] .+= step; # each to increment this
        linenum += step;
        next_row_to_fill[Hs] .= linenum # '#' set the next row for their col to the one after them via selector 
        #println("$next_row_to_fill");
    end
    #    next_row_to_fill = fill(linenum, length(data[begin])) ; #our counter of next O values (starting from linenum)
    #    Orows = 0;
end

function spin_cycle!(data)
    shift!(data, NORTH)
    shift!(data, WEST)
    shift!(data, SOUTH)
    shift!(data, EAST)
end

function detect_change(data, cycles)
    olddata = deepcopy(data)
    for i in 1:cycles
        spin_cycle!(data);
    end
    changes = olddata .== data
    count(changes)
end

#try some lagged cycle testing I guess