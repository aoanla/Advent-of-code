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



map_raw = read("input")
width = findfirst(==(UInt8('\n')), map_raw);
matrix = (reshape(map_raw, width, :)[begin:end-1, :]);

starter = findfirst(==(UInt8('S')), matrix)
#println("$matrix")

#start at exact centre 
#start_idx = (1+9*131) ÷ 2
#starter = CartesianIndex(start_idx,start_idx)

#new matrix by concatenation - big enough to get up to 2 tiles away left and right and up and down 

#line = [ s_matrix s_matrix s_matrix s_matrix s_matrix s_matrix s_matrix s_matrix s_matrix]
#matrix = [ line ; line ; line ; line ; line ; line ; line ; line ; line]




println("$(UInt8('S'))")

N = CartesianIndex(-1, 0)
S = CartesianIndex(1, 0)
E = CartesianIndex(0, 1)
W = CartesianIndex(0, -1)

function expand(actives, matrix, six_four_nodes)
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

function find_parity_at_dist(parity, dist)
    six_four_nodes = Set{CartesianIndex{2}}()
    active_nodes = Set{CartesianIndex{2}}([starter])
    for count ∈ 1:dist
        active_nodes = expand(active_nodes, matrix, six_four_nodes)
        if count % 2 == parity
            union!(six_four_nodes, active_nodes)
        end
    end
    length(six_four_nodes)
end

even = 0
odd = 1

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
   #note, this is not true - at step 130 we've sampled 15272 tiles!

#another 131 steps later, we'll sample 5 full tiles (centre + ortho adjacents) , 4 half tiles (the diagonals between their corners) and 4 quarter tiles (the new peaks of the diamond)
# which is 8 tiles total - 4 times the 1x130 area and thus 15505*4 = 62020 cells in total walkable
# this is "261" steps distance 
    #note this is not true, at step 261 we've sampled 62004 tiles!

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

#println("$(3944+(14863+15890*4)*4)")

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


#... edit to add, I just noticed another pattern in the input data (there's a big diamond in it - so we *are* supposed to sum the "small diamond" contribution 
#specially) - we could *also* see this now as a tiling of "inner diamond" and the outer corners (forming their own diamond with adjacent tiles)

#having slept on this, I think the entire issue with the quadratic above is that it's only counting the *odd* tile fills. 
#if we look at this from the perspective above of the "tile" really being a central diamond [==C], the "1/2 dist" bit, with then edge corners E 
#then 1 tile = C + E , or equiv, E = tile - C
#the parity of C and E will alternate in adjacent tiles so we need oddC and oddE, and evenC and evenE, to calculate the result

#extending into adjacent tiles, we can see that a "small trie" is just 1/4 E [from symmetry we'll always get each quarter of E the same number of times]
#                                   a big seg (missing 1 trie) is just C + 3/4 E 
#                                   a "point"                  is just C + 1/2 E

# whole tiles :

#   1        2        o
#            e       oeo 
#   o       eoe     oeoeo             
#            e       oeo
#  1,0      1,4       o   9,4  - this is sum of 4Σ2n+1 stuff - gives quadratics in general as sum

#our count is even so let's do this for an even distance  N

# we'll always have 4 "points", and they'll be an odd tile so they contribute                   4×Co    +   2×Eo total 
# we'll have N tries per side (they fill in gaps each column) for 4N tries, evens                           N×Ee total  
# we'll have N-1 big segs per side (running point to point) for 4(N-1) big segs, odd            4(N-1)×Co   3(N-1)×Eo
# we'll have N² even whole tiles                                                                N²×Ce       N²×Ee
# we'll have (N-1)² odd whole tiles                                                             (N-1)²×Co   (N-1)²×Eo

# Total Co: 4+4(N-1)+(N-1)² = 4 + 4N -4 +N² -2N + 1 = N² + 2N + 1 = (N+1)(N+1)
# Total Eo: 2+3(N-1)+(N-1)² = 2 + 3N -3 +N² -2N + 1 = N² + N      =    N (N+1)
# or, since ODDTILE = Co + Eo 
# N(N+1) ODDTILE + N+1 Co

# Ce, Ee are easier - we only get even Ee separately from the small tries so we just have
# N² EVENTILES + N Ee

EVENTILES = find_parity_at_dist(even, 132) #big enough to fill
ODDTILES = find_parity_at_dist(odd, 132)
CODD = find_parity_at_dist(odd, 65) 
EODD = ODDTILES - CODD 
CEVEN = find_parity_at_dist(even, 65)
EEVEN = EVENTILES - CEVEN 

println("$EVENTILES")

function find_tiles_at_even_tile_dist(n)
    n*(n+1)*ODDTILES  + (n+1)*CODD + (n^2)*EVENTILES + n*EEVEN 
end

#test 
println("$(find_tiles_at_even_tile_dist(2))")
println("$(find_tiles_at_even_tile_dist(4))")

println("$(find_tiles_at_even_tile_dist(202300))")