#read file, find coords of the posts 

#it's going to be worth the upfront cost because then "lines" are just finding the next post you collide with from a small pool
#(and lengths are just subtraction)

#set of points
s = Vector{Tuple{Int32,Int32}}()
loc = (nothing,nothing)
lines = readlines("inputtest")
for (x, l) ∈ enumerate(lines)
    for (y,ch) ∈ enumerate(collect(l))
        ch == '#' && push!(s, (x,y))
        if ch == '^'
            global loc = (x,y)
        end 
    end
end
boundaries = (length(lines), length(lines[1]))
#exit()



function intersect(a,b)
    #parallel so no intersection [if we're not looping] - if we are looping we check if the const bits are the same and then intersect the ranges
    a[3] == b[3] && return false
    #intersect if the "const" dir of each line is in the range of the other 
    #this is wrong for the intersection axes
    (a[1][a[3]] <= b[2][a[3]]) && (a[1][a[3]] >= b[1][a[3]]) && (b[1][b[3]] <= a[2][b[3]]) && (b[1][b[3]] >= a[1][b[3]])     
end

function pt1(s,loc)
    dirs = ((<,==),(==,>),(>,==),(==,<)) #up, unless I have my grid rotated
    axis = (1,2,1,2)
    offset = ((1,0),(0,-1),(-1,0),(0,1))
    #utility for right-ward rotation, assuming my axes are the right way around
    rotate(d) = begin 
        d = (d+1) % 4  
        d == 0 ? 4 : d #annoying zero indexing workaround 
    end
    dir = 1
    #or via lambdas for match (<, ==), (==, >), (>, ==), (==, <)
    history = [((-2,-2),(-1,-2),1)]
    tot = 1
    while true
        test(x) = reduce(&, broadcast.(dirs[dir] , x, loc))
        candidates = map(filter(test, s)) do cand
            (abs(cand[axis[dir]] .- loc[axis[dir]])-1, cand .+ offset[dir]) 
        end
        isempty(candidates) && break #actually need to add final line here to boundary
        (len,nextloc) =  minimum( candidates )
        line = (dir == 1 || dir == 4) ? (loc,nextloc, axis[dir]) : (nextloc,loc, axis[dir]) 
        dir = rotate(dir)
        inters = mapreduce(+, history) do c
            intersect(line, c)
        end
        tot += len - inters
        print("tot = $tot δ($len - $inters)\n")
        push!(history,line)
        loc = nextloc
    end
    #add final line to boundary
    nextloc = axis[dir] == 1 ? ( (dir==1 ? 0 : boundaries[1]+1) , loc[2]) : (loc[1],  (dir==4 ? 0 : boundaries[2]+1 )) 
    line = (dir == 1 || dir == 4) ? (loc,nextloc, axis[dir]) : (nextloc,loc, axis[dir])
    len = nextloc[axis[dir]] - loc[axis[dir]] 
    tot += len - mapreduce(+, history) do c
        intersect(line,c)
    end 
    tot
end

print("$(pt1(s,loc))")

