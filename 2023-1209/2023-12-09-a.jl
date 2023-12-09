
using Printf
using BenchmarkTools




"""
    finite_diff(x)

    where x is a vector of values
    returns tuple of dx (the first differences) and same (if all values of dx are the same)
"""
function finite_diff(x)
    l = length(x);
    dx = zeros(l);
    same = true;
    dx[1] = x[2]-x[1];
    for i in 2:l
        dx[i]=x[i]-x[i-1];
        same &= (dx[i] == dx[i-1]);
    end
    (dx[2:end],same)
end

"""
    finite_diff!(x, l)

    where x is a vector of values [starting at the 2nd index - the first index being scratch]
    and l is the position of the *last* element in x with a real value
    returns new length l, same (if all values of dx are the same), modifies x in place with its differences
"""
function finite_diff!(x,l)
    same = true;
    x[1] = x[3]-x[2];
    for i in 3:l
        x[i-1]=x[i]-x[i-1];
        same &= (x[i-1] == x[i-2]);
    end
    (same,l-1)
end

"""
        extend_front_and_back!(x, l)

        where x is a vector of values [starting at the 2nd index, the first index being scratch]
        and l is the index of the last element used for values
        DESTROYS contents of x
        returns "zeroth" value of x in x[1] and "n+1th" value of x in x[2]
"""
function extend_front_and_back!(x, l)
    s = false;
    sgn = 1;
    next_x = x[l];
    prev_x = x[2];
    while !s #differentiate until we hit the constant differences
        #inlined function (s,l) = finite_diff!(samples, l);
        s = true;
        x[1] = x[3]-x[2];
        for i in 3:l
            x[i-1]=x[i]-x[i-1];
            s &= (x[i-1] == x[i-2]);
        end
        l -= 1;
        #end inline
        next_x += x[l];
        prev_x = x[2] - prev_x;
        #(samples,s) = finite_diff(samples);
        #next_x += samples[end]; #the next element of the top sample, accumulating the leading differences until constant
        #prev_x = samples[begin] - prev_x; #the previous element of the top sample, reducing "forwards"
        sgn = -sgn; #our "backwards" reduce above will flip the sign on odd summations so we need to reverse that if needed
    end
    x[1] = next_x;
    x[2] = sgn * prev_x;
end

"""
        parse_file(fname)
        
        where fname is a filename (string)

        returns a *static* array holding the file parsed into 1 column per line
        assumes the input data is rectangular.
"""
function parse_file(fname)
    open(fname) do f
        arr = Vector{Vector{Int64}}();
        for line in eachline(f)
            push!(arr, append!([0], parse.(Int64,split(line))));
        end
        arr
    end
end

#bulk read and then size statically sized matrix for data
function parse_file2(fname)
    data = read(fname);
    cols = count(==(0xA), data); #faster to just work with bytes than Unicode here - this is '\n'
    rows = 2 + count(==(0x20), data) ÷ cols; #this is ' ' - and we add 2 (one for the last num in the line, and one for our leading sentinel)
    arr = Array{Int64, 2}(undef,rows,cols); #TODO make this stack not heap
    col = 1;
    row = 2;
    num = 0;
    sgn = 1;
    for i in data
        if i == 0x2D #-sign
            sgn = -1;
            continue;
        end
        if i == 0x20 #new num
            arr[row, col] = sgn*num;
            num = 0;
            sgn = 1;
            row += 1;
            continue;
        end
        if i == 0xA #new col
            arr[row, col] = sgn*num;
            num = 0;
            sgn = 1;
            row = 2;
            col += 1;
            continue;
        end
        num = (num * 10) + i - 0x30; #'0'
    end 
    arr
end


function solve!(arr::Vector{Vector{Int64}})
    l = length(arr[1]); #data is rectangular, don't recheck each time
    parts = [0,0];
    for line in arr
        extend_front_and_back!(line, l);
        parts += line[1:2];
    end
    parts
end

function solve!(arr::Matrix{Int64})
    l = size(arr, 1); #data is rectangular, don't recheck each time
    parts = [0,0];
    for i in axes(arr,2)
        @views extend_front_and_back!(arr[:,i], l); #need a reference not a copy, so @views
        @views parts += arr[1:2, i];
    end
    parts
