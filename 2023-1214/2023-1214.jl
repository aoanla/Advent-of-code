
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