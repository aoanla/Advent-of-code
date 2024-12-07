### this is a recursive descent problem (you start assuming + everywhere as that's the lowest answer, and then try a * in the leftmost position and so on)
### recursion on substrings is probably the "clever" thing you need to do - but there's other optimisations for pt1 
#### (for. ex. as +,* commute, you can check the * positions from the left and right in parallel with a reversed string passed to the same func
####           2: the closer to the middle a * is, the larger the answer, so if we ever go > the target with our first new * (and +++ in the rhs), we can quit)
####           3: we can memoise all the substrings of (+,+,+) from the right to make that sub-calc a lookup not lots of + )

struct item
    target::Int128 
    elems::Vector{Int128}
    memo::Vector{Int128}
#    revmemo::Vector{Int64}
end

probs = map(readlines("input")) do l
    s,p = split(l,':')
    p = parse.(Int128,collect(split.(p)))
    memo = reverse(cumsum(reverse(p))) #making use of commutivity of + = these are the sums for the *rhs* fragments, for a given position 
    item(parse(Int128,s),p, [memo ; 0])
end


function try_asterisk(i)
    max_ = length(i.elems) - 1
    accum = 0
    for p ∈ 1:max_
        accum += i.elems[p]
        #try asterisk positions - l to r, using memo to avoid recomputation
        lhs = accum * i.elems[p+1]
        rhs = i.memo[p+2]

        #lhs > i.target && return false #lhs already bigger than the answer - but if there's a terminal 1 (sigh) then we can still get a valid solution
        lhs + rhs == i.target && return true  #found a solution
        p == max_ && return false #can't recurse further, as already in the final position for an asterisk 

        #recurse into subproblems for extra asterisks, where subproblem is (currentstate, [...rest of problem])
        #is this function call right- are we accumulating wrong (accum + lhs double count?)
        try_asterisk( item(i.target, [lhs ; i.elems[p+2:end]], i.memo[p+1:end]) ) && return true

    end
    return false
end

valid = Vector{Int128}()
for i ∈ probs
    #i.target < first(i.memo) && print("sum case: $i\n") #values that are just 1 in the sum *do* reduce the total when multiplied so we can't early exit here
    if i.target == first(i.memo) #possible that we might have a solution for all sums
        push!(valid, i.target)
        continue
    end 
    try_asterisk(i) && push!(valid, i.target)
end

print("$valid, $(sum(valid))\n")

