
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



open("input") do f
    accum = 0;
    accum2 = 0;
    for line in eachline(f)
        samples = append!([0], parse.(Int64,split(line)));
        l = length(samples);
        s = false;
        sgn = 1;
        next_x = samples[end];
        prev_x = samples[2];
        while !s #differentiate until we hit the constant differences
            #inlined function (s,l) = finite_diff!(samples, l);
            s = true;
            samples[1] = samples[3]-samples[2];
            for i in 3:l
                samples[i-1]=samples[i]-samples[i-1];
                s &= (samples[i-1] == samples[i-2]);
            end
            l -= 1;
            #end inline
            next_x += samples[l];
            prev_x = samples[2] - prev_x;
            #(samples,s) = finite_diff(samples);
            #next_x += samples[end]; #the next element of the top sample, accumulating the leading differences until constant
            #prev_x = samples[begin] - prev_x; #the previous element of the top sample, reducing "forwards"
            sgn = -sgn; #our "backwards" reduce above will flip the sign on odd summations so we need to reverse that if needed
        end
        accum += next_x;
        accum2 += sgn*prev_x; #fix sign!
    end
    @printf "Part one: %i\n" accum
    @printf "Part two: %i\n" accum2
end