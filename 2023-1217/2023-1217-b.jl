#"The A* one, part 2"
using Pkg
Pkg.activate(".")
using GLMakie
using DataStructures #I really don't to write my own PriorityQueue

#I think A* is probably fine for this, if the heuristic encodes the cost of an overall angle of approach that makes it hard to "alternate directions"
# (That is: since we have to move 1 orthogonally for every 3 down, at least, paths which are "straight down" actually cost more since we have to go
#                                                                                                                   3 down, 1 left, 1 right [total cost 5]

d = read("input");
width = findfirst(==(UInt8('\n')), d);
matrix = (reshape(d, width, :)[begin:end-1, :]) .- UInt8('0');
println("$(size(matrix))")
bounds= size(matrix)
goal = CartesianIndex(bounds) #that's the last coordinate, so!
#bounds = bounds(matrix)
#exp_bounds = vcat([ i for i in bounds ], [4, 3]); #extra dimensions are "direction from" and "amount" 

CI(x,y) = CartesianIndex((x,y))

dir_to_num = Dict([CI(0,1)=>1, CI(0,-1)=>2, CI(1,0)=>3, CI(-1,0)=>4]);
num_to_dir = [CI(0,1), CI(0,-1), CI(1,0), CI(-1,0)];
max_c = 10;

struct cell_data
    c::CartesianIndex{2} #the cell itself
    dir::Int
    count::Int #its history - how it was got to, and how many successive moves 
end


#note: check this is 1/3 and not 1/4 - the example shows chains of 4 squares in a row from 3 *movements* 
#           if 1/4 then 3->4 , 5*x÷3 -> (1 + 1/4 + 1/4) = 3*x÷2 ? 
""" h(posn)

    Return a suitable heuristic for the remaining distance (encoding the "no more than 3 steps in a straight line" rule)
""" 
function h(posn::cell_data)
    #improvement - use movehist to tweak this estimate (only really significant for short distances where it matters if we can't move 3 in one dir in one go)
    #return 0 # try with Dijkstra - okay, so the problem isn't h 
    d = goal - posn.c;
    return d[1]+d[2]
    d == CI(0,0) && return 0
    (bigger, smaller) = d[1] > d[2] ? (d[1], d[2]) : (d[2], d[1])
    slope = smaller != 0 ? bigger ÷ smaller : bigger ; 
    #we're within the range where we can jink around and still get there within Metropolis distance
    slope < 4 && return d[1]+d[2]
    #otherwise, we'd have to make up the excess by going back and forth - a cost equivalent to doing a 3:1 slope and then "running back" the excess distance orthogonally
    #in fact bigger > 3smaller here, 1/3 bigger > smaller!
    #bigger +  bigger ÷ 3  #=3:1=# + bigger ÷ 3 - smaller #=excess we need to also "do"=#
    #5bigger ÷ 3  - smaller
    3bigger ÷ 2 - smaller
end

possibles = Set(CartesianIndex.([(0,1), (1,0), (0,-1), (-1,0) ]) );

""" return a list of locations accessible from c with its current move history annotation
    - we can't get the node "back" from movehist 
    - we can't get the node *forward* from movehist if count == 10
    - we can't go any direction *other* than forward if count < 4
    - we can't violate bounds!
"""
function accessible(c)
    #                       yes 4, thanks Julia for indexing at 1
    if c.count < 4
        return checkbounds(Bool, matrix, c.c+num_to_dir[c.dir]) ? [num_to_dir[c.dir]] : []
        #return c.dir #can only go forward 
    end
    notaccessible = c.count == 10 ? [num_to_dir[c.dir], num_to_dir[c.dir]*-1] : [num_to_dir[c.dir]*-1]
    p = setdiff(possibles, notaccessible)
    filter(p) do pp 
        checkbounds(Bool, matrix, c.c+pp)
    end     
end

function reconstruct_path(prev, cursor)
    totalpath = [cursor]
    while cursor in keys(prev)
        cursor = prev[cursor]
        pushfirst!(totalpath, cursor)
    end
    totalpath
end

makie_markers = ['▾', '▴', '▶', '◀']
#makie_markers = ['▶', '◀', '▾', '▴']

""" path here is an output of reconstruct_path containing cell_data objects
"""
function path_to_makie(path)
    points = (x->Point2f(x.c[1], x.c[2])).(path) 
    dirs = (x->makie_markers[x.dir]).(path)
    counts  = (x->x.count).(path)
    points, dirs, counts
end


