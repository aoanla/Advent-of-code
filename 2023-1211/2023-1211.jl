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
distsrows = foldl(bigrows, [0]) do accum, r
    push!(accum, accum[end]+r) #is this push! okay given that we get passed accum?
end

numgs = length(galaxies);
#pair distances
function solve(galaxies, bigcols, bigrows)
    sumdist = 0;
    sumdist2 = 0;
    for i in 1:numgs
        (row,col) = galaxies[i];
        for (row2, col2) in galaxies[i+1:end]
            #order rows to get range right
            (lrow, rrow) = (row > row2) ? (row2, row) : (row, row2);
            # (lcol, rcol) = (col > col1) I shouldn't need to sort these if findall iterates in order through the array...
            #obviously we should precompute "sum 1:row" and "sum 1:col" and then just subtract the two sums to avoid doing this quadratically
            dist=sum(bigrows[lrow:rrow]) + sum(bigcols[col:col2]) -2; #-2 removes the "final step h and v" which we shouldn't count
            dist2=sum(bigrows2[lrow:rrow]) + sum(bigcols2[col:col2]) -2;
            #println("dist $i $j = $dist")
            sumdist += dist;
            sumdist2 += dist2;
        end 
    end
    (sumdist, sumdist2)
end

println("Sum is $(solve(galaxies, bigcols, bigrows))")

#println("Sum is $sumdist");
