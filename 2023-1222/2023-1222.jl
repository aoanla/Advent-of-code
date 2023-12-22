#this is *YET ANOTHER RANGE INTERSECTION PUZZLE*
#I guess Eric thinks we're actually building libraries in the earlier days rather than trying to solve each puzzle from scratch 
#if we were doing that, this wouldn't be so vaguely repetitive?

#Anyway, 2d ranges like in Day 19 (which I still need to finish in Rust)
# brick lands on brick below if intersection of ranges. Iterate down the list until you hit one or more at same level
# tag all the bricks you land on with the *number* of bricks total you landed on 

#brick can be destroyed if none of its tags are 1 