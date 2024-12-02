using DelimitedFiles

input = readlines("input");

print("$(input[1,:])")


pt1 = map(input) do line 
    l = parse.(Int64, split(line, " "))  
    (oldli,nxt) = iterate(l)
    (li, nxt) = iterate(l,nxt)
    olddiff = li - oldli
    if abs(olddiff) > 3 || abs(olddiff) == 0
        return false
    end
    while !isnothing(iterate(l,nxt))
        (newli, nxt) = iterate(l,nxt)
        diff = newli - li 
        if abs(diff) > 3 || abs(diff) == 0 || diff*olddiff < 0
            return false
        end
        olddiff = diff
        li = newli
    end
    true
end |> sum

#pt1 = sum(mapslices(test_line, input; dims=[2,]))

print("$pt1")