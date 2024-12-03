#work in progress for non brute-force-ish version
input = readlines("input");

#return v, the index of the first failing element

#if dampener = true, recurse (with dampener = false)
# when we hit a problem, removing each of the two possible issues (li and newli) to
# see if either fixes the problem.
function validate(l; dampener = false)
    (oldli,nxt) = iterate(l)
    (li, nxt) = iterate(l,nxt)
    olddiff = li - oldli
    if abs(olddiff) > 3 || abs(olddiff) == 0
        dampener || return false  #or 2 
        return validate(l[2:end]) | validate(vcat(l[1:1],l[3:end]))   
    end
    while !isnothing(iterate(l,nxt))
        (newli, nxt) = iterate(l,nxt)
        diff = newli - li 
        if abs(diff) > 3 || diff == 0 
            dampener || return false
            #we *could* just validate the tail here, but I don't need the extra efficiency
            return validate(vcat(l[begin:nxt-2],l[nxt:end])) | validate(vcat(l[begin:nxt-1],l[nxt+1:end]))
        end
        if  diff*olddiff < 0
            dampener || return false
            #there's a special case here where the *first* diff is the wrong sign
            #but makes everything else look wrong as a result which we don't handle
            if nxt == 4 #we're testing the *second* diff (2,3)[olddiff is the first]
                return validate(l[2:end]) | validate(vcat(l[1:1],l[3:end])) | validate(vcat(l[1:2],l[4:end]))
            end
            #we *could* just validate the tail here, but I don't need the extra efficiency
            return validate(vcat(l[begin:nxt-2],l[nxt:end])) | validate(vcat(l[begin:nxt-1],l[nxt+1:end]))
        end
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
    validate(l; dampener = true)
end |> sum

print("Pt2: $pt2\n")