
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

boxes = [ Vector{Tuple{Vector{UInt8}, UInt8}}() for i in 1:256 ];
equality(x,y) = x[1] == y[1] 




function equalsop!(box, lens)  
    posn = findfirst(x->x[1]==lens[1],box);
    isnothing(posn) ? push!(box, lens) : box[posn] = lens ; 
end

function minusop!(box, label)
    out = []
    for bi in eachindex(box)
        if box[bi][1] == label 
            append!(out, box[bi+1:end]);
            break;
        end
        push!(out, box[bi]);
    end
    copy!(box, out) ; #sufficient copy?
end

function decode!(d)
    accum::UInt8 = 0;
    label = UInt8[];
    for x in d
        x == UInt8('=') && continue; #we know it's equals from the fact there's a digit next
        if x == UInt8('-')
            minusop!(boxes[accum+1], label); #julia 1-based indexing
            break;
        end
        if x < UInt8(':') #digit
            equalsop!(boxes[accum+1], (label, x-UInt8('0')))
            break;
        end
        accum = hash_accum(accum, x);
        push!(label, x);
    end
end

function decode_line!(d)
    srt = 1
    com = findfirst(comma, d);
    while !isnothing(com)
        decode!(d[srt:com]);
        srt = com + 1;
        com = findnext(comma, d, srt);
    end
    decode!(d[srt:end]);
end

decode_line!(d)

#=
accum = 0
for i in eachindex(boxes)
    accum += i * mapreduce( x-> x[1]*x[2][2],  + , enumerate(boxes[i]));
end
=#

accum = mapreduce(+, enumerate(boxes)) do (i,box)
    #println("$box");
    i * mapreduce( x-> x[1]*x[2][2],  + , enumerate(box); init=0);
end

println("$accum");