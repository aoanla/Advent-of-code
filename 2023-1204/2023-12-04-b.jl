
#part 2
using Base.Iterators


open("input") do f   
    extras = Int[]
    for (index, line) in Iterators.enumerate(eachline(f))
        #this is overly complex given that the input is fixed format [we could just parse out by positions]
        _, wins, candidates = filter.(num -> length(num) > 0, split.(Iterators.flatten(split.(split(line, ':'), '|')), ' ' ));

        #this would be nicer if Julia had a built-in Queue and a pop with defaults if the list is empty
        if index > length(extras)
            push!(extras,1)
        end

        chain_len = length(filter(c -> in(c, wins), candidates));
        extra = extras[index];
        
        for i in index+1:index+chain_len
            if i > length(extras)
                push!(extras,1)
            end 
            extras[i] += extra
        end

    end
    println("$(reduce(+, extras))");
end
    