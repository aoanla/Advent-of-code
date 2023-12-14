# No time to really write code for this but some notes


# obviously the combinatrical "try every possible ? as a # or a ." is stupid and won't work.

#I think we need to use sliding windows of each "number of consecutives" to break this down into combinatrically sensible units.
# as the "number of consecutives" need to end on a ., an N means a window of N+2 [where we start the *next* window on the 
# final element - the "space" - of the previous one]

#it's tempting to try to optimise this more by starting with the "hardest to match" window (== the longest one)
# but if that's in the middle, we would also need to check the space left on either side to hold the remaining windows

#obviously, to make the windows easy, we extend each vector of #?. by one . start and end so our window edges fit.

#so, from the left or the right:

#if from the left, the left of the window can be the sequence start - if we always ensure the next substring would start with a . (or ?) [which it would if the right 
#of the window catches it but isn't included in the "match string" removed.]

#fn(substring)
# matches = 0;
# [try first match and recurse]
#
#while match(window_n, substring)
#   if not last window
#       if nothing_memoised
#           (matches, memoised_substring_lengths) += call fn(window_n+1, substring - [sequence we just consumed])
#        else
#            matches+= memoised_matches where substring <= current substring length
#   else
#       (matches, memoised_substring_length_at_match) += 1, match_length
#return ( matches, memoised_list_of_matches_by_substring)

#that seems relatively sensible?
#the matches are either just using regex or I could write a sliding-window thing myself if I cared

#match(window_n, substring_start, string)
 #   for i in substring_start:length(string)-window_n
    #or
 #   i = substring_start
 #   while string[i] != '#' #we must match a *space* before this sequence starts
        #match if
 #       string[i] to string[i+window_n-1] != '.' 
        #and
 #       string[i+window_n] != '#'
        #and do
            #match++
            #push (i) => list_of_match_posns
  #          i+=1

d = read("input", String); 

rawcodes = String[];
codes = String[];
patterns = Array{Int}[];

function parse_line(line)
    (code, windows) = split(line, ' ');
    code1 = code * "."; #extra dot padding to make the window matching work
    (code, code1, parse.(Int, (split(windows, ',')) ) ) 
end

for line in split(d, '\n')
    if length(line) < 2
        break;
    end
    push!.((rawcodes,codes,patterns), parse_line(line) ) ; 
end

println("$(codes[1])")
println("$(patterns[1])")

#memoisation unit - length of substring needed for this submatch, number of matches in it
struct sub_match
    length::Int
    matches::Int
end

#BUG:
# currently:
# ??#.???????#??#??.. 1,1,9
# window 1 matches on first ?
# so entire cache matches just on the one solution for that - which needs 2 to match on first # (on posn 3)
# (so we miss the solution where 1 matches at posn 3, allowing 2 to match the start of the second set of ?s )

#so, we need to be able to "re-call" the recursed functions to add more options - *if* we change the sets of # (and only #, not ?) we consume

#need public shared cache for pt2 - maps pairs of Substring patterns and the remaining windows => number of solutions for that 
cache = Dict{(String,Vector{Int}), Int}

#do we need an equality rule that ignores leading .? (since they don't matter for the substring if they're in the way)?

#you know, the above is probably *solved* if we do better memoisation needed for part 2 (and memoise the pattern sequence not just the length) without needing the cache invalidation

function match(windows, substring_start, string)
    matches = 0;
    match_list = Dict{Int, Int}();
    i = substring_start;
    window_n = windows[1];
    cache = [];
    met_hash = false;
    #println("Substring start at $i")
    while i == 1 || ( string[i-1] != '#' && i+window_n <= length(string) )#we must not let any #s escape past our sequence
        #match if
        #println("$window_n")
        #                   pattern matches # or ?                      and there's . or ? padding          and, if this is the last pattern, there's no # left
        @views  if  all( '.' .!= collect(string[i:i+window_n-1]) ) & (string[i+window_n] != '#') & ( length(windows) > 1 || all('#'.!=collect(string[i+window_n:end])))
            # !met_hash && any('#' .== collect(string[i:i+window_n-1]) ) #state change - we hadn't met a hash in our pattern just ? previously
            #                                                             which means we need to regenerate the cache as our restrictions on upstream patterns have changed
            if isempty(cache) ||  ( !met_hash && any('#' .== collect(string[i:i+window_n-1]) ) )
                #recurse and fill cache with matches downstream, until there is no downstream
        @views  cache = length(windows) > 1 ? match(windows[2:end], i+window_n+1, string) : Dict([(length(string)+1=>1 )]); 
        #default is a single match *if* we've consumed all the #s in the entire string with our last pattern
            end
            #sum the cached elements compatible with our current "end string position" for our accrued matches recursed
            match_list[i] = sum(values(filter(items->items.first>i+window_n, cache)));
        end
        i += 1;
    end
    #println("Matches at $match_list");
    #println("Candidates end at: $i");
    filter(items->items.second>0, match_list)
end

solve(pc) = sum(values(match(pc[1], 1, pc[2])));


println("$(mapreduce((x)->solve(x), +, zip(patterns,codes)))");


#part 2 - lets hope our memoisation is fast enough!

#it isn't - we're going to need to interleave these with the pt1 examples and use the memoisations from the previous versions
# we *can't* just blindly raise the combinations to the power 5, because for some examples, the extra ? might allow a degree of freedom...
# (although, yes, most of the cases will be covered by that, which is why the caches are useful)
#but = for later!

# I think we actually need to memoise over the entire set of puzzles - and do better memoisation in that case (associate result with actual pattern fragment)
# rather than just offset counts 


#further note - it's actually probably necessary to do the dynamic programming thing here and attack from both directions to catch all possibilities
# (this was already implied by part 1 - where I fudged it by requiring the last match should not have any # to the right of it, but it
#  "should" be done by moving in from the left and right "simultaneously" and matching up in the middle)

pt2patterns = repeat.(patterns, 5);
println("$(patterns[1])  => $(pt2patterns[1])");
pt2codes = repeat.(rawcodes .* "A", 5)[begin:end-1];  #remove the final ?
println("$(rawcodes[1]) => $(pt2codes[1])");

#println("$(mapreduce(solve, +, zip(pt2patterns,pt2codes)))");

#=
for (p,c) in zip(patterns,codes)
    println("$c : $p")
    println("$(match(p, 1, c))")
#    println("$(sum(values(match(p, 1, c))))");
#    println("$(solve((p=>c)))");
end
#==#