
file = readlines("input")

pt1 = mapreduce(+, file) do line
    mapreduce(+, eachmatch(r"mul\(([1-9][0-9]?[0-9]?),([1-9][0-9]?[0-9]?)\)", line)) do m
        parse(Int,m[1])*parse(Int,m[2])
    end
end

print("pt1 = $pt1\n")

global enable = true

pt2 = mapreduce(+, file) do line
    mapreduce(+, eachmatch(r"mul\(([1-9][0-9]?[0-9]?),([1-9][0-9]?[0-9]?)\)|do(?:n't)?\(\)", line)) do m
        if m.match == "do()" 
            global enable = true
            0
        elseif m.match == "don't()"
            enable = false
            0
        else
            #print("$(m.match)")
            parse(Int,m[1])*parse(Int,m[2])*enable 
        end
    end
end

print("pt2: $pt2 \n")