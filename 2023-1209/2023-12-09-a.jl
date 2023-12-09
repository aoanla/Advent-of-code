
using Printf

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

open("input") do f
    accum = 0;
    accum2 = 0;
    for line in eachline(f)
        samples = parse.(Int64,split(line));
        s = false;
        sgn = 1;
        next_x = samples[end];
        prev_x = samples[begin];
        while !s #differentiate until we hit the constant differences
            (samples,s) = finite_diff(samples);
            next_x += samples[end]; #the next element of the top sample, accumulating the leading differences until constant
            prev_x = samples[begin] - prev_x; #the previous element of the top sample, reducing "forwards"
            sgn = -sgn; #our "backwards" reduce above will flip the sign on odd summations so we need to reverse that if needed
        end
        accum += next_x;
        accum2 += sgn*prev_x; #fix sign!
    end
    @printf "Part one: %i\n" accum
    @printf "Part two: %i\n" accum2
end