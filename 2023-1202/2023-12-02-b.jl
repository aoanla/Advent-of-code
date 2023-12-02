
#part 2
open("input") do f
    accum = 0
    for line in eachline(f) 
        g_dict = Dict("red" => 0, "green" => 0, "blue" => 0)
        for substr in eachmatch(r"[:;]([^;]*)", line), numcol in eachmatch(r"([0-9]*) (red|green|blue)", substr.captures[1])
            num, col = numcol.captures
            nn = parse(Int,num)
            if nn > g_dict[col]
                g_dict[col] = nn
            end
        end
        accum += prod(values(g_dict))
    end
    println("$accum")
end

println("DONE")