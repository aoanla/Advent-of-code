
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

function solve(file) 
    (d,t,cursors) = readfile(file);
    println("$cursors");
    exit();
    #brute force approach
    #the clever approach would be to find cycles & sub-paths for each of the **As and then find the LCM of the prime factors?
    for (i,n) in enumerate(Iterators.cycle(d))
        cursors .= (x->t[x][n+1]).(cursors);
        reduce(|, notfoundZ.(cursors) ; init=false) && continue ;
        println("Found **Z after $i steps!");
        break;
    end
end

solve("input")