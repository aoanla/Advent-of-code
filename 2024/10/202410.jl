f = readlines("input")
#padding to make this easier
#to array of chars --> and concat into matrix

# .<  is 12 bigger than '0' so we get 12 in those slots as buffer
g = reduce(hcat, vcat.('<',(collect.(f)), '<') ) .- '0'
empty = fill(12,size(g)[1])

grid = [empty ;; g ;; empty ] #top & bottom padding

#now it's safe to traverse the grid with no bounds checking as we have buffer 

trailheads = Dict{Tuple{Int64, Int64}, Int64}()
const directions = ((0,1),(0,-1),(1,0),(-1,0))

function explore(loc, cur, tmp_scratch, zero_coord)
    trailheads = 0
    for dir ∈ directions
        pos = loc .+ dir
        if grid[pos...] == cur + 1 && tmp_scratch[(pos .- zero_coord .+ 10)...]
            tmp_scratch[(pos .- zero_coord .+ 10)...] = false #not valid as we just saw it
            if cur == 8
                #this was a 9 we found
                trailheads+=1  #we should actually accumulate this in the return calls
            else
                trailheads+=explore(pos, cur+1, tmp_scratch, zero_coord)
            end
        end
    end 
    trailheads
end

zero_(x) = x == 0

function get_trailheads(grid, trailheads)
    zero_coord = findfirst(zero_, grid) 
    while !isnothing(zero_coord)
        zero_coord_ = Tuple(zero_coord) #needed for math to work
        tmp_scratch = fill(true, (19,19) ) #"visited" counter to avoid backtracking, centred on spot 
        trailheads[zero_coord_]= explore(zero_coord_, 0, tmp_scratch, zero_coord_)
        zero_coord = findnext(zero_, grid, CartesianIndex(zero_coord_ .+ (1,0)))
    end
end

get_trailheads(grid, trailheads)

#I think this is what pt1 wants
print("$(sum(values(trailheads)))")
