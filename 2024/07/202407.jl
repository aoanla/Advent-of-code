### this is a recursive descent problem (you start assuming + everywhere as that's the lowest answer, and then try a * in the leftmost position and so on)
### recursion on substrings is probably the "clever" thing you need to do - but there's other optimisations for pt1 
#### (for. ex. as +,* commute, you can check the * positions from the left and right in parallel with a reversed string passed to the same func
####           2: the closer to the middle a * is, the larger the answer, so if we ever go > the target with our first new * (and +++ in the rhs), we can quit)
####           3: we can memoise all the substrings of (+,+,+) from the right to make that sub-calc a lookup not lots of + )