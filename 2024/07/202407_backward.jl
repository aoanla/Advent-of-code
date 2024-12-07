## other approaches: we could try testing divisibility of the solutions from the right hand side (and "deconcating" them)
###  I'm not sure of the time trade off between division being slow and this easily discounting parts of the search space (it might pay off, but...)

### lets try the above

struct item
    target::Int64
    elems::Vector{Int64}
    memo::Vector{Int64}
#    revmemo::Vector{Int64}
end

probs = Set(map(readlines("input")) do l
    s,p = split(l,':')
    p = parse.(Int128,collect(split.(p)))
    memo = reverse(cumsum(p)) #making use of commutivity of + = these are the sums for the *rhs* fragments, for a given position 
    item(parse(Int128,s),reverse(p), [memo; 0])
end)

#print("$probs")

function try_asterisk(i)
    max_ = length(i.elems) - 1
    target = i.target
    for p ∈ 1:max_
        divisor = i.elems[p]
        target % divisor != 0 && return false #asterisk not possible here for all substrings as target is not divisible
        target_ask = target ÷ divisor
        target_ask == i.memo[p+1] && return true
        #and recurse 
        try_asterisk( item(target_ask, i.elems[p+1:end], i.memo[p+1:end]) ) && return true

        # we *loop* by subtracting the next element from p!!!
        target -= divisor
    end
    return false
end

valid = Set{item}()
for i ∈ probs
    #i.target < first(i.memo) && print("sum case: $i\n") #values that are just 1 in the sum *do* reduce the total when multiplied so we can't early exit here
    if i.target == first(i.memo) #possible that we might have a solution for all sums
        push!(valid, i)
        continue
    end 
    try_asterisk(i) && push!(valid, i)
end

pt1 = mapreduce(x->x.target, +, valid)

print("Pt1 = $(pt1)\n")

# Pt2 

function deconcat_p(x,y)
    places = floor(Int64,log10(y)) + 1
    (x % 10^places) == y
end

function try_ask_pipes(i)
    max_ = length(i.elems) - 1
    target = i.target

    for p ∈ 1:max_
        accum = i.elems[p]
        #try asterisk positions - l to r, using memo to avoid recomputation
        
        #this is instead a division test 
        t1 = target % accum == 0
        if t1 
            target_ask = target ÷ accum
            target_ask == i.memo[p+1] && return true #remainder are +s    
            try_ask_pipes( item(target_ask, i.elems[p+1:end], i.memo[p+1:end]) ) && return true
        end
        ###concat stuff 

        #try concat  - this should work now, because we removed the incorrect early return above
        #deconcat test:
        t2 = deconcat_p(target,accum)
        if t2 
            target_pipe = target ÷ 10^(floor(Int64,log10(accum)) + 1)  #deconcat 
            target_pipe == i.memo[p+1] && return true #remainder are +s
            try_ask_pipes( item(target_pipe, i.elems[p+1:end], i.memo[p+1:end])) && return true
        end
        #and recurse, if at least one path succeeded
        p == max_ && return false #can't recurse and out of options 

        # we *loop* by subtracting the next element from p!!!
        target -= accum
    end
    return false
end


#only test the ones we can't already solve!

remaining = setdiff!(probs, valid)

valid_2 = Set{item}()

for i ∈ remaining
    try_ask_pipes(i) && push!(valid_2, i)
end

#print("$valid_2")
print("Pt2 = $(mapreduce(x->x.target, +, valid_2)+pt1)\n")

