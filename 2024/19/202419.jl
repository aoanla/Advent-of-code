#this looks like subsequence matching [with backtracking] like soln for 17pt2. 
#in this case, we probably need to memoise to make it tractable.

#note - my input sequence, at least, has 4 of 5 colours as single letters (just missing a 'w'), so all sequences with no 'w' are trivially possible.
#       it's also worth noting that this means that *several* of the longer sequences can be decomposed into shorter ones already

#we probably want to order the matchable subsequences by length, and by first letter?, and try to greedily match the longer ones first (and then backtrack if the
# remaining parts of the string can't match things)

#we can memoise successful combinations of subsequences (and mark them as "not original" in the dictionary), and also memoise failed ones to save time. 

#is equality testing more efficient (if we map the sequences to octal values, we can just do numeric comparison)

Dict{Int64,Set{String}}