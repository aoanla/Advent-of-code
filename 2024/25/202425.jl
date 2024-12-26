
fits((p1,p2)) = all((p1.+p2).<6)

function parse_input(input_)  #yes, there's a nicer way to do this by reading the known chunk size and then parsing it as one by rotating it, but meh
    blocks = readlines(input_) |> Base.Fix2(Iterators.partition, 8) |> Base.Fix1(map, x->reduce(hcat, collect.(collect(x)[1:7])))
    locks = filter(x->x[1]=='#', blocks) |> Base.Fix1(map, x->sum(==('#'), x, dims=2).-1)
    keys_ = filter(x->x[1]!='#', blocks) |> Base.Fix1(map, x->sum(==('#'), x, dims=2).-1)
    (keys_, locks)
end 
(k, l) = parse_input("input")

#print("keys = $k \n locks = $l \n")
res = mapreduce(fits,  +  , Iterators.product(k,l))
print("res: $res\n")