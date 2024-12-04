
f = readlines("input")
#padding to make this easier
llim = length(f[1])
fl = f .* "..."
#to array of chars --> and concat into matrix
g = reduce(hcat, collect.(fl)) 
empty = fill('.',size(g)[1])

grid = [g ;; empty ;; empty ;; empty] #bottom padding 

#search vert, hori, diags
#if we look for both smax and xmas then we avoid most of our reverse counting
#the issue is the diag / because it can't be made "forward both v and h" simultaneously

directions = [ 
    [[0,1,2,3],[0,0,0,0]],
    [[0,0,0,0],[0,1,2,3]],
    [[0,1,2,3],[0,1,2,3]], #diag \
    [[0,1,2,3],[3,2,1,0]], #neg diag /
]

matches = [['X','M','A','S'], ['S','A','M','X']]

tot = 0
for i ∈ 1:llim, j ∈ 1:llim 
    for d ∈ directions
        candidate = grid[CartesianIndex.(d[1] .+ i, d[2] .+ j)]
        for m ∈ matches
            global tot += reduce(&, candidate .== m)
            #print("$tmp")
        #and then sum, sum, sum 
        end
    end
end

print("Pt1 = $tot\n")

function test_pair(p)
    (p[1] == 'M' && p[2] == 'S') || (p[1] == 'S' && p[2] == 'M') 
end

tot = 0
for i ∈ 1:llim, j ∈ 1:llim 
    #needs a central A         #\ diag
    global tot += ( grid[i+1,j+1] == 'A' && 
        test_pair(grid[CartesianIndex.(i.+[0,2],j.+[0,2])]) &&
        test_pair(grid[CartesianIndex.(i.+[2,0],j.+[0,2])]) )
end

print("Pt2 = $tot\n")




### we could also do stupid things like making mirrors
### of the grid in different directions and then just looking for xmas lr in each