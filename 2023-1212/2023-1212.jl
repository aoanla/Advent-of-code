# No time to really write code for this but some notes


# obviously the combinatrical "try every possible ? as a # or a ." is stupid and won't work.

#I think we need to use sliding windows of each "number of consecutives" to break this down into combinatrically sensible units.
# as the "number of consecutives" need to end on a ., an N means a window of N+2 [where we start the *next* window on the 
# final element - the "space" - of the previous one]

#it's tempting to try to optimise this more by starting with the "hardest to match" window (== the longest one)
# but if that's in the middle, we would also need to check the space left on either side to hold the remaining windows

#obviously, to make the windows easy, we extend each vector of #?. by one . start and end so our window edges fit.

#so, from the left or the right:

#if from the left, the left of the window can be the sequence start - if we always ensure the next substring would start with a . (or ?) [which it would if the right 
of the window catches it but isn't included in the "match string" removed.]

#fn(substring)
# matches = 0;
# [try first match and recurse]
#
#while match(window_n, substring)
#   if not last window
#       if nothing_memoised
#           (matches, memoised_substring_lengths) += call fn(window_n+1, substring - [sequence we just consumed])
        else
            matches+= memoised_matches where substring <= current substring length
#   else
#       (matches, memoised_substring_length_at_match) += 1, match_length
#return ( matches, memoised_list_of_matches_by_substring)

#that seems relatively sensible?
#the matches are either just using regex or I could write a sliding-window thing myself if I cared

match(window_n, substring_start, string)
    for i in substring_start:length(string)-window_n
    #or
    i = substring_start
    while string[i] != '#' #we must match a *space* before this sequence starts
        #match if
        string[i] to string[i+window_n-1] != '.' 
        #and
        string[i+window_n] != '#'
        #and do
            #match++
            #push (i) => list_of_match_posns
            i+=1
