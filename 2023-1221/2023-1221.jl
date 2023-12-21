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

map_raw = read("input")
width = findfirst(==(UInt8('\n')), map_raw);
s_matrix = (reshape(map_raw, width, :)[begin:end-1, :]);

#starter = findfirst(==(UInt8('S')), matrix)
#println("$matrix")

#start at exact centre 
start_idx = (1+9*131) ÷ 2
starter = CartesianIndex(start_idx,start_idx)

#new matrix by concatenation - big enough to get up to 2 tiles away left and right and up and down 

line = [ s_matrix s_matrix s_matrix s_matrix s_matrix s_matrix s_matrix s_matrix s_matrix]
matrix = [ line ; line ; line ; line ; line ; line ; line ; line ; line]




println("$(UInt8('S'))")

N = CartesianIndex(-1, 0)
S = CartesianIndex(1, 0)
E = CartesianIndex(0, 1)
W = CartesianIndex(0, -1)

function expand(actives, matrix)
    new_actives = Set{CartesianIndex{2}}()
    #println("$actives")
    for cell ∈ actives
         #println("$cell")
         for dir ∈ [N, E, S, W]
            cand = cell + dir
            #   must be in bounds               and not an already found 64     and not going into a wall  
            checkbounds(Bool, matrix, cand) && !(cand ∈ six_four_nodes) && matrix[cand] != UInt8('#') && push!(new_actives, cand);
         end
    end
    new_actives
end

active_nodes = Set{CartesianIndex{2}}([starter])
for count ∈ 1:(65+131*4)
    global active_nodes = expand(active_nodes, matrix)
    if count % 2 == 1
        union!(six_four_nodes, active_nodes)
    end
    if count ∈ [64,65+130, 65+131, 65+132, 65+130+131, 65+131+131, 65+131+131+131, 65+131*4]
        println("Odd cells at count $count = $(length(six_four_nodes))")
    end
end

println("$(length(six_four_nodes))");

#part 2
#annoyingly 26501365 doesn't factor nicely (it's 5 x 11 x 481843)
# however, since it is odd, *any* tile that can be reached in an odd number of steps can *also* be reached in 26501365 steps (just as for even and 64 above)
#so, this problem reduces to "find the tiles no more than 26501365 steps away which have odd step counts" - since the map tiles, we can probably do some maths on what
#the images look like by just filling the "main tile" and inspecting its step patterns (esp as we have a 2 tile border on the repeat edges of .s with no obstructions)

#we can probably count "how far we get" by inspecting the "count at which each cell on the border is reached" and multiplying up.... but this is also Manhattan which has 
# exciting distance properties - we can move orthogonally at any points in our line and it counts as the same distance as long as we move the same number total lr and ud 
# notably, there's no obstructions on the l-r or u-d lines that S sits on, meaning that S is *exactly* 65 steps from every edge and thanks to the above property, 
# every other point on the edge is the normal manhattan distance from it.
# so, the corners will have been visited at 65+65 = step 130 ? - so after 130 steps we will know how many odd cells are in the base tile 
 
# = from running the script, at step 130, there are 7748 odd cells in the tile 
# I think every other tile will flip parity because of the edges, so even tiles is 7757 which will be odd tiles on the orthogonally connected tiles 

#wavefronts in Manhattan are diagonals so I think the extra "1/2" is evenly distributed sampling all sections of the tile images in all directions.


#yes... 26501365 / 131 (the tile width) is according to bc, 202300.496 (that is, 1 cell off being exactly whole+1/2 num of tiles - which makes sense as we start at cell 0)

# average 7757 and 7748 is 15505/2

#we're going 202300.5 in left *and* right though so that's 404601 repeats * 404601 repeats "north-south" as well for a total of 16370196201 tiles!
# or are we off by one? 16370196200? + the base one which is "half a tile"? that must be too low, right?

#think about what happens with the triangular wavefronts - at step 130, we're actually the centre of a *rotated* title that's diamond oriented, and samples
# the first entire tile (odd counts) + 4 quarters of the next tiles (even counts) - so we've actually sampled 15505 cells in total (2 "tiles")

#another 131 steps later, we'll sample 5 full tiles (centre + ortho adjacents) , 4 half tiles (the diagonals between their corners) and 4 quarter tiles (the new peaks of the diamond)
# which is 8 tiles total - 4 times the 1x130 area and thus 15505*4 = 62020 cells in total walkable
# this is "261" steps distance 

#ah, but that isn't helpful - we're still "off by one-half". 
#... that's because we want 0.5 (the diamond where the cells just touch the border of the inner cell) in the centre plus a *whole* tile orthogonally (for 65+131 ) then 65 + (2*131) and so on - the centre tile is sampled differently
# which also gives us the correct divisor (26501365 - 65)/131 = 202300 

#so this is odd@65 == 3944 (centre tile) + [whatever we get extra for another 131 tiles] + ...?
#these are *homogenous* right, so these should be total = area in "diagonal tiles" * 15505 ? 

#so, at 65 - 3944 (~1/4 * 15505 - the diagonal super tile *is* 4x bigger than this one),
# at 196 (=65+131)  34697 [15505*2.237... actually 4.5 / 2 = the diagonal tile *is* 2.25times bigger  (9/2)/2] , consider this an extra 30753 per "odd ring"
# at 327 (=65+131*2)  97230 [15505*6.270880... actually 6.25 = diagonal tile ratio (25/2)/2], consider this an extra 62553 per "even ring" 
# which shows that our homogeneity is true but we need a correction.
# the scaling can't be more than quadratic, and we know the "constant term" is the 0.5 we subtract off, right (for 0 extra 131 steps)
# so formula is 

# n = 3944 + p * [131 multiples] + q * [131 multiples squared]

# 30753 = p + q  #remember we don't have the constant term
# 93286 = 2p + 4q
# q = 30753 - p 
# 93286 = 2p - 30753*4 - 4p
# p = (30753*4 - 93286) / 2 = 14863
# q = 15890

# we need 202300 multiples of 131 so our answer is

println("$(3944+(14863+15890*4)*4)")

#hm, for 65+131*3 we get 189489 which is *not* what our formula thinks (it thinks 191543)
#also not for 65+131*4 - we get 314556, formula thinks 317636

#okay, so the error can be more than quadratic... I'm actually going to have to count up the number of tiles that contribute from the edges aren't I?
#we have "whole tiles" (which we know about in bulk )
#we have the contributions from the four "points" of the diagonal (on n+1/2 length sides)
# then the points go into small triangles on the corners of the next, and big tiles *missing* the top corners on the next. 
# and so on down the line into the midpoint (which is either a small triangle or a big tile missing a corner - small triangle if n odd)

#we can actually generate these by running the simulation on grids of different widths and heights (3x1 grid gives us only centre tile + 2 odd "points")
# 3x3 gives 4 (odd) points, 4 (even) small tries and the centre ; 5x5 gives centre + 4 odd tiles + 4 (even) points + 4 (even) big segs + 8 small (odd) triangles
# we know that we want an *even* number so maybe we can solve this with 1x1, 5x5 (n=2), 9x9 (n=4), 13x13 (n=6) and simultaneous equations for the 
# different segment contributions? - tiles we already know!, points, small tries, big segs 