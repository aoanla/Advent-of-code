#this probably does need an efficient 64-bit log10 for digit counts

const lookup_table::Vector{Int64} = [ (10^x -1) for x ∈ 1:18 ]

integer_log10(x::Int64) = begin
    raw = ((64-leading_zeros(x))*20) >> 6
    raw + (x>lookup_table[raw])
    end

#we of course could implement an 128bit version if we needed to
print("$(integer_log10(12345678))")