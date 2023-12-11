

#part 1

#this is the first puzzle where we can't really get away with parsing line-by-line and need to pull in the whole file first

d = read("input");


size = length(d); #unsure if I should count the newlines here or not tbh - or if I should floodfill them
total = size;
println("Size is: $size");


b(x) = UInt8(x);

s = findfirst(x-> x==b('\n'), d); #going "up" a row is subtracting stride 

# Tuple(usize,usize)
n = -s;
e = 1;
w = -1;
START = 0;
NULL = 999;

decode = Dict([
     b('|') => (n,s) ,
     b('-') => (e,w) ,
     b('L') => (n,e) ,
     b('J') => (n,w) , 
     b('7') => (s,w) , 
     b('F') => (s,e) , 
     b('S') => (START,START) ])

     #for the S to id it for part 2 leak detection
encode = Dict([(v=>k) for (k,v) in pairs(decode)]);


function find_start_and_connector(d)
    #find start
    start = findfirst( x -> x==b('S'), d);
    #check four cells around it for a cell that connects (we don't care which, because we just need a start point)
    (adj,dir) = d[start+n] in b.(['|', '7', 'F']) ? (start+n, n) :  #items that connect to "their south" == our north
           d[start+s] in b.(['|', 'L', 'J']) ? (start+s, s) : (start+e, e) ; #only two options left, so it must be both of them!
           # ch[start+e] in ['-', 'J', '7'] ? start+e : start+w ; #because it must be connected somewhere
    return (adj,dir)
end

# indexing map[direction...] splat to map correctly
function follow_pipe(curr_pipe, entry_dir, d)
    directions = decode[d[curr_pipe]];
    entry_dir = directions[ (directions[1]==-entry_dir)+1  ];  #comparison is 0 or 1, so we can branchlessly map to the end we didn't enter from
    curr_pipe += entry_dir;
    (curr_pipe, entry_dir)
end

""" modifies d to leave trail """
function follow_pipe_and_mark!(curr_pipe, entry_dir, d)
    directions = decode[d[curr_pipe]];
    entry_dir = directions[ (directions[1]==-entry_dir)+1  ];  #comparison is 0 or 1, so we can branchlessly map to the end we didn't enter from
    d[curr_pipe] |= 0x80; #set high bit
    curr_pipe += entry_dir;
    (curr_pipe, entry_dir)
end

marked(x) = (x&0x80) == 0x80 ;
horiz_wall(x) = x==(b('-')|0x80);

"""cast rays through d, vertically, counting cells with an odd-crossing count (interior cells)"""
function raycast!(d) 
    accum = 0;
    for i in 1:s-1 
        cell = i;
        polarity = 0;
        while cell <= size
            contents = d[cell];
            #handle boundaries, which is subtle - perpendicular boundaries (here, horizontal) just flip the sign, others don't, we just need to skip them!
            # but *some* bends should count as perpendicular boundaries (when we exit the set with the same "directional turn" as we entered
            # that is 
            #           F                               7
            #           |  a zero polarity set          |   a switching set === -
            #           L                               L

            if marked(contents)
                horiz = horiz_wall(contents);
                right = contents in [b('F')|0x80, b('L')|0x80]; #polarity of this will be odd if we need to switch polarity one more time
                while (cell<=size-s) && marked(d[cell+s])
                    cell += s;
                    contents = d[cell];
                    horiz ⊻= horiz_wall(contents);
                    right ⊻= contents in [b('F')|0x80, b('L')|0x80];

                end
                #... *after* we finish the set, we switch polarity if xor(horiz,right) is true and only if that is true
                if (horiz ⊻ right) 
                    polarity = 1 - polarity;
                end
            else
                accum += polarity;
                d[cell] = b('0')+polarity;
            end
            cell += s;
        end
    end
    accum
end

function solve(d)
    (curr_pipe, entry_dir) = find_start_and_connector(d);
    steps = 1;
    initial_dir = entry_dir; #to id 'S' after
    while d[curr_pipe] != b('S')
        (curr_pipe, entry_dir) = follow_pipe(curr_pipe, entry_dir, d);
        steps += 1;
    end
    println("Total $steps to circumnavigate, halfway is thus $(steps ÷ 2)");
end

solve(d);

#solve part 2, destructively on d
function solve2!(d)
    println("$(String(d.&0x7f))") #remove marker bits
    (curr_pipe, entry_dir) = find_start_and_connector(d);
    start_dir = entry_dir;
    steps = 1;
    while d[curr_pipe] != b('S')
        (curr_pipe, entry_dir) = follow_pipe_and_mark!(curr_pipe, entry_dir, d);
        steps += 1;
    end
    c = encode[(start_dir, -entry_dir)];
    println("S was a $c !");
    d[curr_pipe] = c | 0x80; #mark and set type
    println("Total $steps to circumnavigate, halfway is thus $(steps ÷ 2)");
    println("");
    inside = raycast!(d);
    println("Inside cells: $inside");
    println();
    println("$(String(d.&0x7f))"); #remove marker bits
end

solve2!(d)