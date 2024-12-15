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

(grid, moves) = parse_input("input")

start = Tuple(findfirst(==('@'), grid))

function pt1_solve(start, grid, moves)
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

pt1_solve(start, grid, moves)

boxes = Tuple.(findall(==('O'), grid))
pt1 = mapreduce(x->100*(x[1]-1)+(x[2]-1), + , boxes)

print("Final grid: \n")
for l ∈ eachrow(grid)
    print("$l\n")
end
print("Pt1: $pt1\n")


