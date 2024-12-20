#surely this is just "work out distance to goal from each point on track" "select pairs of points where dist difference is 100 - length of cheat(==2)"?

grid_ = reduce(vcat, permutedims.(collect.(readlines("input"))))
const start = Tuple(findfirst(==('S'), grid_))
const end_ = Tuple(findfirst(==('E'), grid_))
const grid = map(!=('#'), grid_)

struct Step
    perp_dirs::Set{Tuple{Int64,Int64}} #dirs a cheat could happen from - usually 2 long, but start could cheat from 3 dirs
    count::Int64
end 

print("Start: $start\nEnd: $end_\n$grid\n")

const dirs = Set([(0,1), (1,0), (0,-1), (-1,0) ])
const deltas = Dict([ (0,1)=>[(0,1), (-1,0), (1,0)], 
                (0,-1)=>[(0,-1), (-1,0), (1,0) ],
                (1,0)=>[(1,0), (0,-1), (0,1) ],
                (-1,0)=>[(-1,0),(0,-1), (0,1) ],
])

next_dir(cell, dirs) = filter(x->grid[(cell.+x)...], dirs) |> first 

function trace_path()
    dists = Dict{Tuple{Int64,Int64}, Step}()
    cell = start
    dir = next_dir(cell, dirs)
    count = 0
    dists[cell] = Step(setdiff(dirs,[dir]), count)
    #traverse grid for values 
    while cell != end_ 
        cell = cell .+ dir 
        count += 1
        n_dir = cell != end_ ? next_dir(cell, deltas[dir]) : dir.*(-1) #the end cell also has no "next dir" other than backwards 
        dists[cell] = Step(setdiff(dirs, [n_dir, dir.*(-1)]), count) #the perps are "not back where we came from" and "not where we are going"
        dir = n_dir
    end
    dists  
end

dists = trace_path()
#print("$dists\n")

struct Cheat 
    cells::Tuple{Tuple{Int64,Int64}, Tuple{Int64,Int64}}
end 

function get_cheats(dists)
    cheats = Dict{Int64, Set{Cheat}}()
    #find cheats - a cheat is a *lateral* movement so it's perpendicular to where we were moving on the grid at that time
    foreach(pairs(dists)) do (k,v)
        for trial ∈ v.perp_dirs
            dest = k.+(trial.*2)
            !haskey(dists, dest) && continue #if this is on the path
            dest_count = dists[dest].count 
            saving = v.count - dest_count - 2 #2 for the steps we need to take to cheat
            cheats[saving]=get(cheats, saving, Set{Cheat}()) ∪ [Cheat((k.+trial, dest))]
        end
    end
    cheats 
end

cheats = get_cheats(dists)

count = filter(>=(100), collect(keys(cheats))) |> Base.Fix1(map, k->length(cheats[k])) |> sum 

print("Pt1: $count\n")

#pt2 - we can cut down on what we need to consider by looking *backwards* from destinations long enough along the path to allow a saving
# (there's no point in looking @ destinations with a length < saving) - which also means for the cell at position 102, we only need to look
# at cheat of length 2 , for cell at position 103, cheats of length 2 and 3, and so on 
# this also means we can probably build up cheats from past cheats too

