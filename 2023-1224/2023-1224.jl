# We've given sets of linear equations in t for x,y,z
# but we need to intersect just the lines (regardless of t) in x,y
## so need to make parametric in x,y

# Row     A, B, C @ D, E, F 

# x = A + Dt ; y = B + Et ; z = C + Ft 
# => x = A + (D/E)( y-B) = (A-B/E) + D/E (y) = α + βy

#
# then intersections between two sets are easy, just equate xs and solve for y
# x = α+βy , x'=α'+β'y  => α+βy = α'+β'y  iff β≠β' (parallel) -> y = (α-α')/(β'-β)
# (and x via either starting equation)
# check either x or y in the range we consider, and done