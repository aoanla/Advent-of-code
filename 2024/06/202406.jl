#read file, find coords of the posts 

#it's going to be worth the upfront cost because then "lines" are just finding the next post you collide with from a small pool
#(and lengths are just subtraction)

#set of points
s = Set{(Int32,Int32)}()
strt = (nothing,nothing)
for (y, l) ∈ enumerate(readlines("input"))
    for (x,ch) ∈ enumerate(collect(l))
        ch == '#' && push!(s, (x,y))
        if ch == '^'
            global strt = (x,y)
        end 
    end
end

dir = (-1,0) #up, unless I have my grid rotated
#utility for right-ward rotation, assuming my axes are the right way around
rotate(d) = (d[2], d[1]*-1)

#or via lambdas for match (<, ==), (==, >), (>, ==), (==, <)

while (there's a match)
    nextpost = filter(match, s)
    rotate(dir)
    length += (linelength) - (intersections with existing lines)
end
