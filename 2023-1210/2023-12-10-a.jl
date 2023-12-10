

#part 1

#this is the first puzzle where we can't really get away with parsing line-by-line and need to pull in the whole file first

d = read("input2");

size = length(d); #unsure if I should count the newlines here or not tbh - or if I should floodfill them
total = size;

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

marked(x) = (x & 0x80) == 0x80  ;
horiz_wall(x) = x == (b('-')|0x80) ;
vert_wall(x) = x == (b('|')|0x80) ;
already_filled(x) = x == (b('O'));  

"""checks if we can move in dir from curr without hitting a blocking boundary, and mutates cell if it's not a loop element
    returns (can_we_move?, add_to_counter, where_are_we_now?)
    DOES NOT check boundaries of the map!!! (at loc < 0, loc > size, or a loc moving from loc % s = 0 to 1 or vice versa  )
"""
function attempt_move(curr, dir)
    new = curr+dir;
    cell = d[new]; #candidate cell
    #stop if we hit an already filled patch
    already_filled(cell) && return (false, 0, curr);
    ##a blocking wall means no 
    horiz_wall(cell) && abs(dir) == s && return (false, 0, curr);
    vert_wall(cell) && abs(dir) == e && return (false, 0, curr);
    if !marked(new) #move is allowed and is mutating [not a loop element we flow down]
        d[ch] = b('O');
        counter = 1
        return (true, 1, new); 
    end
    (true, 0, new)
end
    

"""Floodfill algorithm, bounded by Ss, on d starting at boundaries"""
function floodfill_with_count(start, d)
    accum = 0;
    #fill from top first
    for i in 1:s  #first row
        cell = i;
        result = true;
        dir = s; 
        while result 
            (result, count, cell) =  attempt_move(cell, dir);
            accum += count;
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
    inside = total - steps #"the boundary" can't be inside itself.
    println("Total $steps to circumnavigate, halfway is thus $(steps ÷ 2)");
    println("")
    println("$(String(d.&0x7f))") #remove marker bits
end

solve2!(d)