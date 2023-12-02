
#part 1
open("input") do f
    accum = 0
    g_dict = Dict("red" => 12, "green" => 13, "blue" => 14)
    for line in eachline(f) 
        digit = parse(Int, match(r"Game ([0-9]*):", line).captures[1])
        
        for substr in eachmatch(r"[:;]([^;]*)", line), numcol in eachmatch(r"([0-9]*) (red|green|blue)", substr.captures[1])
            num, col = numcol.captures
            if parse(Int,num) > g_dict[col]
                digit = 0
                break
            end
        end
        accum += digit
    end
    println("$accum")
end

println("DONE")