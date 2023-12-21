#This feels like the secret is to pop things off the "accessible" queue once you get a loop to them that's a power of 2 (since that means it will
#recur @ 64)

#so, you want a "nodes visited" dict with a "seen at" value 
#and a "nodes we're currently at" Set which we expand from each time
#and a "nodes with a period of 2^n" Set you push things into when you meet them again at the right time?

#with a rule that when you do the next "step update", you *don't* move to any nodes in the "period 2^n" list
# (which breaks those cycles and means that we don't grow an exponential number of nodes we're tracking at time t since we're pruning short cycles as we go)


#Further thought before going out to do other things: no, this is slightly more subtle than that: *all* points where we can reach them at an even timestep are in the set
# (because we can then trivially step off them and back into them endlessly until we get any other even number)
# - are there any odd points which are also in the set? anything we can orbit with an odd cycle ?

six_four_nodes = Set{CartesianIndex{2}}()

map_raw = read("input2")
width = findfirst(==(UInt8('\n')), map_raw);
matrix = (reshape(map_raw, width, :)[begin:end-1, :]);

starter = findfirst(==(UInt8('S')), matrix)
println("$matrix")

println("$(UInt8('S'))")

N = CartesianIndex(-1, 0)
S = CartesianIndex(1, 0)
E = CartesianIndex(0, 1)
W = CartesianIndex(0, -1)

function expand(actives, matrix)
    new_actives = Set{CartesianIndex{2}}()
    println("$actives")
    for cell ∈ actives
         println("$cell")
         for dir ∈ [N, E, S, W]
            cand = cell + dir
            #   must be in bounds               and not an already found 64     and not going into a wall  
            checkbounds(Bool, matrix, cand) && !(cand ∈ six_four_nodes) && matrix[cand] != UInt8('#') && push!(new_actives, cand);
         end
    end
    new_actives
end

active_nodes = Set{CartesianIndex{2}}([starter])
for count ∈ 1:10
    global active_nodes = expand(active_nodes, matrix)
    if count % 2 == 1
        union!(six_four_nodes, active_nodes)
    end
end

println("$(length(six_four_nodes))");

#part 2
#annoyingly 26501365 doesn't factor nicely (it's 5 x 11 x 481843)
# however, since it is odd, *any* tile that can be reached in an odd number of steps can *also* be reached in 26501365 steps (just as for even and 64 above)
#so, this problem reduces to "find the tiles no more than 26501365 steps away which have odd step counts" - since the map tiles, we can probably do some maths on what
#the images look like by just filling the "main tile" and inspecting its step patterns (esp as we have a 2 tile border on the repeat edges of .s with no obstructions)

#we can probably count "how far we get" by inspecting the "count at which each cell on the border is reached" and multiplying up