function setupplot(#=p,d, l=#)
    #p, d, l = @lift( $makie_data ) ;
    fig, ax, hm = heatmap(matrix) ; #the backing matrix
    #scatter!(p, color=l, marker=d)
    Colorbar(fig[:, end+1], hm); #and a colourbar for reference to be fancy
    fig 
end


function A✴(s::CartesianIndex{2}, g::CartesianIndex{2})

    prev = Dict{cell_data, cell_data}() #dictionary of previous points
    s_cell = cell_data(s, 1, 1); #count 1 == 0 really (thanks Julia!)

    goalscore = [ [typemax(1) for i in 1:4, j in 1:max_c] for k in 1:bounds[1], l in 1:bounds[2] ]  #cost s -> cell
    goalscore[s][1,1] = 0 #zero cost to not move at all!

    #we need to note where we last entered each node from and now many times we'd done that exact direction 
    #movehistory = Dict{CartesianIndex{2}, Tuple{CartesianIndex{2}, UInt8}}([s=>(CartesianIndex(0,0), 0)]);

    #fscore = fill(typemax(1), bounds) #f, our heuristic estimate for s->g via cell 
    fscore = [ [typemax(1) for i in 1:4, j in 1:max_c] for k in 1:bounds[1], l in 1:bounds[2] ] 
    fscore[s][1,1] = h(s_cell) #and our best guess for s is just h at the moment 



    openset = PriorityQueue{cell_data, Int}(s_cell => fscore[s][1,1] ) #need to sort out *what* we can use as a priority queue in Julia

    #Makie
    #pth = Observable{Vector{cell_data}}([s_cell]);
    fig, ax, hm = heatmap(matrix) ; #the backing matrix 
    point(x) = Point2f(x.c[1], x.c[2])
    pts  = Observable(Point2f[point(s_cell)]) #@lift( map(point, $pth)  );
    dirs = Observable(Char[makie_markers[s_cell.dir]]) #@lift( map(x->makie_markers[x.dir], $pth) );
    counts = Observable(Int[s_cell.count]) #@lift( map(x->x.count, $pth) );
    sc = scatter!(pts, color=counts, marker=dirs, colormap=:grays, colorrange=(1,10))
    Colorbar(fig[:, end+1], hm); #and a colourbar for reference to be fancy
    Colorbar(fig[end+1, begin], sc, vertical=false);
    v = VideoStream(fig, format="mp4", framerate=60)
    #Make
    cc = 0;



    while !isempty(openset)

        #note, there's something *screwy* with the documentation for PriorityQueue - 
        # Docs claim popfirst! gives the pair K->V 
        # Julia claims popfirst! is not implemented for PriorityQueue [at least a v0.18.15] and I need to use dequeue! (which is supposed to be deprecate)
        # and only gives K not V !
        cursor = dequeue!(openset) #the highest priority (lowest "value") node
        score = fscore[cursor.c][cursor.dir, cursor.count]; 

        cc += 1;
            #Makie
            #c[] = cursor ; #update Observable for plot
            if cc % 50 == 0
                pth = reconstruct_path(prev, cursor);
                pts.val = map(point, pth);
                dirs.val = map(x->makie_markers[x.dir], pth)
                counts.val = map(x->x.count, pth);
                notify(pts); notify(dirs); notify(counts);

                recordframe!(v);
                #sleep(0.05)
            end



        cursor.c == g #=we got there!=# && begin
                                                pth = reconstruct_path(prev, cursor);
                                                pts.val = map(point, pth);
                                                dirs.val = map(x->makie_markers[x.dir], pth)
                                                counts.val = map(x->x.count, pth);
                                                notify(pts); notify(dirs); notify(counts);

                                                recordframe!(v);
                                                save("./output2.mp4", v);
                                                save("./output2.png", fig);
                                                #println("$(reconstruct_path(prev, cursor))"); 
                                                return score # the total cost! (I think fscore[cursor] == goalscore[cursor] at this point?)
                                        end 
        #hist = movehistory[cursor]
        #evaluate neighbours of cursor = which means we need to store the direction we entered cursor from and how long we'd been moving in that direction
        for i in accessible(cursor)
            di = dir_to_num[i]
            cand = cell_data(cursor.c+i, di, cursor.dir == di ? cursor.count+1 : 1)
            trialgoalscore = goalscore[cursor.c][cursor.dir, cursor.count] + matrix[cand.c];
            if trialgoalscore < goalscore[cand.c][di, cand.count]
                prev[cand] = cursor 
                goalscore[cand.c][di,cand.count] = trialgoalscore
                #movehistory[cand] = i == hist[1] ? (i, hist[2]+1) : (i, 1)  #accrue straight lines - it's okay for this to change if cand leaves and re-enters the open set
                fscore[cand.c][di,cand.count] = trialgoalscore + h(cand)
                #if haskey[openset] #update priority (which *can* change here I think!)
                #    openset cand priority = fscore[cand]
                #else 
                openset[cand] = fscore[cand.c][di,cand.count]
                #end
            end
        end
    end 

    return typemax(1)
end

println("$(A✴(CartesianIndex((1,1)), goal))");


