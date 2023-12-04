
#part 1
using Base.Iterators



open("input") do f
    linevals = 0    

    for line in eachline(f) 
        _, wins, candidates = filter.(num -> length(num) > 0, split.(Iterators.flatten(split.(split(line, ':'), '|')), ' ' ));

        val = length(filter(c -> in(c, wins), candidates)) -1;
        linevals += val >= 0 ? 2^val : 0

    end

    println("$linevals");
end
    