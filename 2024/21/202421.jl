#So, this is a "memoryless sequence" translation-to-translation multiple paths thing
# We want shortest sequences which means:

# repeated sequences of the same move are better than alternating moves (because repetition = "A" lots of times at the higher levels)
# "R" and "U" are better directions than "L" and "D" to end on (as they're adjacent to "A")
# the only exceptions to this are when we need a custom move to avoid the "blank spot"

#also, as this is memoryless, we only need to worry about optimising each transition between numbers - the whole sequence will then also be optimal.
# (That's just 11x10 = 110 sequences that need to be optimal, some of which are trivial - all the one-move ones, for example)

row(n) = (n-1)÷3 #[bottom to top]
col(n) = (n-1)%3 #[l to r]

### got the test wrong for 0 as a destination (wrong true/false ordering)
function numpad_(src, dest)
    src == dest && return ""
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
             "^" ^ (row(dest)+1) * "<"  #constraint to avoid the gap
        else #1 right 
            ">" * "^" ^ (row(dest)+1) 
        end
    elseif dest == -1 #A
        #must be 1-9 by now by elimination   #I think this is possibly not optimal as r is better than d as a final move (and r->d transition is cheap)
        ">" ^ (2-col(src)) * "v" ^ (row(src)+1)
    else #dest == 0 by elimination           #similarly here, I think r *last* might be better than r first because repeated vv adds As 
        ( col(src) == 2 ? "<" : ( col(src) == 0 ? ">" : "" ) ) * "v" ^ (row(src)+1)
    end
end 

#numpad transitions
#SRC DEST SEQ
numpad = fill("",(11,11))

#square numpad transitions can be algorithmic
for src ∈ -1:9, dest ∈ -1:9
    numpad[src+2,dest+2] = numpad_(src,dest) * "A"
end

print("transition: 40 $(numpad_(4,0))\n")

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
"<A"=>">>^A" #is this the most efficient, considering higher order routing? - > the "official" order might endup being ">^>" given the below
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
"A<"=>"v<<A" #left is worse, but repetition is better than no reps - the "official" mapping is not "v<<" but "<v<", ridiculously
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
    internal = seq
    out = "" 
    for i ∈ 1:l-1
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
    num = parse(Int128, i[1:end-1])
    final = foldl((x,i)->kpad_kpad('A'*x), 1:2; init=npad_kpad(line)) #need a leading A for each seq as it is encoded 
    l = length(final)
    val = l*num
    print("$l * $(num) = $val\n")
    global count += val 
end 

print("Total Pt1: $count\n")

#naive pt2 for exploration of behaviour (should be 1:25 but this of course too slow for practical exploration)
#count = 0
#for i ∈ readlines("input")
#    line = parse_str(i)
#    num = parse(Int64, i[1:end-1])
#    final = foldl((x,i)->kpad_kpad('A'*x), 1:5; init=npad_kpad(line)) #need a leading A for each seq as it is encoded...
#    l = length(final)
#    val = l*num
#    print("$l * $(num) = $val\n")
#    global count += val 
#end 

#print("Total Pt2: $count\n")

#so, patterns grow (as we expected) very quickly - 2 iterations gets us to ~70, 3 to ~170, 5 to ~1000
# this is a "extrapolate the fixed points etc of the repeated function application" problem for pt2

#there's actually only a limited number of pairs that exist in our output (we listed them in our kpad mapper)
# - since we don't need the actual sequence, just the length, can we just turn these is to "pairs transition maps" and just
# count the number of each pairs that exist each iteration?

# no - because we wouldn't know the edges
# however - *all* our subsequences are bounded by As on the right, so we can always subdivide a given sequence by As [and track those sequences internally]
# we might just have to track the "leftmost" subsequence specially as it doesn't have an A to the left <-- this is false as we always need to add an A each 
# time for the starting position...



function kpad_pop_kpad(population)
    newpop = Dict{String,Int128}()
    for (k,v) ∈ pairs(population)
        newk = kpad_kpad('A'*k*'A') #adds the leading A automatically inside kpad_kpad
        for kk ∈ split(newk[1:end-1], 'A') #remove the terminal A to avoid a false empty set 
            newpop[kk] = get(newpop,kk,0) + v
        end 
    end
    newpop
end

function kpad_to_pop(keys)
    newpop = Dict{String,Int128}()
    subseqs = split(keys[1:end-1], 'A') #remove the terminal A to avoid a false empty set 
    for i ∈ subseqs[1:end] #the first subsequence also starts with an 
        newpop[i] = get(newpop, i, 0) + 1
    end 
    newpop
end 

#tested against pt1 soln for n = 2,3,4,5 and works - "too low" for pt2 apparently (and hard to verify of course)
count = Int128(0)
for i ∈ readlines("input")
    line = parse_str(i)
    num = parse(Int128, i[1:end-1])
    final = foldl((x,i)->kpad_pop_kpad(x), 1:25; init=kpad_to_pop(npad_kpad(line))) #need a leading A for each seq as it is encoded 
    l = mapreduce(+, pairs(final)) do (k,v)
        v * (length(k)+1) #+1 for the A that terminates it 
    end
    val = l*num
    print("$l * $(num) = $val\n")
    global count += val 
end 

print("Total Pt2: $count\n") #
#consider triplet sequences - we're never going to generate longer sequences without an A 
# (except from the numpad at the start - maybe there's some additional optimisation there)
# is it possible that we generate some sequences that are of different resulting length for the *next* robot (even with our careful curation)?

#resolution - we had < and > mixed up in the "0 as a destination" code [I should have just written everything out longhand because then I wouldn't make logic errors]
# moral of the story - my brain is better at doing a simple "logical ordering" problem than it is at writing too much code to do the same thing.