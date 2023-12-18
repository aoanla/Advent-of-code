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

function read_instructions(f)
    instructions = []
    rowcol = [1,1]
    c = 0
    open(f) do fd
        for l in readlines(fd)
            _, _, colour = split(l, ' ');
            dir = colour[end-1];
            l = parse(Int, "0x" * colour[begin+2:end-2])

            #0 R 1 D 2 L 3 U
            select = ( dir == '2' || dir == '0' ) ? COL : ROW   #COL now is "COLranges" stored in ROW hash
            nselect = 3 - select; #2 if 1, 1 if 2 
            step = ( dir == '3' || dir == '2' ) ? -1 : 1

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
        #print number of ranges, which we assume is 1

        #continue
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
                if i[1] > r[2] #not in range - this new range is *before* this range [and thus needs to go in the next_ranges list now]
                    push!(next_ranges, (r[1], r[2], k))
                    pushfirst!(inside_ranges, i) #pop this back onto the list for the next new candidate
                    break
                end
                if r[2] == i[1] #extends to the top - this needs to go on the *inside* ranges, with a depth of k, for any subsequent new ranges to glom
                    match = true
                    new_range = (r[1], i[2], k) 
                    insidespace += (i[2] - i[1] + 1) * (k - i[3]) #*up to* this range 

                    pushfirst!(inside_ranges, new_range);
                    break
                end
                if r[1] == i[2] #extends to the bottom  - this needs to go on the *new* ranges list, with a depth of k, for any subsequent inside ranges to glom
                            #TESTED by example
                    match = true
                    new_range = (i[1], r[2], k)
                    insidespace += (i[2] - i[1] + 1) * (k - i[3]) #*up to* this range 

                    pushfirst!(inside_ranges, new_range)
                    break
                end
                if r[1] > i[1] && r[2] < i[2] #is wholly included within  - TESTED by example 
                    match = true
                    new_range = [(i[1], r[1], k), (r[2], i[2], k)]

                    insidespace += (i[2] - i[1] + 1) * (k - i[3]) #*up to* this range - this is the Interior!
                    insidespace += (r[2] - r[1] - 1) #interior nub
                    push!(next_ranges, new_range[1]) #the top goes to next ranges because it can't match anything new
   
                    pushfirst!(inside_ranges, new_range[2]) #the bottom goes to inside_ranges because it could match another segment at the bottom
    
                    break 
                end
                if r[1] == i[1] #shrinks us from the top                    
                    match = true 
                    if r[2] == i[2] #actually caps us, just need to fiddle the range to get it okay SPECIAL CASE TESTED by example
 
                        new_range = (i[1], i[2], k)
                        insidespace += (i[2] - i[1] + 1) * (k - i[3] + 1) #*up to* this range, inc cap
                        push!(next_ranges, new_range); 
                        break
                    end
                    new_range = (r[2], i[2], k)
                    insidespace += (i[2] - i[1] +1 ) * (k - i[3] ) #*up to* this range 
                    insidespace += (r[2] - r[1] ) #top cap

                    push!(next_ranges, new_range)
                    break
                end 
                if r[2] == i[2] #shrinks us from the bottom
                    match = true
                    new_range = (i[1], r[1], k)
                    insidespace += (i[2] - i[1] + 1 ) * (k - i[3] ) #*up to* this range 
                    insidespace += (r[2] - r[1] ) #bottom cap
    
                    push!(next_ranges, new_range)
                    break
                end
                if r[1] > i[2] #we're past the end of the ranges we could match - and all subsequent new ranges will be even further past

                    push!(next_ranges, i); #so this range goes onto next_ranges
                    #pushfirst!(next_ranges)
                end
            end 

            #if our range is past all ranges in the inside_ranges, add it to the list 
            if match != true
                push!(next_ranges, (r[1], r[2], k))
                past_it = true; #and signal that everything else is as well at this point
            end
        end
        #if we get to here then only inside_ranges can have things in it (if all our new ranges were above them )
        append!(next_ranges, inside_ranges)
        inside_ranges = deepcopy(next_ranges)
    
    end #depths iter
    println("Remaining ranges: $inside_ranges")
    excess = 0
    for i in inside_ranges
        excess += i[2] - i[1] +1 
    end
    println("Potential excess = $excess")
    insidespace
end
#answer from another solution is 45757884535661 (we get about half this, despite our test example passing perfectly)

println("$(read_instructions("input"))")

