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
    print(reduce(*, l))
    print("\n")
end
print("Pt1: $pt1\n")

#pt 2 is a transform of the matrix ('#' -> '#', '#'; 'O' -> '[', ']'; '.' -> '.', '.' ; '@' -> '@', '.')
#and a change of rules ([] are one box - so push rules vertically propagate like a binary tree)

expander = Dict(['#' => ['#' '#'], 'O'=>['[' ']'], '.' => ['.' '.'], '@'=>['@' '.']])
grid2 = mapreduce(vcat, eachrow(origgrid)) do r
    mapreduce(x->expander[x], hcat, r)
end

function test_sqs(loc, grid)
    #handle non-wide robot here - no "extra" 
    test_sq = [loc]
    #push is vertical, object is wide
    
    if grid[loc...] == '[' #then also consider obstructions on the right cell
        push!(test_sq, loc.+(0,1))
    elseif grid[loc...] == ']' #then also consider obstructions on the left cell
        push!(test_sq, loc.+(0,-1))
    end 
    test_sq
end


move_type = Union{Set{Tuple{Int64, Int64}}, Nothing}

function try_m2(loc, dir, grid)
    #horizontal pushes are unchanged for wide things 
    dir[1] == 0 && return try_m(loc, dir, grid)
    
    test_sq = test_sqs(loc, grid)

    move_dict = try_m2_wide(test_sq, dir, grid, 1)
    #print("Result of try_m2_wide on $cand_sq is $res\n")
    isnothing(move_dict) && return false
    for i ∈ move_dict[2]:-1:1
        for cell ∈ move_dict[1][i]
            grid[(cell.+dir)...] = grid[cell...]
            grid[cell...] = '.'
        end
    end 
    true 
end


function try_m2_wide(test_sq, dir, grid, n)
    cand_sq = map(x->x.+dir, test_sq)
    any(map(x->grid[x...]=='#', cand_sq)) && return nothing #can't move into a wall 
    all(map(x->grid[x...]=='.', cand_sq)) && return (Dict([n=>Set(test_sq)]),n) #neither side blocked, but neither side needs to move anything

    #otherwise we're going to need to return some stuff to move ahead of us, accumulating recursively. I guess we could preallocate a vector of length "height of room"....
    move_dict = Dict([n=>Set(test_sq)])
    max_n = n
    for sq ∈ cand_sq
        grid[sq...] == '.' && continue #can't push an empty dot
        res = try_m2_wide(test_sqs(sq,grid), dir, grid, n+1)
        isnothing(res) && return nothing #nothings propagate and override
        max_n = max(max_n, res[2])
        for k ∈ keys(res[1])
            move_dict[k] = get(move_dict,k, Set()) ∪ res[1][k]
        end
    end
    (move_dict, max_n)
end 

function solve2(start, grid, moves)
    robot = start
    for m ∈ moves
        #print("candidate cell $(robot.+m), ($(grid[(robot.+m)...]))\n")
        robot = try_m2(robot, m, grid) ? robot.+m : robot 
        #print("New state\n")
        #for l ∈ eachrow(grid)
        #    print("$l\n")
        #end
        #print("\n\n")
    end
end

start2 = Tuple(findfirst(==('@'), grid2))
solve2(start2, grid2, moves)

boxes = Tuple.(findall(==('['), grid2))
pt2 = mapreduce(x->100*(x[1]-1)+(x[2]-1), + , boxes)

print("Final grid: \n")
for l ∈ eachrow(grid2)
    print(reduce(*, l))
    print("\n")
end

print("\nPt2: $pt2\n")