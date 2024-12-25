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
function topo_sort(starts, node, edges)
    starts = deepcopy(starts)
    edges = deepcopy(edges)
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

result = topo_sort(starts, nodes, edges)
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



num(x,n) = x * string(n;pad=2)


##### we should make a list of "true" pairs first - as we know all the inputs are good
##### - in particular, the XOR/AND pairs that aren't x,y *must be* n,c pairs, and the OR pairs *must be* o,m pairs 
##### - at the same time, we can flag zs we know are wrong if they're outputs of anything but a XOR


#run through the adder from bit 0 to bit 44...

#on examining the data, we can clarify that the rule is precisely that the output (the third entry on a line == "node key" here)
# is the only thing that can be "wrong". (all the "inputs" seem to be fine, in that all the AND and XOR operations come in pairs with identical inputs as we expect)

function fix_nodes!(n1,n2,nodes,swaps)
    swaps[n1] = n2
    swaps[n2] = n1 
    (nodes[n1], nodes[n2]) = (nodes[n2], nodes[n1]) 
end 

function find_anomaly(node, edges)
    x = ["x"*string(i; pad = 2) for i ∈ 0:44 ]
    n = ["" for i ∈ 0:44 ]
    m = ["" for i ∈ 0:44 ]
    o = ["" for i ∈ 0:44 ]
    z = ["z"*string(i; pad = 2) for i ∈ 0:45 ]
    c = ["" for i ∈ 0:45 ]

    swaps = Dict{String, String}()
    c[2] = first(filter(i->node[i].op == &, edges["x00"]))  #the 00s are a half-adder with no carry, but they do produce a carry 
    for i ∈ 1:44
        x_ = num("x", i)
        #edges[x_] != edges[y_]  #error, these are always paired inputs <-- these can't be wrong, as x,y given
        n_or_m = edges[x_]
        n[i+1] = first(filter(x->node[x].op == ⊻,  n_or_m)) #this is what is true if the network is correct
        m[i+1] = first(filter(x->node[x].op == &, n_or_m )) #this is what is true if the network is correct
        if n[i+1] == "" || m[i+1] == "" || c[i+1] == ""
            print("Missing element@$i n=$(n[i+1]), m=$(m[i+1]), c=$(c[i+1]) @ x,y")
        end
        #test this - 
        z_ = num("z", i)
        # check for n[i+1], c[i+1] pair
        if n[i+1][1] == 'z' 
            z_c = first(edges[o[i+1]])
            n_true = first(setdiff(node[z_c].ins, [c[i+1]]))
            fix_nodes!(n_true, n[i+1], node, swaps)
            n[i+1] = z_c
        end
        if c[i+1][1] == 'z'
            z_n = first(edges[n[i+1]])
            c_true = first(setdiff(node[z_n].ins, [n[i+1]]))
            fix_nodes!(c_true, c[i+1], node, swaps)
            c[i+1] = c_true
        end
        if edges[n[i+1]] != edges[c[i+1]] #error, these are always paired inputs 
            #identify which is wrong - by looking at the resulting nodes and seeing what their paired inputs are.
            if z_ ∈ edges[n[i+1]] #then c is probably wrong
                c_true = first(setdiff(node[z_].ins, [n[i+1]]))
                fix_nodes!(c[i+1], c_true, node, swaps)
                c[i+1] = c_true 
            elseif  z_ ∈ edges[c[i+1]] #then n is probably wrong
                n_true = first(setdiff(node[z_].ins, [c[i+1]]))
                fix_nodes!(n[i+1], n_true, node, swaps)
                n[i+1] = n_true
            else #z_ is not an endpoint for either, which means z_ was also swapped!
                print("Unfixable anomaly - $(n[i+1]) and $(c[i+1]) should be parents of $z_ but it is not a descendant of either\n")
            end
        end 
        #we should have confirmed n[i+1], c[i+1] by here 
        z_or_o = edges[n[i+1]]
        z[i+1] = filter(x->node[x].op == ⊻,  z_or_o) |> first  #what should be true if this is correct
        
        if z[i+1] != z_ #the z is wrong, fix it
            fix_nodes!(z[i+1], z_, node, swaps)
            z[i+1] = z_ 
        end 
        o_cand = filter(x->node[x].op == &,  z_or_o) |> first #what should be true if this is correct 
        if o_cand[1] == 'z' 
            c_m = first(edges[m[i+1]])
            o_true = first(setdiff(node[c_m].ins, [m[i+1]]))
            fix_nodes!(o_true, o_cand, node, swaps)
            o[i+1] = o_true
        end
        if m[i+1][1] == 'z'
            c_o = first(edges[o_cand])
            m_true = first(setdiff(node[c_o].ins, [o_cand]))
            fix_nodes!(m_true, m[i+1], node, swaps)
            m[i+1] = m_true
        end
        if edges[o_cand] != edges[m[i+1]] #these should have 1 edge and it should be the same 
            c_m = first(edges[m[i+1]])
            c_o = first(edges[o_cand])
            if node[c_m].op == | #then m is probably good and o wrong 
                o_true = first(setdiff(node[c_m].ins, [m[i+1]]))
                fix_nodes!(o_true, o_cand, node, swaps)
                o[i+1] = o_true
            elseif node[c_o].op == | #then o is probably good and m wrong
                m_true = first(setdiff(node[c_o].ins, [o_cand]))
                fix_nodes!(m_true, m[i+1], node, swaps)
                m[i+1] = m_true
            else #neither has a valid op, so we're out of luck finding an answer
                print("Unfixable anomaly - $(m[i+1]) and $(o[i+1]) should be parents of the c for $(i+1) element but no | operations with either\n")
            end
        end 
        #we assume m, o are resolved by here
        c[i+2] = first(edges[m[i+1]])  #this is tested by the next iteration of the loop
    end
    swaps
end 

swaps = find_anomaly(nodes, edges) |> keys |> collect |> sort 
print("$(join(swaps,","))\n")


#of course we're probably supposed to do the more general version of this (move from low to high bits, checking values to identify the points of errors)

#=
steps:
xN xor -> nN?
xN and -> mN?
does nN? xor cN? exist? 
 -> yes, and = zN G, n,c confirmed
 -> yes, and != zN (=??) -> ??, zN are switched partners, so note this and fix
 -> no
    -> is one of nN, cN part of the pair for zN?
       -> yes - the remaining part of the pair is the switched partner, fix
       -> no -> possible that zN is switched with another z!
             -> find zX such that nN or cN are part of its pair?
                     -> ....
once we have a confirmed nN, cN
nN and cN -> oN?
does mN? or oN? exist?
    -> yes -> assume result is c(N+1)?
    -> no -> does an (unfound) or pair with mN (or) oN exist? 
            -> if there's two of them, then I'm not sure how we break a tie
            -> if there's just 1 or pair, then assume the remaining part of the pair is the switched partner, fix 

once we have confirmed mN, oN

on to next N, forwarding c(N+1)?
=#
