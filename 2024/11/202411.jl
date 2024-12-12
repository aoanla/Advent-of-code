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
for i ∈ 1:25 
    global n = step!(stones, n)
end

print("Pt1: $n\n")

#50 more steps - becomes too big for memory, so we clearly have to extrapolate instead?
for i ∈ 1:50
    global n = step!(stones, n)
end
print("Pt2: $n\n")
