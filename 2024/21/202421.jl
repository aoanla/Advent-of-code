#So, this is a "memoryless sequence" translation-to-translation multiple paths thing
# We want shortest sequences which means:

# repeated sequences of the same move are better than alternating moves (because repetition = "A" lots of times at the higher levels)
# "R" and "U" are better directions than "L" and "D" to end on (as they're adjacent to "A")
# the only exceptions to this are when we need a custom move to avoid the "blank spot"

#also, as this is memoryless, we only need to worry about optimising each transition between numbers - the whole sequence will then also be optimal.
# (That's just 11x10 = 110 sequences that need to be optimal, some of which are trivial - all the one-move ones, for example)

row(n) = (n-1)÷3 #[bottom to top]
col(n) = (n-1)%3 #[l to r]


function numpad_(src, dest)
    if (src > 0) & (dest > 0)
        rowdiff =  row(dest) - row(src) 
        coldiff =  col(dest) - col(src)
        rowmove = (rowdiff > 0 ? "^" : "v") ^ abs(rowdiff)
        colmove = (coldiff > 0 ? ">" : "<") ^ abs(coldiff)
        #if colmove is -ve, we absolutely need the lefts first
        coldiff > 0 ? rowmove*colmove : colmove * rowmove
        #coldiff < 0 ? colmove * rowmove : rowmove * colmove 
        #else we prefer right over down, and don't care (? maybe?) about right v up so try simple approach of always col second so right is last   
    elseif src == -1 #A
        dest == 0 && return "<"
        if col(dest) == 2 #same row as us
            "^" ^ (row(dest)+1)
        elseif col(dest) == 1 #one left 
            "<" * "^" ^ (row(dest)+1)
        else #2 left 
            "^" ^ (row(dest)+1) * "<<" #minimising transitions, and putting up with l being last to avoid the transitions
        end
    elseif src == 0
        dest == -1 && return ">" 
        if col(dest) == 1 #same row as us
            "^" ^ (row(dest)+1)
        elseif col(dest) == 0 #one left 
            "<" * "^" ^ (row(dest)+1)
        else #1 right 
            ">" * "^" ^ (row(dest)+1) #minimising transitions, and putting up with l being last to avoid the transitions
        end
    elseif dest == -1 #A
        #must be 1-9 by now by elimination 
        ">" ^ (2-col(src)) * "v" ^ (row(src)+1)
    else #dest == 0 by elimination
        ( col(src) == 0 ? "<" : ( col(src) == 2 ? ">" : "" ) ) * "v" ^ (row(src)+1)
    end
end 

#numpad transitions
#SRC DEST SEQ
numpad = fill("",(11,11))

#square numpad transitions can be algorithmic
for src ∈ -1:9, dest ∈ -1:9
    numpad[src+2,dest+2] = numpad_(src,dest) * "A"
end

#keypad transitions
#SRC DEST SEQ
keypad = Dict([
"^^"=>"A"
"<<"=>"A"
">>"=>"A"
"vv"=>"A"
"AA"=>"A"
"^A"=>">A"
"^v"=>"vA"
"^>"=>"v>A"
"^<"=>"v<A"  #not the most efficient, as we need to avoid The Gap
"<v"=>">A"
"<>"=>">>A"
"<^"=>">^A"  #this actually is the most efficient, despite the Gap, as we end on a ^
"<A"=>"^>>A" #is this the most efficient, considering higher order routing? - > the "official" order might endup being ">^>" given the below
"v<"=>"<A"
"v>"=>">A"
"v^"=>"^A"
"vA"=>"^>A"  #is there anything to call between these two? I feel like ^> might actually be better for future move reasons
"><"=>"<<A"
">v"=>"<A"
">^"=>"<^A"  #up last as closest to A
">A"=>"^A"
"A^"=>"<A"
"A>"=>"vA"
"Av"=>"<vA" #left is worse to end on
"A<"=>"<<vA" #left is worse, but repetition is better than no reps - the "official" mapping is not "v<<" but "<v<", ridiculously
])

mapping(chr) = chr == 'A' ? Int8(-1) : parse(Int8, chr) 

function parse_str(str)
    mapping.(collect("A"*str)) #don't forget our starting A position
end

#test = parse_str("379A")

#print("$test\n")

function npad_kpad(seq)
    l = length(seq)
    out = ""
    for i ∈ 1:l-1
        out = out * numpad[seq[i]+2,seq[i+1]+2]
    end
    out 
end

function kpad_kpad(seq)
    l = length(seq)
    internal = "A" * seq
    out = "" 
    for i ∈ 1:l
        out = out * keypad[internal[i:i+1]]
    end 
    out 
end 

#one = npad_kpad(test)
#print("$(one)\n")
#two = kpad_kpad(one)
#print("$(two)\n")
#three = kpad_kpad(two)
#print("$(three) - $(length(three))\n")
#this is frustrating because the mapping seems to be *different* for the final mapping for the official answer... 
# (A< -> A<v<A but if we use this in previous mappings we get a mapping that's "too long", as v<< is still the optimal path for previous ones)
#print("$(three[18:20] == "<vA<AA>>^AvAA<^A>A<v<A>>^AvA^A<vA>^A<v<A>^A>AAvA^A<v<A>A>^AAAvA<^A>A"[18:20])")

count = 0
for i ∈ readlines("input")
    line = parse_str(i)
    num = parse(Int64, i[1:end-1])
    final = foldl((x,i)->kpad_kpad(x), 1:2; init=npad_kpad(line))
    l = length(final)
    val = l*num
    print("$l * $(num) = $val\n")
    global count += val 
end 

print("Total Pt1: $count\n")

#naive pt2 for exploration of behaviour (should be 1:25 but this of course too slow for practical exploration)
count = 0
for i ∈ readlines("input")
    line = parse_str(i)
    num = parse(Int64, i[1:end-1])
    final = foldl((x,i)->kpad_kpad(x), 1:5; init=npad_kpad(line))
    l = length(final)
    val = l*num
    print("$l * $(num) = $val\n")
    global count += val 
end 

print("Total Pt2: $count\n")

#so, patterns grow (as we expected) very quickly - 2 iterations gets us to ~70, 3 to ~170, 5 to ~1000
# this is a "extrapolate the fixed points etc of the repeated function application" problem for pt2