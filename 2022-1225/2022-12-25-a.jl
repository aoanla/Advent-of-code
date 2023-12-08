
#part 1


function dec_to_balanced_q(x) 
    map = ["0", "1", "2", "=", "-"];
    out = ""
    while x > 0
        rem = x % 5;
        if rem < 3 
            x = (x-rem) ÷ 5;
        elseif rem == 3
            x = (x+2) ÷ 5;
        else # rem == 4
            x = (x+1) ÷ 5;
        end
        out = map[rem+1] * out;
    end
    out
end

open("input") do f
    accum = 0
    for line in eachline(f) 
        value::Int64 = foldl(collect(line); init=0) do acc, c
            c in ['2','1','0'] && return parse(Int64,c)+acc*5 ;
            c == '-' && return acc*5 - 1;
            acc*5 - 2;
        end
        
        accum += value
    end

    println("$accum");
    println("$(dec_to_balanced_q(accum))");
end

println("DONE")