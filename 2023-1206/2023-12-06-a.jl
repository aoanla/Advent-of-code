
#part 1
using Printf

const re = r"[0-9]+"
first_parse(f) = map(x->x.match, collect(eachmatch(re,readline(f))));
listnums(l) = map(x -> parse(Int32,x),l);
onenum(l) = parse(Int, join(l));
function solve(x)
    halfx = x[1]/2;
    s = sqrt(halfx^2 - x[2] - 1); #-1 because we want the solution that *beats* x[2]
    floor(halfx + s) - ceil(halfx-s) + 1
end

open("input") do f
    linevals = 0
    l1=first_parse(f);
    l2=first_parse(f);
    Ts=listnums(l1);
    Ds=listnums(l2);
    linevals = reduce(*, map(solve,zip(Ts,Ds))) ;
    println("Part one: $linevals");
    println("$(onenum(l1)) $(onenum(l2))")
    @printf "Part two: %f" solve([onenum(l1),onenum(l2)])
end
    