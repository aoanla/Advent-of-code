#the trick here is that we need to efficiently determine if a barrel is "fixed" along an axis [because it impinges on a wall] or not
#we can do this by propagating fixedness from walls and having efficient updates on them as they update.


#a Cell can be fixed, hypothetically from *both* sides if there's a line of them between 2 walls 
#struct Cell
#    obs::Bool #is an obstruction
#    wall::Bool 
#    fixed_axes::Tuple{Bool,Bool}
#    fixed_from::Set{Tuple{Int8,Int8}} #can be fixed in multiple directions
#    fixing_in::Set{Tuple{Int8,Int8}}   #so we can unstick cells to the other side of it when it moves
#end 

#function move(loc, dir)
#    candidate = loc .+ dir
#    cand_cell = grid[candidate...]
#    cand_cell.obs || return candidate #unblocked cell easy
#    cand_cell.fixed_axes .* dir == (0,0) && return loc #blocked cell, fixed in this dir 
    #now we deal with the unfixed axis 

    #unfix Cells this Cell fixes 
#    foreach(cand_cell.fixing_in) do cc
#        setdiff!(cc.fixed_from, candidate) #remove candidate 
        #unfix if necessary - hm, this is not as easy using 1 set for all fixed_from dirs. Bitstring would be better...
#    end

    #"delete" and move cell
#    grid[candidate...]... 
#    grid[(candidate.+dir)...] = 
#end

#hm is it easier just to propagate attempted moves?

function try_m(loc, dir, grid)
    cand = loc .+ dir 
    grid[cand...] == '#' && return false #can't move into a wall 
    grid[cand...] == '.' && begin
        grid[cand...] = grid[loc...]
        grid[loc...] = '.'
        return true
    end 
    #now we have a '0' which means recursion
    if try_m(cand, dir, grid)
        grid[cand...] = grid[loc...]
        grid[loc...] = '.'
        return true
    else 
        return false 
    end
end 

dir_dict = Dict(['<'=>(0,-1), '>'=>(0,1), '^'=>(-1,0), 'v'=>(1,0)])

function parse_input(input)
    map_ = true
    arr = Vector{String}()
    insts = ""
    for l ∈ eachline(input)
        map_ = map_ == true && length(l) > 1
        if map_ == true 
            arr = [ arr ; l]
        else 
        insts *= l
        end
    end
    grid = mapreduce(x->permutedims(collect(x)), vcat , arr)
    moves =  map(x->dir_dict[x], collect(insts))
    (grid, moves)
end

(origgrid, moves) = parse_input("input")

grid = deepcopy(origgrid)
start = Tuple(findfirst(==('@'), grid))

function solve(start, grid, moves)
    robot = start
    for m ∈ moves
        #print("candidate cell $(robot.+m), ($(grid[(robot.+m)...]))\n")
        robot = try_m(robot, m, grid) ? robot.+m : robot 
        #print("New state\n")
        #for l ∈ eachrow(grid)
        #    print("$l\n")
        #end
        #print("\n\n")
    end
end

solve(start, grid, moves)

boxes = Tuple.(findall(==('O'), grid))
pt1 = mapreduce(x->100*(x[1]-1)+(x[2]-1), + , boxes)

print("Final grid: \n")
for l ∈ eachrow(grid)
    print("$l\n")
end
print("Pt1: $pt1\n")

#pt 2 is a transform of the matrix ('#' -> '#', '#'; 'O' -> '[', ']'; '.' -> '.', '.' ; '@' -> '@', '.')
#and a change of rules ([] are one box - so push rules vertically propagate like a binary tree)

expander = Dict(['#' => ['#','#'], 'O'=>['[',']'], '.' => ['.','.'], '@'=>['@','.']])
grid2 = mapreduce(vcat, eachrow(origgrid)) do r
    mapreduce(x->expander[x], hcat, r)
end

function try_m2(loc, dir, grid)

    #horizontal pushes are unchanged for wide things 
    dir[2] == 0 && return try_m(loc, dir, grid)
    
    #handle non-wide robot here - no "extra" 

    #push is vertical, object is wide
    if grid[loc] == '[' #then also consider obstructions on the right cell
        extra = loc.+(0,1)
    else #grid[loc] == ']' #then also consider obstructions on the left cell
        extra = loc.+(0,-1)
    end 

    (cand, cand_e) = (loc .+ dir, extra .+ dir)

    grid[cand...] == '#' || grid[cand_e...] == '#' && return false #can't move into a wall 
    (grid[cand...] == '.' && grid[cand_e...] == '.') && begin #neither side is blocked [this is wrong because we don't know we actually move until all other potential
                                                              # children have tested, see below]
        grid[cand...] = grid[loc...]
        grid[loc...] = '.'
        return true
    end 

    #at least one of the two sides is pushing something - but we need to propagate this "sideways" properly [separate "space to move" and "move"]
    # because *all* of the children need to report they *can* move before we can move any of them
    # we need a "try_m2" and a "move_m2". 
    if try_m(cand, dir, grid)
        grid[cand...] = grid[loc...]
        grid[loc...] = '.'
        return true
    else 
        return false 
    end
end 


solve(start2, grid2, moves)

boxes = Tuple.(findall(==('[]'), grid2))
pt2 = mapreduce(x->100*(x[1]-1)+(x[2]-1), + , boxes)

print("Final grid: \n")
for l ∈ eachrow(grid2)
    print("$l\n")
end
print("Pt2: $pt2\n")