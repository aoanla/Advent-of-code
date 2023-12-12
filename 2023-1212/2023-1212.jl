# No time to really write code for this but some notes


# obviously the combinatrical "try every possible ? as a # or a ." is stupid and won't work.

#I think we need to use sliding windows of each "number of consecutives" to break this down into combinatrically sensible units.
# as the "number of consecutives" need to end on a ., an N means a window of N+2 [where we start the *next* window on the 
# final element - the "space" - of the previous one]

#it's tempting to try to optimise this more by starting with the "hardest to match" window (== the longest one)
# but if that's in the middle, we would also need to check the space left on either side to hold the remaining windows

#obviously, to make the windows easy, we extend each vector of #?. by one . start and end so our window edges fit.