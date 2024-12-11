f = readlines("input")
#padding to make this easier
#to array of chars --> and concat into matrix

# .<  is 12 bigger than '0' so we get 12 in those slots as buffer
g = reduce(hcat, vcat.('<',(collect.(f)), '<') ) .- '0'
empty = fill(12,size(g)[1])

grid = [empty ;; g ;; empty ] #top & bottom padding

#now it's safe to traverse the grid with no bounds checking as we have buffer 

trailheads = Dict{Tuple{Int32, Int32}, Int32}
foreach zero_coord ∈ grid 
    trailheads[zero_coord] = 0
    tmp_scratch = fill(true, (19,19) ) #"visited" counter to avoid backtracking, centred on spot 
    for dir ∈ directions
        pos = loc .+ dir
        if grid[pos...] == cur + 1 && tmp_scratch[(pos .- zero_coord .+ 10)...]
            tmp_scratch[(pos .- zero_coord .+ 10)] = false #not valid as we just saw it
            if cur == 8
                #this was a 9 we found
                trailheads[zero_coord] += 1
            end 
            recurse(cur+1, pos, zero_coord)
        end
    end
end-foreach
