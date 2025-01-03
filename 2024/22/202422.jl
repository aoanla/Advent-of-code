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

# I do worry that we're supposed to do something clever knowing that we only care about the deltas in the lowest 4 bits of each sequence.
# since the low bits of "pure" xorshift PRNGs are known weak.
#ah, actually we do know this - the left-shifted xors only touch the upper bits - because they're all zero below 64 | 2048. 
#                               so each time the *lower* bits follow a pattern of x ⊻ (x' >> 5) where x' is x ⊻ (x << 6)
#                                                                                 x ⊻ (x >> 5 ⊻ x << 1)
# not sure if this is actually helpful, but it does mean we can expect low entropy and a lot of repeating patterns in our sequences once processed 

encode(x) = foldl((n,i)->(n<<6)+i, x; init=0)
function pt2()
    seq_totals = fill(0, 9586981) #the sequences, encoded a little lossily as 4 x 5bit values
    buffer = fill(true,9586981)
    for seed ∈ parse.(Int64, readlines("input"))
        #repeat buffer, true if we've not met this sequence before for this seed 
        fill!(buffer, true)
        oldn = seed
        oldn10 = seed % 10 
        seq = fill(0,4) #Vector{Int64}() #would be faster to use a ringbuffer of size 4 (index (n+i)%4 +1 where i is our loop number and n is the index we want)
        for i ∈ 1:3 #fill first seq value - nothing until we have this many diffs
            n = xorshift(oldn)
            n10 = n %10 
            x = n10 - oldn10 
            seq[i] = x+18
            #push!(seq, x+18)
            oldn = n
            oldn10 = n10
        end
        for i ∈ 4:2000
            n = xorshift(oldn)
            n10 = n % 10 
            x = n10 - oldn10 
            seq[(i+3)%4+1] = x+18

            index = encode([seq[(i+n)%4+1] for n ∈ 0:3]) + 1
            if buffer[index] 
                seq_totals[index] += n10 #add the increment for this seed for this sequence
                buffer[index] = false
            end
            oldn = n
            oldn10 = n10
        end
    end
    seq_totals
end

seq_totals = pt2()
#sort!(seq_totals)
print("$(maximum(seq_totals))\n")
