using DataStructures
#for Queue data structure

#this probably does need an efficient 64-bit log10 for digit counts

const lookup_table::Vector{Int64} = [ (10^x -1) for x ∈ 1:18 ]

integer_log10(x::Int64) = begin
    x < 10 && return 1
    raw = ((64-leading_zeros(x))*20) >> 6 
    raw + (x>lookup_table[raw])
    end


#we of course could implement an 128bit version if we needed to

#see discussion at end: we probably gain a lot by *counting* populations of stones of each number
#as we'll have *loads* of 0,2,4,8 etc stones by the end.

#this also means that a dictionary is the best storage, since we don't *actually* need to worry about
#the "order preservation" that Eric tells us about as a red-herring. (stones never merge so who cares)

function newstone(stone)
    if stone == 0
        [1]
    else
        stonedigits = integer_log10(stone)
        if iseven(stonedigits)
            cutoff = 10^(stonedigits÷2)
            [stone ÷ cutoff,stone % cutoff]
        else 
            [stone * 2024]
        end
    end
end

function step(stones)
    newdict = Dict{Int64, Int64}()
    for (k,v) ∈ pairs(stones)
        for kk ∈ newstone(k)
            newdict[kk]=get(newdict,kk,0)+v
        end 
    end 
    newdict
end 

stones = Dict{Int64,Int64}()
parse.(Int64, split(readline("input")," ")) |> Base.Fix1(foreach, x->stones[x]=1 )


for i ∈ 1:25 
    global stones = step(stones)
end
pt1 = sum(values(stones))
print("Pt1: $pt1\n")

#50 more steps - becomes too big for memory, so we clearly have to extrapolate instead?
for i ∈ 1:50
    global stones = step(stones)
end
pt2 = sum(values(stones))
print("Pt2: $pt2\n")

#geometric mean is ~1.5 - I think it's actually going to be 2 - (1/2.024) because
# if our multiplier was 1000, *all* odd-digit numbers would be even-digit next (and thus split)
# but here 1/2.024 of them will instead carry and get an extra digit.

#in any case, I think this *would* eventually work, in the limit, but isn't going to give us an
#exact answer that the question wants.

#thinking about the pattern of loops when you ×2024, it seems that a lot of numbers will
#eventually produce 0 (which then has a loop of 0->1->2024->[2,0,2,4]) producing lots of 
#0s, 2s, 4s (and other single digits)
#So *most* of the stones are going to be many [0-9] stones, all of which follow the same loop
#for a given timestep. It would be more efficient to just count populations and transform
#them that way
