
#part 1 &2
using Printf

const re = r"[0-9]+"
first_parse(f) = map(x->x.match, collect(eachmatch(re,readline(f))));
#this is really a "reparsing" problem if you're already solving things directly [doing "math" rather than "cs" ;)]
listnums(l) = map(x -> parse(Int32,x),l);
onenum(l) = parse(Int, join(l));

function solve(x)
    halfx = x[1]/2;
    s = sqrt(halfx^2 - x[2] - 1); #-1 because we want the solution that *beats* x[2]
    floor(halfx + s) - ceil(halfx-s) + 1  #I am sure I can make this shorter but... 
end

open("input") do f
    linevals = 0
    l1=first_parse(f);
    l2=first_parse(f);
    Ts=listnums(l1);
    Ds=listnums(l2);
    linevals = reduce(*, solve.(zip(Ts,Ds))) ;

    println("Part one: $linevals");
    @printf "Part two: %f" solve([onenum(l1),onenum(l2)])
end
    