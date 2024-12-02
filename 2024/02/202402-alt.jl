#work in progress for non brute-force-ish version
input = readlines("input");

#return v, the index of the first failing element
function validate(l)
    (oldli,nxt) = iterate(l)
    (li, nxt) = iterate(l,nxt)
    olddiff = li - oldli
    if abs(olddiff) > 3 || abs(olddiff) == 0
        return 1  #or 2?
    end
    while !isnothing(iterate(l,nxt))
        (newli, nxt) = iterate(l,nxt)
        diff = newli - li 
        #there's a special case here where the *first* diff is the wrong sign
        #but makes everything else look wrong as a result which we don't handle
        if abs(diff) > 3 || abs(diff) == 0 || diff*olddiff < 0
            return nxt-1 #the item that broke
        end
        #olddiff = diff - we're now counting violations rel to the first
        # I guess the problem here is that we don't know that the first diff isn't the "wrong" one
        # so we'd need to count the violations for diff sign separately (if *every other*
        # difference is opposite to the first, that's 1 violation)
        li = newli
    end
    0
end

pt1 = map(input) do line 
    l = parse.(Int64, split(line, " "))
    validate(l)
end |> (x -> x.==0) |> count

#pt1 = sum(mapslices(test_line, input; dims=[2,]))

print("Pt1: $pt1\n")

#pt 2, the same, but we iterate over versions of the list skipping an element
#and result is true if any of them are true (as soon as any are true)

pt2 = map(input) do line 
    l = parse.(Int64, split(line, " "))
    (v = validate(l)) == 0 && return true
    #second chance, removing the first failing element
    validate(vcat(l[begin:v-1],l[v+1:end])) == 0 && return true
    false
end |> sum

print("Pt2: $pt2\n")