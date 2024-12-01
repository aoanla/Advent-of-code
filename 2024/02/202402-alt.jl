#work in progress for non brute-force-ish version
input = readlines("input");

#return v, the index of the first failing element

#this is too complicated - I think what we actually do is recurse (with dampener = false)
# when we hit a problem, removing each of the two possible issues (li and newli) to
# see if either fixes the problem.
function validate(l; dampener = false)
    (oldli,nxt) = iterate(l)
    (li, nxt) = iterate(l,nxt)
    olddiff = li - oldli
    skip = false
    if abs(olddiff) > 3 || abs(olddiff) == 0
        dampener || return false  #or 2 
        skip = true   
        #not quite true as we also need to sort out if we're removing the 1st or 2nd elem...
    end
    #first loop, until first "break"
    skip || while !isnothing(iterate(l,nxt))
        (newli, nxt) = iterate(l,nxt)
        diff = newli - li 
        #there's a special case here where the *first* diff is the wrong sign
        #but makes everything else look wrong as a result which we don't handle
        if abs(diff) > 3 || diff == 0 
            dampener && break;
            return false;
        end
        if  diff*olddiff < 0
            if nxt == 4 #we're testing the *second* diff (2,3)[olddiff is the first]
                #so we need to check the *third* diff to see if olddiff is the wrong one
                (peek,_) = iterate(l, 4)
                if (peek-newli)*olddiff < 0 #olddiff is wrong, so we need to restart from 2,3
                    olddiff = diff #update diff, and then reset our loop nxt
                    li = newli
                end #diff is wrong, so we do want to skip it, and    
            end
            #this is a special case because we need to detect if olddiff is actually the wrong one
            dampener && break;
            return false;
        end
        #olddiff = diff - we're now counting violations rel to the first
        # I guess the problem here is that we don't know that the first diff isn't the "wrong" one
        # so we'd need to count the violations for diff sign separately (if *every other*
        # difference is opposite to the first, that's 1 violation)
        li = newli
    end
    #we only get here if we had a break - if this didn't happen in the first diff, 
    #then we can just skip to the next one. If it *did* happen in the first diff... 
    # we need to check if the issue is elems (1,2) or elems (2,3) if it's a sign issue
    #second loop, after "fixing" first break, if dampener set
    while !isnothing(iterate(l,nxt)) #"skips" an elem
        (newli, nxt) = iterate(l,nxt)
        diff = newli - li 
        #there's a special case here where the *first* diff is the wrong sign
        #but makes everything else look wrong as a result which we don't handle
        if abs(diff) > 3 || diff == 0 || diff*olddiff < 0
            return false
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