#read file, find coords of the posts 

#it's going to be worth the upfront cost because then "lines" are just finding the next post you collide with from a small pool
#(and lengths are just subtraction)
const dirs = ((<,==),(==,>),(>,==),(==,<)) #up, unless I have my grid rotated
const axis = (1,2,1,2)
const offset = ((1,0),(0,-1),(-1,0),(0,1))


#set of points
s = Vector{Tuple{Int32,Int32}}()
loc = (nothing,nothing)
lines = readlines("input")
for (x, l) ∈ enumerate(lines)
    for (y,ch) ∈ enumerate(collect(l))
        ch == '#' && push!(s, (x,y))
        if ch == '^'
            global loc = (x,y)
        end 
    end
end
const boundaries = (length(lines), length(lines[1]))
#exit()

rotate(d) = begin 
    d = (d+1) % 4  
    d == 0 ? 4 : d #annoying zero indexing workaround 
end

function intersect(a,b)
    #parallel so no intersection [if we're not looping] - if we are looping we check if the const bits are the same and then intersect the ranges
    a[3] == b[3] && return false
    #intersect if the "const" dir of each line is in the range of the other 
    tests =( (a[1][b[3]] <= b[2][b[3]]) , (a[1][b[3]] >= b[1][b[3]]) , (b[1][a[3]] <= a[2][a[3]]) , (b[1][a[3]] >= a[1][a[3]]) )    
    return reduce(&, tests)
end

function pt1(s,loc)
    #dirs = ((<,==),(==,>),(>,==),(==,<)) #up, unless I have my grid rotated
    #axis = (1,2,1,2)
    #offset = ((1,0),(0,-1),(-1,0),(0,1))
    dir = 1
    #or via lambdas for match (<, ==), (==, >), (>, ==), (==, <)
    history = [((-2,-2),(-1,-2),1, 1)]
    tot = 1
    while true
        test(x) = reduce(&, broadcast.(dirs[dir] , x, loc))
        candidates = map(filter(test, s)) do cand
            (abs(cand[axis[dir]] .- loc[axis[dir]]), cand .+ offset[dir]) 
        end
        isempty(candidates) && break #actually need to add final line here to boundary
        (len,nextloc) =  minimum( candidates )
        line = (dir == 2 || dir == 3) ? (loc,nextloc, axis[dir], dir) : (nextloc,loc, axis[dir], dir) 

        inters = mapreduce(+, history) do c
            intersect(line, c)
        end
        tot += len - inters
        push!(history,line)
        #find new direction, and start off with a single step to avoid intersection
        dir = rotate(dir)
        #need to check if we would step into a new barrier 
        # case:            ...# 
        #                  ...^# 
        # which actually results in a 180 degree turn
        if (nextloc .- offset[dir]) ∈ s 
            dir = rotate(dir)
        end
        loc = nextloc .- offset[dir]
    end
    #add final line to boundary
    
    nextloc = axis[dir] == 1 ? ( (dir==1 ? 1 : boundaries[1]) , loc[2]) : (loc[1],  (dir==4 ? 1 : boundaries[2] )) 
    line = (dir == 2 || dir == 3) ? ( loc, nextloc, axis[dir], dir) : (nextloc,loc, axis[dir], dir)
    len = nextloc[axis[dir]] - loc[axis[dir]] 
    inters = mapreduce(+, history) do c
        intersect(line,c)
    end 
    tot += len - inters
    push!(history,line) 
    (tot, history[2:end]) #not clear if we're supposed to ignore the first segment or just the first square
end

(pt_1, path) =  pt1(s,loc)
print("Pt1 = $pt_1\n")

#pt2 

#conditions - presumably can't be "on the initial line of the guard", not just where she is 

#we can extend the intersection checker to instead check for loops
#   in this case, we want path segments that *are* colinear, have the same const coord 
#       the same direction sense (> or <)
#       and whose variable coords overlap (or are the same)

# it might also be useful to memoise loops that *don't* include the obstruction we add
# as we can detect them faster that way

#(v1,v2,axis, sense) [sense is l-r or r-l ordering]
#dont need this in the end as I can just do a set comparison
function overlap(a,b)
    #perpendicular so no overlap, or antiparallel so no overlap, or not on same parallel axis 
    (a[3] != b[3] || a[4] != b[4] || a[1][3-a[3]] != b[1][3-a[3]]) && return false    
    #segments are on same line, but we need them to overlap along that line too - but this will be true if they have the same destination!
    a[a[4]][a[3]] == b[a[4]][a[3]]
end


function find_loop(s, loc, dir)
    #do mostly what pt1 does, but our "itersection" test is now a test for overlapping an existing element of the history, and we store a sense param for this
    #dirs = ((<,==),(==,>),(>,==),(==,<)) #up, unless I have my grid rotated
    #axis = (1,2,1,2)
    #offset = ((1,0),(0,-1),(-1,0),(0,1))
    #utility for right-ward rotation, assuming my axes are the right way around
    history = Set{Tuple{Int32,Int32,Int32}}()
    while true
        test(x) = reduce(&, broadcast.(dirs[dir] , x, loc))
        candidates = map(filter(test, s)) do cand
            (abs(cand[axis[dir]] .- loc[axis[dir]]), cand .+ offset[dir]) 
        end
        isempty(candidates) && return false #escape
        (len,nextloc) =  minimum( candidates )
        line = (nextloc[1], nextloc[2], dir)
        
        line ∈ history && return true #loop happened, as path segment is in history
        push!(history,line)
        #find new direction, and start off with a single step to avoid intersection
        dir = rotate(dir)
        #need to check if we would step into a new barrier 
        # case:            ...# 
        #                  ...^# 
        # which actually results in a 180 degree turn
        if (nextloc .- offset[dir]) ∈ s 
            dir = rotate(dir)
        end
        loc = nextloc .- offset[dir]
    end
        #add final line to boundary - don't care about this for pt2 as we don't need length
    true #just in case
end 


#we iterate through the history path

#set of obstacles that work
obs = Set{Tuple{Int32,Int32}}()
prevs = Set([loc]) #we shouldn't check the first square!


for segment ∈ path
    #get start,end, dir  
    dir = segment[4]
    bounce_dir = rotate(dir)
    #this, if we're not on the initial segment, needs to step back one to consider the start of the path in this direction
    (strt,end_, step) = (dir==2 || dir==3) ? (segment[1],segment[2], 1) : (segment[2], segment[1], -1)
    pts = isodd(dir) ? [(i,strt[2]) for i ∈ strt[1]:step:end_[1]] : [(strt[1],i) for i ∈ strt[2]:step:end_[2] ]
    for pt ∈ pts
        (pt ∈ prevs) && continue  #already tried this obstacle location - we can only hit it from one side (the first time we meet it on the path)
        push!(prevs, pt)
        find_loop(s ∪ [pt], pt .+ offset[dir], bounce_dir ) && push!(obs, pt)
    end
end
 
print("Pts2 = $(length(obs))\n")