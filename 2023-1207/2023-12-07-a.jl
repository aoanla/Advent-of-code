
#part 1 &2
using Printf

#map to nybbles so we can pidgeonhole principle the classifer
const cardtohex = Dict{Char,UInt64}('2'=>0x1, '3'=>0x10, '4'=>0x100, '5'=>0x1000, '6'=>0x10000,
                     '7'=>0x100000, '8'=>0x1000000, '9'=>0x10000000, 'T'=>0x100000000, 'J'=>0x1000000000,
                     'Q'=>0x10000000000, 'K'=>0x100000000000, 'A'=>0x1000000000000);


struct Hand
    hand::Vector{UInt64}
    value::Int16
    bid::Int32 
end

#                  low nybble        high nybble, shift right      
hilonybble(x) = 4^(x & 0x0f)   +   4^((x & 0xf0 ) >> 4) ; 

function classify(hand)
    counts = sum(hand); #we like the pidgeonhole sorting principle - a UInt64 has enough nybbles in it that we can assign one to each possible card type
    #this next bit could be SIMDified which is why chose this approach
    sum(hilonybble.(reinterpret(UInt8, [counts])))
end


function handcmp(hone,htwo) 
    hone.value != htwo.value && return hone.value < htwo.value ; 
    for (one,two) in zip(hone.hand,htwo.hand)
        one != two && return one < two ;
    end
    false
end

handbid(x) = x[1]*x[2].bid;

open("input") do f
    partone = 0
    hands = Vector{Hand}();
    for line in eachline(f)
        (handc,bidc) = split(line," ");
        hand = map(x->cardtohex[x], collect(handc) );
        value = classify(hand); #the hard bit
        bid = parse(Int64,bidc);
        push!(hands,Hand(hand,value,bid));
    end
    sort!(hands, lt=handcmp);
    partone = foldl(+,handbid.(enumerate(hands)));

    println("Part one: $partone");

end
    