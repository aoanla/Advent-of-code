
hasher(x::Vector{UInt8}) = foldl((accum, xi)->(accum+xi)*UInt8(17), x; init=UInt8(0));
hash_accum(acc::UInt8, x::UInt8) = (acc+x)*UInt8(17);

comma(x) = x == UInt8(',');
d = read("input")
#d = collect(codeunits("rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7\n"));

function solve1(data)
    res = 0;
    accum::UInt8 = 0;
    for x in d
        x == UInt8('\n') && continue; #skip newlines
        if comma(x)
            res += accum;
            accum = UInt8(0);
        else 
            accum = hash_accum(accum, x);
        end
    end
    res + accum
end

println("$(solve1(d))");

#part 2

decode()

equalsop(box, lens) = 
minusop(box, lens) = 