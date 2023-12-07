
#part 1 &2

const cardtoval = Dict{Char,UInt32}('2'=>1, '3'=>2, '4'=>3, '5'=>4, '6'=>5, '7'=>6, '8'=>7, '9'=>8, 'T'=>9, 'J'=>10, 'Q'=>11, 'K'=>12, 'A'=>13);

const cardtovaltwo = Dict{Char,UInt32}('J'=>1, '2'=>2, '3'=>3, '4'=>4, '5'=>5, '6'=>6, '7'=>7, '8'=>8, '9'=>9, 'T'=>10, 'Q'=>11, 'K'=>12, 'A'=>13);

#reduce into separate hex values per card, leftmost value largest
handconcat(x) = foldl(x) do acc, card
    (acc << 4) + card
end


#map to nybbles so we can pidgeonhole principle the classifer
const cardtohex = Dict{Char,UInt64}('2'=>0x1, '3'=>0x10, '4'=>0x100, '5'=>0x1000, '6'=>0x10000,
                     '7'=>0x100000, '8'=>0x1000000, '9'=>0x10000000, 'T'=>0x100000000, 'J'=>0x1000000000,
                     'Q'=>0x10000000000, 'K'=>0x100000000000, 'A'=>0x1000000000000);

#mapping for pt2
const cardtohextwo = Dict{Char,UInt64}('J'=>0x1, '2'=>0x10, '3'=>0x100, '4'=>0x1000, '5'=>0x10000,
                     '6'=>0x100000, '7'=>0x1000000, '8'=>0x10000000, '9'=>0x100000000, 'T'=>0x1000000000,
                     'Q'=>0x10000000000, 'K'=>0x100000000000, 'A'=>0x1000000000000);



struct Hand
    value::UInt64
    bid::Int32 
end

#####
#####   In general, using nybbles is memory parsimonious but needs masks like this to do stuff efficiently.
#####   The SIMD version of this needs to use bytes (and UInt128 to hold them all) and then this is simplified.
#####
#                  low nybble        high nybble, shift right 
# note this also adds 1 for every zero nybble     
hilonybble(x) = UInt64(4)^(x & 0x0f)   +   UInt64(4)^((x & 0xf0 ) >> 4) ; 

    #counts = sum(hand); #we like the pidgeonhole sorting principle - a UInt64 has enough nybbles in it that we can assign one to each possible card type
    #this next bit could be SIMDified which is why chose this approach
classify(handbits) =  sum(hilonybble.(reinterpret(UInt8, [handbits])));

compact_h(hand_str) = sum(map(x->cardtohex[x], collect(hand_str)));
compact_htwo(hand_str) = sum(map(x->cardtohextwo[x], collect(hand_str)));

const FiveK = classify(compact_h("AAAAA"));
const FourK = classify(compact_h("AAAAK"));
const ThreeK = classify(compact_h("AAAKQ"));
const FH = classify(compact_h("AAAKK"));
const Pair = classify(compact_h("AAKQJ"));
const TwoPair = classify(compact_h("AAKKJ"));
const High = classify(compact_h("AKQJT"));
#lookup jmap values below
const High1 = classify(compact_h("A"));
const High2 = classify(compact_h("AK"));
const High3 = classify(compact_h("AKQ"));
const High4 = classify(compact_h("AKQJ"));
const FourK4 = classify(compact_h("AAAA"));
const ThreeK4 = classify(compact_h("AAAK"));
const ThreeK3 = classify(compact_h("AAA"));
const Pair4 = classify(compact_h("AAKQ"));
const Pair3 = classify(compact_h("AAK"));
const Pair2 = classify(compact_h("AA"));
const TwoPair4 = classify(compact_h("AAKK"));
const Empty = classify(compact_h(""));


jmap = zeros(UInt64,FiveK);  #thankfully no collisions
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


function classifypt2(handbits)
    #with them compacted, this is just a mask on the lower nybble
    jcount = handbits & 0x000000000000000f;
    handnojs = handbits & 0xfffffffffffffff0;
    if jcount == 0 #early return
        classify(handnojs)
    else
        starting_value = classify(handnojs); #value of hand without js
        jmap[starting_value]  #lookuptables (mostly sparse)
    end
end

function handcmp(hone,htwo) 
    hone.value < htwo.value #: hone.rawhand < htwo.rawhand 
end

handbid(x) = x[1]*x[2].bid;

open("input") do f
    hands = Vector{Hand}();
    handsp2 = Vector{Hand}();
    for line in eachline(f)
        (handc,bidc) = split(line," ");
        rawhand = handconcat(map(x->cardtoval[x], collect(handc)));  #faster to compact down into bitset ASAP, but we need the ordered list for tie breaks!
        rawhand2 = handconcat(map(x->cardtovaltwo[x], collect(handc)));
        # we *should* just get hand from rawhand directly by mapping nybble -> 16^(nybble-1) but iterating over nybbles is annoying
        # in the SIMD version of this I think we'd use bytes not nybbles and a UInt128
        hand = compact_h(handc);
        hand2 = compact_htwo(handc);
        value::UInt64= (classify(hand)<< 32 ) | rawhand ; #the hard bit
        value2::UInt64= (classifypt2(hand2) << 32 ) | rawhand2  ; #harder!
        bid = parse(Int64,bidc);
        push!(hands,Hand(value,  bid));
        push!(handsp2, Hand(value2, bid));
    end
    sort!(hands, lt=handcmp);
    sort!(handsp2, lt=handcmp);
    println("$(handsp2[end])");
    partone = sum(handbid.(enumerate(hands)));
    parttwo = sum(handbid.(enumerate(handsp2)));
    println("Part one: $partone");
    println("Part two: $parttwo");

end
    