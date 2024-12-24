#this is probably optimally done by topologically sorting the set of nodes

ops = Dict(["AND"=>&, "OR"=>|, "XOR"=>⊻])

struct Node 
    ins::Tuple{String, String}
    op::Function
end

function readinput(input_)
    input = readlines(input_)
    starters = Dict{String, Bool}()
    edges = Dict{String, Set{String}}()
    enders = Set{String}() 
    node = Dict{String, Node}()
    i = 1
    for line ∈ input
        length(line) == 0 && break #last line of no-deps nodes
        (out, val) = split(line, ": ")
        #node[out] = (("",""), parse(Bool, val))
        starters[out] = parse(Bool,val) 
        i+=1
    end
    for line ∈ input[i+1:end] #rest 
        (in1,op,in2,_,out) = split(line,' ')
        node[out] = Node((in1,in2), ops[op])
        edges[in1] = get(edges,in1,Set{String}()) ∪ [out]
        edges[in2] = get(edges,in2,Set{String}()) ∪ [out]
        first(out) == 'z' && push!(enders, out)
    end
    (starters, enders, node, edges)
end

(starts, ends, nodes, edges) = readinput("input")
outs = Dict{}
endings = sort(collect(ends); rev=true)
print("Endings: $endings \n")

#topological sort of nodes 
function topo_sort!(starts, node, edges)
    vals = Dict{String, Bool}()
    while length(starts) != 0
        s = pop!(starts)
        push!(vals, s)
        ks = first(s)
        for m ∈ get(edges,ks, Set{String}())
            edges[ks] = setdiff(edges[ks], m)
            calc= node[m]
            all(calc.ins .∈ Ref(keys(vals))) && push!(starts, m=>(calc.op)(get.(Ref(vals), calc.ins, 0)...))
        end
    end
    vals
end 

result = topo_sort!(starts, nodes, edges)
output = foldl((e,i)->e<<1+result[i], endings;init=0)
print("Pt1: $output\n") 

#Pt2: okay, so if this is a classical adder then we can probably construct the "ideal" adder here and compare.
#   this is a 45 bit adder, so can produce a 46 bit output with carry.
# a multi-bit adder is a hierarchical template built from 1-bit \w carry adders so can we just iterate through x00->44 and y00->44 and trace what should happen?

# a full adder looks like

# xN xor yN -> nN 
# xN and yN -> mN
# nN xor cN -> zN
# nN and cN -> oN
# oN or mN -> c(N+1)  [the carry bit for operation on bit 1]

#(so x0,y0 will be missing the c0 operations, and z45 should just get the c44 input, probably as oN or mN -> z45 )

#further nodes - zN for N < 45 must have a XOR operation, so if we see any other op, we know that's an incorrect wire

x = ["x"*string(i; pad = 2) for i ∈ 0:44 ]
y = ["y"*string(i; pad = 2) for i ∈ 0:44 ]
n = [nothing for i ∈ 0:44 ]
m = [nothing for i ∈ 0:44 ]
o = [nothing for i ∈ 0:44 ]
z = ["z"*string(i; pad = 2) for i ∈ 0:45 ]
c = [nothing for i ∈ 0:45 ]

swaps = Dict{String, String}()

#run through the adder from bit 0 to bit 44...



#of course we're probably supposed to do the more general version of this (move from low to high bits, checking values to identify the points of errors)