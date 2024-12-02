
input = readlines("input");


function validate(l)
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
end

pt1 = map(input) do line 
    l = parse.(Int64, split(line, " "))
    validate(l)
end |> sum

#pt1 = sum(mapslices(test_line, input; dims=[2,]))

print("Pt1: $pt1\n")

#pt 2, the same, but we iterate over versions of the list skipping an element
#and result is true if any of them are true (as soon as any are true)

pt2 = map(input) do line 
    l = parse.(Int64, split(line, " "))
    if validate(l) 
        true
    else
        for i ∈ eachindex(l)
            if validate(vcat(l[begin:i-1],l[i+1:end]))
                return true
            end
        end
        false
    end
end |> sum

print("Pt2: $pt2\n")