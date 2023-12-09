
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
    arr = Array{Int64, 2}(undef,cols,rows); #TODO make this stack not heap
    col = 1;
    row = 2;
    num = 0;
    for i in data
        if i == 0x20 #new num
            arr[col, row] = num;
            num = 0;
            row += 1;
            continue;
        end
        if i == 0xA #new col
            arr[col, row] = num;
            num = 0;
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
        extend_front_and_back!(line, l)
        parts += line[1:2];
    end
    parts
end

function solve!(arr::Matrix{Int64})
    l = size(arr, 2); #data is rectangular, don't recheck each time
    parts = [0,0];
    for i in axes(arr,1)
        @views extend_front_and_back!(arr[i,:], l); #need a reference not a copy, so @views
        @views parts += arr[i, 1:2];
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

#A note on benchmarks so far:

# parse_file2 parses the input about 11x faster than parse_file does ...
# (on my machine, 32μs vs 378μs)
# ...however, the solver on the Array of Arrays (from parse_file) runs ~20% faster than the one on the Matrix (from parse_file2)
# (on my machine 47μs vs 58μs)

#so, overall "solve2" is much faster than "solve" 
# (on my machine 90μs v 428μs )
# but it could be ~10% faster (on my machine ~80μs) if I could get the performance in the Matrix solver

#println("""$(solve("input"))""");

#=
julia> @benchmark solve!(arr) setup=(arr=parse_file2("input"))
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  56.288 μs …  1.961 ms  ┊ GC (min … max): 0.00% … 94.28%
 Time  (median):     58.472 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   59.732 μs ± 35.377 μs  ┊ GC (mean ± σ):  1.39% ±  2.28%

      ▁▄▇██▆▃▁                                                 
  ▂▂▃▅████████▇▅▄▃▃▃▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▁▂▂▁▂▁▁▂▂▂▁▂▂▂▂▂▂ ▃
  56.3 μs         Histogram: frequency by time        71.6 μs <

 Memory estimate: 31.33 KiB, allocs estimate: 401.

julia> @benchmark solve!(arr) setup=(arr=parse_file("input"))
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  45.436 μs … 946.283 μs  ┊ GC (min … max): 0.00% … 91.46%
 Time  (median):     46.719 μs               ┊ GC (median):    0.00%
 Time  (mean ± σ):   47.287 μs ±  16.899 μs  ┊ GC (mean ± σ):  0.68% ±  1.82%

     ▁▁  ▄█▆▄▁                                                  
  ▂▂▅██▇██████▆▆▅▅▅▃▃▃▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▁▂▂▂▁▂▂▂▂▂▂▁▂▁▁▂▂▂ ▃
  45.4 μs         Histogram: frequency by time         53.9 μs <

 Memory estimate: 31.33 KiB, allocs estimate: 401.

julia> @benchmark parse_file("input")
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  372.650 μs …  1.923 ms  ┊ GC (min … max): 0.00% … 62.66%
 Time  (median):     378.210 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   388.868 μs ± 72.960 μs  ┊ GC (mean ± σ):  1.47% ±  5.64%

  ██▄▂                                                         ▂
  ████▇▆▄▄▃▁▁▁▃▄▃▁▃▃▁▃▁▁▁▃▁▄▃▃▅██▆▅▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▄▁▅▆▆▆▆▃▁▃▅▅ █
  373 μs        Histogram: log(frequency) by time       696 μs <

 Memory estimate: 376.35 KiB, allocs estimate: 1415.

julia> @benchmark parse_file2("input")
BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  29.997 μs …  1.567 ms  ┊ GC (min … max): 0.00% … 93.34%
 Time  (median):     31.770 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   35.975 μs ± 35.958 μs  ┊ GC (mean ± σ):  2.84% ±  3.05%

   ▃▆██▆▄▂▁                        ▁▁▂▂▃▃▃▃▃▃▂▁▁              ▂
  ▇████████▇▇▇▇▇▇▇█▆▆▅▄▅▆▄▄▄▄▂▂▂▅▄▇███████████████▇▇▅▅▆▅▅▆▅▅▆ █
  30 μs        Histogram: log(frequency) by time      52.9 μs <

 Memory estimate: 55.85 KiB, allocs estimate: 14.
 =#
