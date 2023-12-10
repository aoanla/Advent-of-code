

#part 1

#this is the first puzzle where we can't really get away with parsing line-by-line and need to pull in the whole file first

data = read("input");
linedata = data.split

# Tuple(usize,usize)
n = (-1,0);
s = (1,0);
e = (0, -1);
w = (0, 1);
START = ((0,0),(0,0));
NULL = ((-1,-1),(-1,-1)));

function raw_to_directions(ch)
    #"julian" switch-case via ternary chain
    ch == '|' ? (n,s) :
    ch == '-' ? (e,w) :
    ch == 'L' ? (n,e) :
    ch == 'J' ? (n,w) : 
    ch == '7' ? (s,w) : 
    ch == 'F' ? (s,e) : 
    ch == 'S' ? START :
    NULL ;
    ch
end

function find_start_and_connectors(d)
    #find start

    #check four cells around it for the two cells that connect
    adjs = (c1,c2);

    return (start, adjs)
end

# indexing map[direction...] splat to map correctly
function follow_pipe()
    # d= "direction we just moved in"  
    newdir = curr_pipe[ (curr_pipe[1]==(.-d))+1  ];  #comparison is 0 or 1, so we can branchlessly map to the end we didn't enter from
    curr_pipe_loc .+= newdir;
    curr_pipe = parsed_data[curr_pipe_loc...]; #need to splat the tuple

end