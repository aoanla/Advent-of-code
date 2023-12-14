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

#need public shared cache for pt2 - maps pairs of Substring patterns and the remaining windows => number of solutions for that 
pubcache = Dict{Tuple{String,Vector{Int}}, Int}();

trim(str) = startswith(str, "..") ? "." * lstrip(str, '.') : str; 

#do we need an equality rule that ignores leading .? (since they don't matter for the substring if they're in the way)?

#you know, the above is probably *solved* if we do better memoisation needed for part 2 (and memoise the pattern sequence not just the length) without needing the cache invalidation


function match(windows, string)
    #println("in Match: $windows, $string");
    ss = trim(string);
    length(ss) == 1 && return 0; #early return for reaching the "fake" ending .
    #if key((trim(substring), windows) is in the cache, return the cached values - can happen hypothetically?
    k = (ss, windows[begin:end]);
    haskey(pubcache, k) && return pubcache[k] ;
    window_width = sum(windows);
    max_i = length(string) - window_width - length(windows) + 1; #don't iterate so far that you run out of room for the windows 
    matches = 0;
    i = 1;

    #set matches = 0;
    #else, try to find a match for the first window, iterating through the substring, without letting a # escape and leaving enough room for the rest of the windows
    while i <= max_i  && ( i == 1 || ( string[i-1] != '#' ) )  
        #match first window
        #                   pattern matches # or ?                      and there's . or ? padding          
@views  if  all( '.' .!= collect(string[i:i+windows[1]-1]) ) & (string[i+windows[1]] != '#')
            # is length(window) == 1 and we've consumed all the hashes - so this *is* a valid match
            if length(windows) == 1
                matches += all('#'.!=collect(string[i+windows[1]:end])); #using true as 1
            else 
                sss = trim(string[i+windows[1]+1:end]);
                kk = (sss, windows[2:end])  
            # is (trim(rest_of_substring), windows[2:end]) in the cache, if not do the work
                matches += haskey(pubcache, kk) ? pubcache[kk] : match(windows[2:end], sss);
            end
        end
        i+=1
    end
    pubcache[k] = matches;
    matches
end

# ?.???????.????.. [5, 1, 1] problematic
#println("$(match([5,1,1], "?.???????.????..."))")

solve(pc) = begin
    #println("$(pc[2]) $(pc[1])");
    sum(values(match(pc[1], pc[2])))
end

println("$(mapreduce((x)->solve(x), +, zip(patterns,codes)))");

#part 2 - lets hope our memoisation is fast enough!


pt2patterns = repeat.(patterns, 5);
#println("$(patterns[1])  => $(pt2patterns[1])");

repstr(x) = repeat(x * "?",5)[begin:end-1] * ".";

pt2codes = repstr.(rawcodes) ; #(repeat.(rawcodes .* "?", 5)) ;  #remove the final ?
#println("$(rawcodes[1]) => $(pt2codes[1])");

println("$(mapreduce(solve, +, zip(pt2patterns,pt2codes)))");

#=
for (p,c) in zip(patterns,codes)
    println("$c : $p")
    println("$(match(p, 1, c))")
#    println("$(sum(values(match(p, 1, c))))");
#    println("$(solve((p=>c)))");
end
=#