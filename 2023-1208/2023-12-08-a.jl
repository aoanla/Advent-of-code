
#part 1


struct node
    value::String
    #lr::(String,String) 
end


readfile(file) = open(file) do f
    f_iter = Iterators.Stateful(eachline(f)); 
    directions = 'R' .== collect(popfirst!(f_iter));
    popfirst!(f_iter); #whitespace
    treedict = Dict{String, Tuple{String, String}}();
    while ! isempty(f_iter)
        line = popfirst!(f_iter);
        #(name, l, r) = (line[1:3], line[8:10], line[13:15]);
        treedict[line[1:3]] = (line[8:10], line[13:15]);
    end
    (directions, treedict)
end

function solve(file) 
    (d,t) = readfile(file);
    cursor = "AAA"
    for (i,n) in enumerate(Iterators.cycle(d))
        cursor = t[cursor][n + 1];
        cursor != "ZZZ" && continue ;
        println("Found ZZZ after $i steps!");
        break;
    end
end

solve("input")