end


function solve(fname::String)
    arr = parse_file(fname); #parse
    solve!(arr)
end

function solve2(fname::String)
    arr = parse_file2(fname); #parse, to matrix
    solve!(arr)
end


p = solve2("input")

@printf "Part 1: %i\nPart 2: %i\n" p[1] p[2]
#=
p = solve("input")

@printf "Part 1: %i\nPart 2: %i\n" p[1] p[2]
=#

#A note on benchmarks so far (at the default optimisation for the Julia shell! I would hope O3 is faster...)

# parse_file2 parses the input about 9x faster than parse_file does ...
# (on my machine, 38μs vs 378μs)
# ... and the solvers run about the same speed (solve on Matrix from parse_file2 is maybe 2-3μs faster?)
# (on my machine 44μs vs 47μs)
#so, overall "solve2" is much faster than "solve" 
# (on my machine 75μs v 428μs )
#=
julia> @benchmark solve2("input")
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  73.640 μs …  1.556 ms  ┊ GC (min … max): 0.00% … 89.45%
 Time  (median):     75.404 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   78.860 μs ± 41.467 μs  ┊ GC (mean ± σ):  1.82% ±  3.29%

  ▂▆▇█▆▃▁ ▁▁ ▁▂                             ▁▂▁▁              ▂
  █████████████▇▆▆▄▃▄▃▄▄▄▁▁▅▃▁▅▄▄▁▁▃▄▃▄▃▄▆▇███████▇▆▇▆▅▆▆██▇▇ █
  73.6 μs      Histogram: log(frequency) by time       105 μs <

 Memory estimate: 71.55 KiB, allocs estimate: 215.
julia> @benchmark solve!(arr) setup=(arr=parse_file2("input"))
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  43.383 μs … 751.012 μs  ┊ GC (min … max): 0.00% … 88.68%
 Time  (median):     43.854 μs               ┊ GC (median):    0.00%
 Time  (mean ± σ):   44.360 μs ±   8.112 μs  ┊ GC (mean ± σ):  0.15% ±  0.89%

  ▂▆██▇▅▄▂▁                                                    ▂
  ██████████▆▆▅▅▅▆▄▅▅▃▅▅▅▅▆▆▅▆▄▄▄▄▄▅▄▄▅▅▅▄▄▁▃▄▄▅▇██▇▆▄▄▆▆▅▅▇▇▆ █
  43.4 μs       Histogram: log(frequency) by time      51.6 μs <

 Memory estimate: 15.70 KiB, allocs estimate: 201.

 julia> @benchmark parse_file2("input")
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  37.181 μs … 952.436 μs  ┊ GC (min … max): 0.00% … 89.17%
 Time  (median):     38.474 μs               ┊ GC (median):    0.00%
 Time  (mean ± σ):   41.726 μs ±  23.707 μs  ┊ GC (mean ± σ):  1.52% ±  2.81%

   ▆█▇▄▂        ▁▃                              ▂▂▁▂▁▁         ▂
  ▇█████▇▇▇██▇▇▇███▆▅▅▅▄▄▅▅▄▄▁▄▄▄▃▄▄▄▅▄▄▄▅▅▄▆▇██████████▇▆▆▆▅▅ █
  37.2 μs       Histogram: log(frequency) by time      64.3 μs <

 Memory estimate: 55.85 KiB, allocs estimate: 14.
#for comparison, the super slow parse_file: 
 julia> @benchmark parse_file("input")
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  376.226 μs …  1.463 ms  ┊ GC (min … max): 0.00% … 58.35%
 Time  (median):     381.357 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   390.393 μs ± 65.931 μs  ┊ GC (mean ± σ):  1.36% ±  5.49%

  █▇▄▁                                                         ▁
  ████▇▆▄▅▁▄▃▁▃▁▄▁▃▁▁▁▁▃▄▃▃▆▄██▇▄▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▃▃▁▁▃▁▁▁▄▁▁▁▁▄ █
  376 μs        Histogram: log(frequency) by time       724 μs <

 Memory estimate: 376.35 KiB, allocs estimate: 1415.
=#


