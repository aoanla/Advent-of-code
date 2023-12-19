#This looks like a graph parsing and simplification problem.

#Graph is mostly a binary tree which merges into two kinds of leaf (A, R)
#each L,R is a T,F split based on a predicate

#Trivial cases for simplification

# L,R are the same 
#          replace node with whatever L is (a leaf or a new node)


#Tracking cases
# 
# track state by dividing ranges of possible values at each node
# i.e if we start with A = [MININT, MAXINT]
# then the predicate A < 0 means that L inherits the state [MININT, -1], R inherits [0, MAXINT]
#
# if both sides of the range for the variable a predicate splits on have the same truth value
#   prune never taken route, replace node with the "always taken" branch  (L or R depending)

#Do the above via a depth-first search (because it's easier for me to think about the state propagators with DFS)

struct Node
    test::Function 
    left::String #another NODE or A/R 
    right::String
end

tt(x) = true 

function parse_inst(instpair)
    ip = split(instpair, ':') 
    i,p = length(ip) == 2 ? (  eval(Meta.parse("T->T."*ip[1])), ip[2]) : (ip) #if terminal, add the trivial condition to it? 
end

function parse_structures(fi)
    tree = Dict{String, Node}
    items = []

    open(fi) do f
        fr = readlines(f)
        for i in fr 
            if length(i) == 1 #newline that splits tree from items
                break
            end
            #parse tree into initial dict (we can do some cheap pruning here textually)
            #hlv{x>1142:fgz,snf}
            name, tmp_instr, _ = split(i, ['{', '}']);
            instructions = parse_inst.(split(tmp_instr, ','))

            #now walk the instructions set backwards, removing branches where both sides go to the same place


            #and insert into dict
            tree[name] = instructions


            #it occurs to me at this point, having already done hacky eval(Meta.parse) stuff
            #that we could just translate each line into Julia and eval(Meta.parse) all of it, and let llvm sort out the optimising.

            #hlv{x>1142:fgz,snf} => hlv(T) = T.x>1142 ? fgz(T) : snf(T)
            #grq{m<453:A,x<1195:A,x>1305:R,R} => grq(T) = T.m<453 ? A(T) : T.x<1195 ? A(T) : T.x>1305 ? R(T) : R(T)
            #
            # where A(T) = true  and   R(T) = false

            #so, translation is 
            # sequence of 3 letters => sequence of three letters (T)
            # "{" => " = "
            # x,m,a,s (with no other letters adjacent) => T.\1
            # ":" => ?
            # "," =? ":"
            # A => true 
            # R => false
            # "}" => "" or ";"

        end
        #now on to processing the inputcases

        #helper to parse the right bit into a number
        parsefragment(x) = parse(Int, x[begin+2:end])

        for p in fr
            #these are all in the same order so just chunk them out splitting on ,s 
            #{x=563,m=116,a=67,s=259}
            #x,m,a,s
            vals = parsefragment.(split(p[begin+1:end-1], ','))

        end

    end

end