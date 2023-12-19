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

#checks - are we parsing the whole file (we are)

function validate_range(r)
    r[1]<r[2] && return true
    println("INVALID RANGE: $r")
    exit()
end

function read_instructions(f)
    rowcol = [1,1]
    c = 0
    open(f) do fd
        last_col_step = 0; #we'll need to fix the "overlap on the last -> first"  at the end
        first = true
        first_col_step = 0
        last_row_step = 0;
        last_row_size = 0;
        first_row = 1 #first row position actually *is* 1
        last_row = 1 #fixed up by loop
        for l in readlines(fd)
            _, _, colour = split(l, ' ');
            dir = colour[end-1];
            l = parse(Int, "0x" * colour[begin+2:end-2])
            #0 R 1 D 2 L 3 U
            select = ( dir == '2' || dir == '0' )    #COL now is "COLranges" stored in ROW hash
            nselect = !select; #2 if 1, 1 if 2 
            step = ( dir == '3' || dir == '2' ) ? -1 : 1
            if first && select
                first_col_step = step #grab this for sorting out at the end
                first = false
            end
#we need an ordered list of oriented rects to sort out the double counting at borders where both rects have same sign, so just do it here

            new = rowcol[select] + step*l
            safepush!(rowscols[nselect], rowcol[nselect], step == 1 ? (rowcol[select],new) : (new,rowcol[select]) ) 
            rowcol[select] = new
            c += 1
        end
    end
    println("Total input size = $c")
    depths = sort(collect(keys(rowscols[ROW])));

    insidespace = 0
    inside_ranges = Tuple{Int, Int, Int}[]
    for k in depths
        new_ranges = collect(sort(unique(rowscols[ROW][k]))) #pairs of walls contain "internal space"
        next_ranges = Tuple{Int, Int, Int}[]
        past_it = false
        while !isempty(new_ranges)
            if past_it == true
                #glom the rest of new_ranges onto the end of next_ranges
                for n in new_ranges
                    push!(next_ranges, (n[1], n[2], k))
                end
                break
            end
            r = popfirst!(new_ranges)
            match = false
            while !isempty(inside_ranges)
                i = popfirst!(inside_ranges)
                #are these all the possible cases, exhaustively? YES - rs cannot contain is due to ordering and connected path

                if i[1] > r[2] #not in range - r is before i [so must be before all other is too, as is are sorted]
                    match=true #because we were consumed
                    push!(next_ranges, (r[1], r[2], k))
                    pushfirst!(inside_ranges, i) #pop this back onto the list for the next new candidate
                    break
                end
                if r[1] == i[2] #extends to the bottom  - this needs to go on the *new* ranges list, with a depth of k, for any subsequent inside ranges to glom
                    #TESTED by example  ??
                    match = true
                    new_range = (i[1], r[2])
                    validate_range(new_range)
                    insidespace += (i[2] - i[1] + 1) * (k - i[3]) #*up to* this range  is this a good calc if we're throwing back into new_ranges?
                    pushfirst!(new_ranges, new_range)
                    #pushfirst!(_ranges, new_range)
                break
                end

                if r[2] == i[2] #shrinks us from the bottom
                    match = true
                    if r[1] == i[1] #actually caps us, just need to fiddle the range to get it okay SPECIAL CASE TESTED by example
                        new_range = (i[1], i[2], k)
                        insidespace += (i[2] - i[1] + 1) * (k - i[3] + 1) #*up to* this range, inc cap, as we're removing this range entirely
                        #push!(next_ranges, new_range); #remove entirely
                        break
                    end
                    new_range = (i[1], r[1], k)
                    validate_range(new_range)
                    insidespace += (i[2] - i[1] + 1 ) * (k - i[3] ) #*up to* this range 
                    insidespace += (r[2] - r[1] ) #bottom cap
                    push!(next_ranges, new_range)
                    break
                end
                if r[1] > i[1] && r[2] < i[2] #is wholly included within  - TESTED by example 
                    match = true
                    new_range = [(i[1], r[1], k), (r[2], i[2], k)]
                    for r in new_range
                        validate_range(new_range)
                    end
                    insidespace += (i[2] - i[1] + 1) * (k - i[3]) #*up to* this range - this is the Interior!
                    insidespace += (r[2] - r[1] - 1) #interior nub
                    push!(next_ranges, new_range[1]) #the top goes to next ranges because it can't match anything new
   
                    pushfirst!(inside_ranges, new_range[2]) #the bottom goes to inside_ranges because it could match another segment at the bottom
    
                    break 
                end
                if r[1] == i[1] #shrinks us from the top                    
                    match = true 
                    new_range = (r[2], i[2], k)
                    validate_range(new_range)
                    insidespace += (i[2] - i[1] +1 ) * (k - i[3] ) #*up to* this range 
                    insidespace += (r[2] - r[1] ) #top cap

                    pushfirst!(inside_ranges, new_range)
                    break
                end 
                if r[2] == i[1] #extends to the top - this needs to go on the *inside* ranges, with a depth of k, for any subsequent new ranges to glom
                    match = true
                    new_range = (r[1], i[2], k) 
                    insidespace += (i[2] - i[1] + 1) * (k - i[3]) #*up to* this range 
                    validate_range(new_range)
                    pushfirst!(inside_ranges, new_range);
                    break
                end
                if r[1] > i[2] #we're past the end of the ranges we could match - and all subsequent new ranges will be even further past ??????                    println("7")
                    push!(next_ranges, i); #so this range goes onto next_ranges
                end
            end 

            #if our range is past all ranges in the inside_ranges, add it to the list  ARG, this triggers on leaving 1 
            if match != true
                push!(next_ranges, (r[1], r[2], k))
                past_it = true; #and signal that everything else is as well at this point
            end
        end
        #if we get to here then only inside_ranges can have things in it (if all our new ranges were above them )
        append!(next_ranges, inside_ranges)
        inside_ranges = deepcopy(next_ranges)
    
    end #depths iter

    insidespace
end
#answer from another solution is 45757884535661 

println("$(read_instructions("input"))")

