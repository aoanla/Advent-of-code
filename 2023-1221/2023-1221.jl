#This feels like the secret is to pop things off the "accessible" queue once you get a loop to them that's a power of 2 (since that means it will
#recur @ 64)

#so, you want a "nodes visited" dict with a "seen at" value 
#and a "nodes we're currently at" Set which we expand from each time
#and a "nodes with a period of 2^n" Set you push things into when you meet them again at the right time?

#with a rule that when you do the next "step update", you *don't* move to any nodes in the "period 2^n" list
# (which breaks those cycles and means that we don't grow an exponential number of nodes we're tracking at time t since we're pruning short cycles as we go)


#Further thought before going out to do other things: no, this is slightly more subtle than that: *all* points where we can reach them at an even timestep are in the set
# (because we can then trivially step off them and back into them endlessly until we get any other even number)
# - are there any odd points which are also in the set? anything we can orbit with an odd cycle ?