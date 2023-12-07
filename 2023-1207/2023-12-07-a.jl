
#part 1 &2
using Printf

#map to nybbles so we can pidgeonhole principle the classifer
const cardtohex = Dict{Char,UInt64}('2'=>0x1, '3'=>0x10, '4'=>0x100, '5'=>0x1000, '6'=>0x10000,
                     '7'=>0x100000, '8'=>0x1000000, '9'=>0x10000000, 'T'=>0x100000000, 'J'=>0x1000000000,
                     'Q'=>0x10000000000, 'K'=>0x100000000000, 'A'=>0x1000000000000);

#mapping for pt2
const cardtohextwo = Dict{Char,UInt64}('J'=>0x1, '2'=>0x10, '3'=>0x100, '4'=>0x1000, '5'=>0x10000,
                     '6'=>0x100000, '7'=>0x1000000, '8'=>0x10000000, '9'=>0x100000000, 'T'=>0x1000000000,
                     'Q'=>0x10000000000, 'K'=>0x100000000000, 'A'=>0x1000000000000);



struct Hand
    hand::Vector{UInt64}
    value::Int16
    bid::Int32 
end

#                  low nybble        high nybble, shift right 
# note this also adds 1 for every zero nybble     
hilonybble(x) = 4^(x & 0x0f)   +   4^((x & 0xf0 ) >> 4) ; 

function classify(hand)
    counts = sum(hand); #we like the pidgeonhole sorting principle - a UInt64 has enough nybbles in it that we can assign one to each possible card type
    #this next bit could be SIMDified which is why chose this approach
    sum(hilonybble.(reinterpret(UInt8, [counts])))
end

const FiveK = classify(map(x->cardtohex[x], collect("AAAAA")));
const FourK = classify(map(x->cardtohex[x], collect("AAAAK")));
const ThreeK = classify(map(x->cardtohex[x], collect("AAAKQ")));
const FH = classify(map(x->cardtohex[x], collect("AAAKK")));
const Pair = classify(map(x->cardtohex[x], collect("AAKQJ")));
const TwoPair = classify(map(x->cardtohex[x], collect("AAKKJ")));
const High = classify(map(x->cardtohex[x], collect("AKQJT")));
#lookup jmap values below
const High1 = classify(map(x->cardtohex[x], collect("A")));
const High2 = classify(map(x->cardtohex[x], collect("AK")));
const High3 = classify(map(x->cardtohex[x], collect("AKQ")));
const High4 = classify(map(x->cardtohex[x], collect("AKQJ")));
const FourK4 = classify(map(x->cardtohex[x], collect("AAAA")));
const ThreeK4 = classify(map(x->cardtohex[x], collect("AAAK")));
const ThreeK3 = classify(map(x->cardtohex[x], collect("AAA")));
const Pair4 = classify(map(x->cardtohex[x], collect("AAKQ")));
const Pair3 = classify(map(x->cardtohex[x], collect("AAK")));
const Pair2 = classify(map(x->cardtohex[x], collect("AA")));
const TwoPair4 = classify(map(x->cardtohex[x], collect("AAKK")));
const Empty = classify(map(x->cardtohex[x], collect("")));


jmap = zeros(UInt16,FiveK);  #thankfully no collisions
jmap[Empty] = FiveK; #5K from 5Js
jmap[High1]  = FiveK;     #5K from 4Js
jmap[High2] = FourK; #4K from 3Js and uniques
jmap[Pair2] = FiveK;     #5k from 3Js and a Pair
jmap[High3] = ThreeK; #3K from 2Js and uniques
jmap[Pair3] = FourK; #4K from 2Js and a Pair
jmap[ThreeK3] = FiveK;     #5K from 2Js and 3K
jmap[High4] = Pair; #Pair from J and uniques
jmap[Pair4] = ThreeK;  #3K from J and Pair 
jmap[TwoPair4] = FH; #FH from J and 2Pair
jmap[ThreeK4] = FourK;  #4K from J and 3K 
jmap[FourK4] = FiveK;    #5K from J and 4K


function splitjs(hand)
    hnojs = filter(iseven, hand); #because j = 1 and all other values must be even
    (hnojs, 5-length(hnojs))  #max length is 5 so js = 5-notjs
end

function classifypt2(hand)
    #remove js
    (handnojs, jcount) = splitjs(hand);
    if jcount == 0 #early return
        classify(handnojs)
    else
        starting_value = classify(handnojs); #value of hand without js
        jmap[starting_value]  #lookuptables (mostly sparse)
    end
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
    handsp2 = Vector{Hand}();
    for line in eachline(f)
        (handc,bidc) = split(line," ");
        hand = map(x->cardtohex[x], collect(handc));
        hand2 = map(x->cardtohextwo[x], collect(handc));
        value = classify(hand); #the hard bit
        value2 = classifypt2(hand2); #harder!
        bid = parse(Int64,bidc);
        push!(hands,Hand(hand,value,bid));
        push!(handsp2, Hand(hand2, value2, bid));
    end
    sort!(hands, lt=handcmp);
    sort!(handsp2, lt=handcmp);
    partone = foldl(+,handbid.(enumerate(hands)));
    parttwo = foldl(+,handbid.(enumerate(handsp2)));
    println("Part one: $partone");
    println("Part two: $parttwo");

end
    