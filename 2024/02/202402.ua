⊜(⊜⋕ ⊸≠ @ )⊸≠@\n &fras "inputcopy"
#above doesn't work for lines of different lengths, so I need to box them and unbox them probably

# d2 = chop off last elem
# d1 = chop off first elem
# d = difference of pairs of d1,d2

# c calculate all the tests 
# c1 = number of elems abs(>3)
# c2 = number of elems =0
# c3 = number of elems rising or falling
#      c3a num of elems falling (0 are >0)
#      c3b num of elems rising (num >0 == len of list)

# b + twice to sum all three
# a count number of values = 0 (didn't fail any tests)

# a  b   c     c1      c2    c3  c3a    c3b        d    d1       d2      
/+=0++≡⊃⊃(≠0/+>3⌵)(≠0/+=0)(×⊃(≠0/+◌)(≠/+:)⧻.>0)≡-⊃(≡↘1)(≡⍜⇌(↘1))
