d = read("input");


b(x) = UInt8(x);

rowl = findfirst(x->x==b('\n'), d);
coll = length(d) ÷ rowl;
space = reshape(d, rowl, :);

bigcols = ones(UInt8, rowl);
bigrows = ones(UInt8, coll); 

#for # in array
# add # to list
# set bigcols(col) = 0
# set bigrows(row) = 0

#pair distances
#for i in list
#  for j in list[i:]
#        metropolis_dist + sum(bigrows[range]) + sum(bigcols[range])

#sum()
