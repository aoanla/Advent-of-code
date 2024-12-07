### this is a recursive descent problem (you start assuming + everywhere as that's the lowest answer, and then try a * in the leftmost position and so on)
### recursion on substrings is probably the "clever" thing you need to do - but there's other optimisations for pt1 
#### (for. ex. as +,* commute, you can check the * positions from the left and right in parallel with a reversed string passed to the same func
####           2: the closer to the middle a * is, the larger the answer, so if we ever go > the target with our first new * (and +++ in the rhs), we can quit)
####           3: we can memoise all the substrings of (+,+,+) from the right to make that sub-calc a lookup not lots of + )

struct item
    target::Int64 
    elems::Vector{Int64}
    memo::Vector{Int64}
    revmemo::Vector{Int64}
end

probs = map(readlines("inputtest")) do l
    s,p = split(l,':')
    p = parse.(Int64,collect(split.(p)))
    revmemo = cumsum(p)
    memo = reverse(cumsum(reverse(p))) #making use of commutivity of + = these are the sums for the *rhs* fragments, for a given position 
    item(parse(Int64,s),p, memo, revmemo)
end

print("$probs")

for i ∈ probs 
    i.target < first(i.memo) && continue #if even the total sum > target, nothing else will get us an answer 
    for p ∈ 1:length(i.memo)
        #try asterisk positions - l to r, using memo, revmemo to avoid recomputation 
        #recurse into subproblems for extra asterisks, where subproblem is (currentstate, [...rest of problem])
    end
end

