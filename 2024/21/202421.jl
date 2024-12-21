#So, this is a "memoryless sequence" translation-to-translation multiple paths thing
# We want shortest sequences which means:

# repeated sequences of the same move are better than alternating moves (because repetition = "A" lots of times at the higher levels)
# "R" and "U" are better directions than "L" and "D" to end on (as they're adjacent to "A")
# the only exceptions to this are when we need a custom move to avoid the "blank spot"

#also, as this is memoryless, we only need to worry about optimising each transition between numbers - the whole sequence will then also be optimal.
# (That's just 11x10 = 110 sequences that need to be optimal, some of which are trivial - all the one-move ones, for example)