
#part 2



readfile(file) = open(file) do f
    f_iter = Iterators.Stateful(eachline(f)); 
    directions = 'R' .== collect(popfirst!(f_iter));
    popfirst!(f_iter); #whitespace
    treedict = Dict{String, Tuple{String, String}}();
    starts = Vector{String}()
    while ! isempty(f_iter)
        line = popfirst!(f_iter);
        #(name, l, r) = (line[1:3], line[8:10], line[13:15]);
        treedict[line[1:3]] = (line[8:10], line[13:15]);
        if line[3] == 'A' 
            push!(starts, line[1:3]);
        end
    end
    (directions, treedict, starts)
end

notfoundZ(x) = x[3]!='Z'
foundA(x) = x[3]=='A'
foundZ(x) = x[3]=='Z'

function solve(file) 
    (d,t,cursors) = readfile(file);
    println("$cursors");
    #the clever approach would be to find cycles & sub-paths for each of the **As and then find the LCM?
    starts = deepcopy(cursors);
    counter = (x->false).(cursors);
    cycles = Vector{Int}();
    for (i,n) in enumerate(Iterators.cycle(d))
        cursors .= (x->t[x][n+1]).(cursors);
        looper = filter(x->foundZ(x[2]), collect(enumerate(cursors))); #this only works because every Z loops back to the start of its cycle immediately
        if length(looper) > 0
            for (idx,c) in looper
                counter[idx] |= true;
                println("After $i steps, $(starts[idx]) maps to $c");
                push!(cycles, i);
            end
        end
        reduce(&, counter) || continue; 
        #reduce(|, notfoundZ.(cursors) ; init=false) && continue ;
        #println("Found **Z after $i steps!");
        break;
    end
    #A more bulletproof algorithm that worked on *any* data would need to find the actual cycles in the data [and where in each cycle we met Zs]
    println("$(reduce(lcm, cycles))");
end

solve("input")