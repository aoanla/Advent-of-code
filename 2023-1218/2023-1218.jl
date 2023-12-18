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
    #raycasting, lets just pick rows to do this over
    
    
    #not sufficient = we need the hull [the path can include interior elements that are "pinched off"]
    #or is it? Am I just missing the case that a cell is passed over more than once above [and so counts as not "opening" the space, just making an inclusion with width stem attaching it to the outside?]
    insidespace = 0
#=
    ordered_rows = sort(keys(rowscols[ROW])); #to do this properly we need to scan in order down the rows and update our "interior" ranges 

    #initial ranges of "interior" are the ranges of consecutive tiles 
    ranges = Tuple{Int, Int}[]
    ordered_cols =  sort(unique(rowscols[ROW][ordered_rows[1]])) #the ordered set of columns
    i = 1
    #list of ranges for the start
    while i < length(ordered_cols)
        #get range of consecutives
        rstart = ordered_cols[i]
        while (i < length(ordered_cols) ) && (ordered_cols[i+1] == ordered_cols[i] + 1) #are we going to miss the final cell here?
            i++
        end
        push!(ranges, (rstart, ordered_cols[i]))
    end
    
    function sumranges(r)
        mapreduce(x->x[2]-x[1]+1, +, r)
    end

    insidespace += sumranges(ranges); #add the top row to our interior space 

    #iterate down, adjusting the ranges to what we encounter next (verts extending a range down 1 are fine, but we could have horz shrink or grow a range)
    for k in ordered_rows[2:end]
        #new ranges
        ordered_cols =  sort(unique(rowscols[ROW][k])) #the ordered set of columns
        # ranges list is *sorted* which helps [and we've written range coalescence code in an early Day...]

        #and reduce to update insidespace
        insidespace += sumranges(ranges)
    end
    =#


        #old from here
    for (k,v) in pairs(rowscols[ROW])
        insidesets = collect(sort(unique(v))) #pairs of walls contain "internal space"

        #insidespace += mapreduce(x->x[2]-x[1]+1, +, insidesets)
        parity = 0
        lastel = length(insidesets)
        for i in eachindex(insidesets)
            insidespace += 1
            if i == lastel
                break;
            end
            if insidesets[i+1] == insidesets[i] + 1 #we're running along a wall // to our direction
                continue;
            else
                parity = 1 - parity
                insidespace += parity * (insidesets[i+1] - insidesets[i] - 1)
            end
        end
    end

    insidespace
end

println("$(read_instructions("input"))")

