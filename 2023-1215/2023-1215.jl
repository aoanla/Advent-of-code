
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

boxes = [ Vector{Tuple(Vector{UInt8}, UInt8)}() for i in 1:255 ];
equality(x,y) = x.first == y.first 
decode()

function equalsop!(box, lens)  
    posn = findfirst( label equality);
    isnothing(posn) ? append!(box, lens) : box[posn] = lens ; 
end

function minusop(box, lens)
    out = []
    for bi in eachindex(box)
        if equality(bi, lens) 
            append!(out, box[bi+1:end]);
            break;
        end
        push!(out, box[bi]);
    end
    box = out ; #sufficient copy?
end