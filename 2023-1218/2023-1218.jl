#using Pkg
#Pkg.activate(".")
#using Images, ImageView, Gtk4, Colors

#Probably should use some sparse data structures to hold this
# row and column dicts containing a stack of the elements in each of them?

#(yes, I know I could just use SparseArrays but lets try it ourselves first)

#we always start with a single filled element, we'll call that 1,1
#the vector of ints is the column indices for all filled elements in a given row
            #    rows dict with set of cols          cols dict with set of rows
rowscols = ( Dict{Int, Set{Int}}([ 1=>Set(1)]), Dict{Int, Set{Int}}([ 1=>Set(1)]) )
#same here, for row indices in the vector for a given col
#cols = Dict{Int, Vector{Int}}([ 1=>[1]])

ROW = 1
COL = 2

#=
function image_and_wait(img)
    guidict = imshow(img);
    #If we are not in a REPL
    if (!isinteractive())
        # Create a condition object
        c = Condition()

        # Get the window
        win = guidict["gui"]["window"]
    
        # Start the GLib main loop
        @async Gtk4.GLib.glib_main()

        # Notify the condition object when the window closes
        signal_connect(win, :close_request) do widget
            notify(c)
        end
        # Wait for the notification before proceeding ...
        wait(c)
    end
end

=#


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
            dir, n, colour = split(l, ' ');
            dist = parse(Int, n);
            select = ( dir == "L" || dir == "R" ) ? COL : ROW
            nselect = 3 - select; #2 if 1, 1 if 2 
            step = ( dir == "U" || dir == "L" ) ? -1 : 1

            for i in 1:dist
                rowcol[select] += step
                #update new entries, dict side first
                safepush!(rowscols[select], rowcol[select], rowcol[nselect])
                safepush!(rowscols[nselect], rowcol[nselect], rowcol[select])
            end
        end
    end

    #visualisation 
    s_rows = sort(collect(keys(rowscols[ROW])))
    max_rows = maximum(s_rows)
    min_rows = minimum(s_rows)
    range_rows = max_rows - min_rows + 1; 
    s_cols = sort(collect(keys(rowscols[COL])))
    max_cols = maximum(s_cols)
    min_cols = minimum(s_cols)
    range_cols = max_cols - min_cols + 1; 
    space = falses(range_rows,range_cols);
    for (k,v) in pairs(rowscols[ROW])
        for i in unique(v)
            space[k-min_rows+1, i-min_cols+1] = true
        end
    end

    #image_and_wait(Gray.(space) )

    

    #raycasting, lets just pick rows to do this over
    
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
    #image_and_wait(Gray.(space) )
    println("$(count(space))")
    insidespace
end

println("$(read_instructions("input3"))")

