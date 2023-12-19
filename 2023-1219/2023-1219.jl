#This looks like a graph parsing and simplification problem.

#Graph is mostly a binary tree which merges into two kinds of leaf (A, R)
#each L,R is a T,F split based on a predicate

#Trivial cases for simplification

# L,R are the same 
#          replace node with whatever L is (a leaf or a new node)
using InteractiveUtils

#Tracking cases
# 
# track state by dividing ranges of possible values at each node
# i.e if we start with A = [MININT, MAXINT]
# then the predicate A < 0 means that L inherits the state [MININT, -1], R inherits [0, MAXINT]
#
# if both sides of the range for the variable a predicate splits on have the same truth value
#   prune never taken route, replace node with the "always taken" branch  (L or R depending)

#Do the above via a depth-first search (because it's easier for me to think about the state propagators with DFS)

#struct Node
#    test::Function 
#    left::String #another NODE or A/R 
#    right::String
#end

#tt(x) = true 

#function parse_inst(instpair)
#    ip = split(instpair, ':') 
#    i,p = length(ip) == 2 ? (  eval(Meta.parse("T->T."*ip[1])), ip[2]) : (ip) #if terminal, add the trivial condition to it? 
#end

struct TT #x,m,a,s
    x::Int
    m::Int
    a::Int
    s::Int
end

function parse_structures(fi)
    #tree = Dict{String, Node}
    #items = []
    accum = 0
    open(fi) do f
        fr = Iterators.Stateful(readlines(f))
        for i in fr 
            if length(i) == 0 #newline that splits tree from items
                break
            end
            #parse tree into initial dict (we can do some cheap pruning here textually)
            #hlv{x>1142:fgz,snf}
            #name, tmp_instr, _ = split(i, ['{', '}']);
            #instructions = parse_inst.(split(tmp_instr, ','))

            #now walk the instructions set backwards, removing branches where both sides go to the same place


            #and insert into dict
            #tree[name] = instructions


            #it occurs to me at this point, having already done hacky eval(Meta.parse) stuff
            #that we could just translate each line into Julia and eval(Meta.parse) all of it, and let llvm sort out the optimising.

            #hlv{x>1142:fgz,snf} => hlv(T) = T.x>1142 ? fgz(T) : snf(T)
            #grq{m<453:A,x<1195:A,x>1305:R,R} => grq(T) = T.m<453 ? A(T) : T.x<1195 ? A(T) : T.x>1305 ? R(T) : R(T)
            #
            # where A(T) = true  and   R(T) = false

            #so, translation is 
            # sequence of 2 or 3 letters => sequence of three letters (T)
            #replace(input,  r"([a-z]{2,3})" => s"\1(T)", r"[^a-z]([amsx][^a-z])" => s"T.\1", r"{" => s" = ", r":" => " ? ", r"," => s":", r"A" => s" true ", r"R" => s" false ", r"}" => s";" )
            # "{" => " = "
            #replace(input, r"{" => s" = ")
            # x,m,a,s (with no other letters adjacent) => T.\1
            #replace(input, r"[^a-z]([amsx])[^a-z]" => s"T.\1")
            # ":" => ?
            #replace(input, r":" => s" ?")
            # "," =? ":"
            #replace(input, r"," => s":")
            # A => true
            #replace(input, r"A" => s" true ") 
            # R => false
            #replace(input, r"R" => s" false ")
            # "}" => "" or ";"
            #replace(input, r"}" => s"")

            julia_i = replace(i, r"([a-z]{2,3})" => s"X\1(T)", r"{" => s" = ", r"}" => s";", r"A" => s" true ", r"R" => s" false ", r":" => s" ? ", r"," => s" : ", r"([amsx][^a-z])" => s"T.\1")
            println("$i => $julia_i")
            eval(Meta.parse(julia_i)); #mahahahaha
        end
        #now on to processing the inputcases

        #helper to parse the right bit into a number
        parsefragment(x) = parse(Int, x[begin+2:end])
        TTs = []
        for p in fr
            #these are all in the same order so just chunk them out splitting on ,s 
            #{x=563,m=116,a=67,s=259}
            #x,m,a,s
            vals = parsefragment.(split(p[begin+1:end-1], ','))
            push!(TTs,TT(vals...))
            #accum += Base.invokelatest(Xin, input)
        end
        filt(T) = Base.invokelatest(Xin, T)
        #println("$(InteractiveUtils.code_llvm(Xin, (typeof(TTs[1]),), optimize=true))")
        mapper(T) = T.x+T.m+T.s+T.a
        accum = mapreduce(mapper, + ,filter(filt, TTs))
    end
    accum
end

f = "input"
println("$(parse_structures(f))")

#we can probably do part 2 by a lazy binary search through the x⊕m⊕a⊕s space I guess if we didn't want to do the analysis properly