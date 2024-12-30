#this looks like subsequence matching [with backtracking] like soln for 17pt2. 
#in this case, we probably need to memoise to make it tractable.

#note - my input sequence, at least, has 4 of 5 colours as single letters (just missing a 'w'), so all sequences with no 'w' are trivially possible.
#       it's also worth noting that this means that *several* of the longer sequences can be decomposed into shorter ones already

#we probably want to order the matchable subsequences by length, and by first letter?, and try to greedily match the longer ones first (and then backtrack if the
# remaining parts of the string can't match things)

#we can memoise successful combinations of subsequences (and mark them as "not original" in the dictionary), and also memoise failed ones to save time. 

#is equality testing more efficient (if we map the sequences to octal values, we can just do numeric comparison)


#I think this is a good place to experiment with Memoization.jl because I've never used it before
using Memoization

t = Dict{Int64,Set{String}}()



function parse_input(input)
    towels = Vector{Regex}()
    targets = Vector{String}()
    t = true 
    for i ∈ readlines(input)
        if t
            towels = split(i, ", ") |> Base.Fix1(map, ii->Regex("^$ii(.*)"))
            t = false 
            continue
        end
        length(i) == 0 && continue 
        push!(targets, i)
    end
    (towels, targets)
end

#trivial version just to see if it works before we try the hard stuff above... (where we'll need to categorise by sequence length etc)
@memoize function match_string(str, towels)
    length(str) == 0 && return true
    for i ∈ towels
        m = match(i,str)
        !isnothing(m) && match_string(m[1], towels) && return true 
    end
    false 
end 

#...okay, I don't need any of the clever stuff above to make this tractable apparently, so we can just do the obvious loop for this one:
@memoize function combi_string(str, towels)
    length(str) == 0 && return 1
    counter = 0
    for i ∈ towels
        m = match(i,str)
        counter += isnothing(m) ? 0 : combi_string(m[1], towels)  #this could be represented just as a sum now because we can't early exit
    end
    counter 
end 


(towels, targets) = parse_input("input")

print("Pt1: $(mapreduce(t->match_string(t, towels), +, targets))\n")
print("Pt2: $(mapreduce(t->combi_string(t, towels), +, targets))\n")

