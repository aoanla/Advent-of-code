### this is a recursive descent problem (you start assuming + everywhere as that's the lowest answer, and then try a * in the leftmost position and so on)
### recursion on substrings is probably the "clever" thing you need to do - but there's other optimisations for pt1 
#### (for. ex. as +,* commute, you can check the * positions from the left and right in parallel with a reversed string passed to the same func
####           2: the closer to the middle a * is, the larger the answer, so if we ever go > the target with our first new * (and +++ in the rhs), we can quit)
####           3: we can memoise all the substrings of (+,+,+) from the right to make that sub-calc a lookup not lots of + )

struct item
    target::Int64 
    elems::Vector{Int64}
    memo::Vector{Int64}
#    revmemo::Vector{Int64}
end

probs = map(readlines("inputtest")) do l
    s,p = split(l,':')
    p = parse.(Int64,collect(split.(p)))
    memo = reverse(cumsum(reverse(p))) #making use of commutivity of + = these are the sums for the *rhs* fragments, for a given position 
    item(parse(Int64,s),p, [memo ; 0])
end

print("$probs")

function try_asterisk(i, accum)
    max_ = length(i.elems) - 1
    for p ∈ 1:max_
        accum += i.elems[p]
        #try asterisk positions - l to r, using memo, revmemo to avoid recomputation
        lhs = accum * i.elems[p+1]
        rhs = i.memo[p+2]
        lhs + rhs == i.target && return true
        p == max_ && return false
        try_asterisk( item(i.target, [lhs ; i.elems[p+2:end]], i.memo[p+2:end]), accum ) && return true
        #recurse into subproblems for extra asterisks, where subproblem is (currentstate, [...rest of problem])
    end
    return false
end

valid = Vector{Int64}()
for i ∈ probs 
    i.target < first(i.memo) && continue #if even the total sum > target, nothing else will get us an answer
    try_asterisk(i, 1) && push!(valid, i.target)
end

print("$valid, $(sum(valid))")

