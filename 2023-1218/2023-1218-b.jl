#Part B where we store ranges in rows and cols and have to intersect them

#using Pkg
#Pkg.activate(".")
#using Images, ImageView, Gtk4, Colors

#Probably should use some sparse data structures to hold this
# row and column dicts containing a stack of the elements in each of them?

#(yes, I know I could just use SparseArrays but lets try it ourselves first)

#we always start with a single filled element, we'll call that 1,1
#the vector of ints is the column indices for all filled elements in a given row
            #    rows dict with set of col ranges          cols dict with set of row ranges
rowscols = ( Dict{Int, Set{Tuple{Int,Int}}}([]), Dict{Int, Set{Tuple{Int,Int}}}([]) )
#same here, for row indices in the vector for a given col
#cols = Dict{Int, Vector{Int}}([ 1=>[1]])

ROW = 1
COL = 2

function safepush!(dict, key, value)
    if haskey(dict, key)
        if value ∈ dict[key] #trying some fancy ordering to "remove" cells we pass over more than once to help our interior detecting raycaster not the problem
            delete!(dict[key], value)
        else
            push!(dict[key], value)
        end
    else
        dict[key] = Set([value])
    end
end

function read_instructions(f)
    instructions = []
    rowcol = [1,1]
    open(f) do fd
        for l in readlines(fd)
            _, _, colour = split(l, ' ');
            dir = colour[end-1];
            l = parse(Int, "0x" * colour[begin+2:end-2])
            println("$dir $l $colour")
            #0 R 1 D 2 L 3 U
            select = ( dir == '2' || dir == '0' ) ? COL : ROW   #COL now is "COLranges" stored in ROW hash
            nselect = 3 - select; #2 if 1, 1 if 2 
            step = ( dir == '3' || dir == '2' ) ? -1 : 1

            new = rowcol[select] + step*l
            safepush!(rowscols[nselect], rowcol[nselect], (rowcol[select], new) ) 
            rowcol[select] = new
        end
    end

    #raycasting, lets just pick rows to do this over

    #PT2 note - this is now going to be raycasting through ranges.
    #trick will be:

    #colrange @ row - add width, determine interior parity by rowranges that start and end at the col limits 
    #rowranges @ cols - determine which rowranges we intersect (ordered by cols) to do parity

    #... this is easier than that because you can just ignore the colranges by row [as the rowranges by cols all have them as limits]
    # in which case this is just adding oriented areas of rectangles from each range
    min_k = minimum(collect(keys(rowscols[ROW])));
    insidespace = 0
    error = 0
    for (k,v) in rowscols[ROW]
        for vv in collect(unique(v))
            dist = vv[1]-vv[2]
            oriented_area = (k ) * (dist); #pick a direction as positive, I think we go down first on the outside so...
            error += (k) * sign(vv[1]-vv[2]) 
            insidespace += oriented_area;
        end
    end
    println("$error")
    insidespace - 952408144115


    
end

println("$(read_instructions("input2"))")

