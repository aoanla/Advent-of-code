#this is a classical xorshift PRNG. I hope we're not going to be expected to reverse them in pt2!

function xorshift(x::Int64)
    x = ((x << 6) ⊻ x) & 16777215
    x = ((x>>5) ⊻ x) & 16777215
    ((x<<11) ⊻ x) & 16777215
end

n_xorshifts(x::Int64, n) = foldl((x,i)->xorshift(x), 1:n; init=x)

pt1 = mapreduce(x->n_xorshifts(x,2000), +, parse.(Int64, readlines("input")))

print("pt1: $pt1\n")

#okay so part2 isn't what I was dreading - it's a maximisation problem on sequence matching 
#intuition suggests that we need to combine "popular subsequences" with "subsequences followed by big numbers".
# we have about 1.5k sequences, each with 2k differences