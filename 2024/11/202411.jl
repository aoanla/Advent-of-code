#this probably does need an efficient 64-bit log10 for digit counts

const lookup_table::Vector{Int64} = [ (10^x -1) for x ∈ 1:18 ]

integer_log10(x::Int64) = begin
    raw = ((64-leading_zeros(x))*20) >> 6
    raw + (x>lookup_table[raw])
    end

#we of course could implement an 128bit version if we needed to


#stones are most efficiently in a linked list


function step!(stones, n)
    for stone ∈ stones
        if stone == 0
            stone = 1
        else
            stonedigits = integer_log10(stone)
            if iseven(stonedigits)
                cutoff = 10^(stonedigits÷2)
                stone = stone ÷ cutoff
                next_stone = stone % cutoff
                n += 1 
                insert!(next_stone, after_stone) #such that we skip it this time...
            else 
                stone = stone * 2024 #I don't think any of the cycles can make this > 2^63...
            end
        end
    end
    n
end 

n = len(stones)
for i ∈ 1:25 
    n = step(stones, n)
end

print("Pt1: $n")