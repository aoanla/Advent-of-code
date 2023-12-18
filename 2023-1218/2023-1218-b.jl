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
rowscols = ( Dict{Int, Set{Range{Int}}}([]), Dict{Int, Set{Range{Int}}}([]) )
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
        dict[key] = Set(value)
    end
end

function read_instructions(f)
    instructions = []
    rowcol = [1,1]
    open(f) do fd
        for l in readlines(fd)
            _, _, colour = split(l, ' ');
            dist = colour[end];
            l = parse(Int, "0x" * colour[begin+1:end-1])
            #0 R 1 D 2 L 3 U
            select = ( dir == '2' || dir == '0' ) ? COL : ROW   #COL now is "COLranges" stored in ROW hash
            nselect = 3 - select; #2 if 1, 1 if 2 
            step = ( dir == '3' || dir == '2' ) ? -1 : 1

            new = rowcol[select] + step*l
            safepush!(rowscols[nselect], rowcol[nselect], step == 1 ? (rowcol[select]:new) : (new:rowcol[select]) ) 
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



    #pt1 below


    #or is it? Am I just missing the case that a cell is passed over more than once above [and so counts as not "opening" the space, just making an inclusion with width stem attaching it to the outside?]
    #.... I'm also missing the same thing from Day 10 
    #               #                                1
    #      1  #######  0    is different to  1  ##########   1
    #         #                                 #    0   #

    insidespace = 0
    for (k,v) in pairs(rowscols[ROW])
        insidesets = collect(sort(unique(v))) #pairs of walls contain "internal space"

        #insidespace += mapreduce(x->x[2]-x[1]+1, +, insidesets)
        parity = false
        lastel = length(insidesets)
        i = 1
        while i < lastel
            insidespace += 1  #an element always counts to the size
            if insidesets[i+1] == insidesets[i] + 1 #we're running along a wall // to our direction
                #need to determine if this is the end of a loop, or a jink in a vertical
                up = haskey(rowscols[ROW], k-1) && insidesets[i] ∈ rowscols[ROW][k-1] ; #is the start of our horizontal run attached to a cell above it
                while (i < lastel - 1)  && insidesets[i+1] == insidesets[i] + 1
                    i+=1
                    insidespace += 1
                end
                up2 = haskey(rowscols[ROW], k-1) && insidesets[i] ∈ rowscols[ROW][k-1];
                parity = parity ⊻ (up ⊻ up2 ) #? parity : 1 - parity #flip parity if this is *not* a loop
                insidespace += parity * (insidesets[i+1] - insidesets[i] -1)
                space[k-min_rows+1, (insidesets[i]-min_cols+1):(insidesets[i+1]-min_cols+1)] .|= parity;
            else
                parity = true ⊻ parity
                insidespace += parity * (insidesets[i+1] - insidesets[i] -1)
                space[k-min_rows+1, (insidesets[i]-min_cols+1):(insidesets[i+1]-min_cols+1)] .|= parity;
            end
            i += 1
        end
        insidespace += 1 #last element
    end

    insidespace
end

println("$(read_instructions("input2"))")

