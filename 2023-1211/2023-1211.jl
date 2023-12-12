d = read("input");


b(x) = UInt8(x);

rowl = findfirst(x->x==b('\n'), d);
coll = length(d) ÷ rowl;
space = reshape(d, rowl, :);

bigcols = fill(2, rowl);
bigrows = fill(2, coll); 
bigcols2 = fill(1000000, rowl);
bigrows2 = fill(1000000, coll); 

#it's probably faster to iterate through the grid and check for #, adding them and setting as we go, but this is easier to write
galaxies = Tuple.(findall(x->x==b('#'), space)); #need to Tuple to make this easily deconstructible?
for (row,col) in galaxies
    bigcols[col] = 1; #this col doesn't expand
    bigrows[row] = 1; #this row doesn't expand
    bigcols2[col] = 1; #this col doesn't expand
    bigrows2[row] = 1; #this row doesn't expand
end 
#println("$galaxies");
#make our accumlated distances to avoid quadratic calculations later on [see comment down there]
#   (I really want to use foldl for this... )

# Note - by recording the number of galaxies in each row and column too [and then accumulating "total above this line"]
# we can actually do the sum in O(rows+columns) since *every* galaxy above the current row has a sum involving
# subtracting the current distance for every galaxy in this row... and *every* galaxy below the current row has a sum
# involving *adding* the current distance for every galaxy in this row 
# so we can just do both of those for every galaxy in the current row with a multiplication at once!

history_accum(l) = foldl(l; init=[0]) do accum, r
    accum[end] += r;
    push!(accum, accum[end]);
    accum
end

dist_rows = history_accum(bigrows);
dist_cols = history_accum(bigcols);
dist_cols2 = history_accum(bigcols2);
dist_rows2 = history_accum(bigrows2);

numgs = length(galaxies);
#pair distances
function solve(galaxies, bigcols, bigrows)
    sumdist = 0;
    sumdist2 = 0;
    for i in 1:numgs
        (row,col) = galaxies[i];
        for (row2, col2) in galaxies[i+1:end]
            #only need the abs for rows because cols are ordered
            sumdist += abs(dist_rows[row2]-dist_rows[row]) + dist_cols[col2] - dist_cols[col];
            sumdist2 += abs(dist_rows2[row2]-dist_rows2[row]) + dist_cols2[col2] - dist_cols2[col];
        end 
    end
    (sumdist, sumdist2)
end

println("Sum is $(solve(galaxies, bigcols, bigrows))")

#println("Sum is $sumdist");
