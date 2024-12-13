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


#stones are most efficiently in a linked list
#but I guess we could make a counting-queue version


function step!(stones, n)
    oldn = n
    for _ ∈ 1:oldn
        stone = dequeue!(stones)
        if stone == 0
            enqueue!(stones, 1)
        else
            stonedigits = integer_log10(stone)
            if iseven(stonedigits)
                cutoff = 10^(stonedigits÷2)
                enqueue!(stones, stone ÷ cutoff)
                enqueue!(stones, stone % cutoff)
                 #such that we skip it this time...
                n+=1 
            else 
                enqueue!(stones, stone * 2024) #I don't think any of the cycles can make this > 2^63...
            end
        end
    end
    n
end 

stones = Queue{Int64}()
parse.(Int64, split(readline("input")," ")) |> Base.Fix1(foreach, x->enqueue!(stones, x) )


n = length(stones)
orig = n
for i ∈ 1:25 
    oldn = n
    global n = step!(stones, n)
    print("$(i): $n $(n/oldn)\n")
end
twentyfive = n
print("Pt1: $n $(n/orig)\n")

#50 more steps - becomes too big for memory, so we clearly have to extrapolate instead?
for i ∈ 1:10
    oldn = n
    global n = step!(stones, n)
    print("$(25+i): $n $(n/oldn) - extrapolate = $(twentyfive * 1.5183306^10)\n")
end

print("35/1: $(n/orig)\n")
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
