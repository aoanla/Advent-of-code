#read file, find coords of the posts 

#boring walking the grid version (yawn)

const offset = ((-1,0),(0,1),(1,0),(0,-1))


#set of points

grid = permutedims(reduce(hcat, collect.(readlines("input"))))
loc = Tuple(findfirst(==('^'),grid))

rotate(d) = begin 
    d = (d+1) % 4  
    d == 0 ? 4 : d #annoying zero indexing workaround 
end


function pt1(loc, grid)

    dir = 1
    n = 0
    #or via lambdas for match (<, ==), (==, >), (>, ==), (==, <)
    history = Set([loc])
    while true
        nxtloc = loc .+ offset[dir]
        !checkbounds(Bool,grid, nxtloc...) && break #escape
        if grid[nxtloc...] == '#'
            dir = rotate(dir)
            continue  #rotate
        end
        push!(history, nxtloc)
        loc = nxtloc
        n += 1
    end
    #add final line to boundary
    history
end

path = pt1(loc, grid)
print("Pt1 = $(length(path))\n")

#pt2 

function find_loop(loc, grid)

    dir = 1
    #or via lambdas for match (<, ==), (==, >), (>, ==), (==, <)
    history = Set([(loc,dir)])
    while true
        nxtloc = loc .+ offset[dir]
        !checkbounds(Bool,grid, nxtloc...) && return false #no loop, as we escaped
        if grid[nxtloc...] == '#'
            dir = rotate(dir)
            continue  #rotate
        end
        (nxtloc, dir) ∈ history && return true #loop as we have been this way in this direction before
        push!(history, (nxtloc, dir))
        loc = nxtloc
    end
    #add final line to boundary
    history
end

#not the first point, but all the others
tot = 0
for pt ∈ setdiff(path, loc) #don't check the starting location!
    grid[pt...] = '#'
    global tot += find_loop(loc,grid)
    grid[pt...] = '.'
end
 
print("Pts2 = $(tot)\n")