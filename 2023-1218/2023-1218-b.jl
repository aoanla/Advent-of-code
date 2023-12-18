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
    rowcol = [1,1]
    accum = 0
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
            #println("$dir $l $colour")
            #0 R 1 D 2 L 3 U
            select = ( dir == '2' || dir == '0' )    #COL now is "COLranges" stored in ROW hash
            nselect = !select; #2 if 1, 1 if 2 
            step = ( dir == '3' || dir == '2' ) ? -1 : 1
            if first && select
                first_col_step = step #grab this for sorting out at the end
                first = false
            end
#we need an ordered list of oriented rects to sort out the double counting at borders where both rects have same sign, so just do it here


            #if this is going to ROW, then add its signed area
            #println("$select")
            if select == true                              #0 if step positive, -1 if negative  # width of range *exclusive of end point (at far end)*
                    accum -= (rowcol[nselect+1] -           (1+step)÷2)                *   (step*(l)) #difference, removing off-by-one
                    #it's actually problematic to have inclusive ranges because correcting for overlap is super hard for positive segments 
                    if step == last_col_step #if we are adjacent to another span with same sign, correct the overlap
                        println("$step == $last_col_step , rowstep is $last_row_step")
                        #if step is +ve  and row_step is +ve then we've oversubtracted by row_size
                        if step > 0 && last_row_step > 0 
                        #println("overlap $(last_row_step * step)")
                            println("1")
                            #accum -= last_row_size;
                            #if step is -ve and row_step is -ve then all is well
                            #if step is +ve and row_step is +ve then all is well 
                            #if step is -ve and row_step is -ve then we undercounted by row_size
                        elseif step < 0 && last_row_step < 0
                            println("2")
                            accum += last_row_size
                        end
                    else #step and last step are different
                        #curr step is -ve (last step was +ve) and row_step is +ve then we've over counted by (rowcol[nselect+1] - last_row_size)!
                        if step < 0 && last_row_step > 0
                            println("3")

                            #accum -= +last_row_size #(rowcol[nselect+1]- last_row_size )
                            #curr step is +ve (last step was -ve) and row_step is -ve then, we've undercounted by last_row_size ?
                        elseif step > 0 && last_row_step < 0
                            println("4")

                            accum += last_row_size  #?
                        end
                        #curr step is -ve (last step was +ve) and row_step is -ve then ... is this okay? Is this possible if we wind anticlockwise?
                        #curr step is +ve (last step was -ve) and row_step is +ve then ... is this okay? Is this possible if we wind anticlockwise?

                        #if last_col_step != last_row_step #winding involution causes us to miscount a row here
                        #println("Winding involution")
                        #accum += last_row_size - 1 ; 
                    end
                    last_col_step = step  
            else #ROW 
                #println("ROW")
                last_row_step = step;
                last_row_size = l;
            end
            #safepush!(rowscols[nselect], rowcol[nselect], (rowcol[select], new) ) 
            rowcol[select+1] += step*l
        end
            #fixup the last col span loop to the first 
        println("$(last_row_step)");
        #for our data, this doesn't trigger
        if first_col_step == last_col_step 

            accum += 1 - rowcol[1]
        end 
        accum += last_row_size +1;
    end

    #PT2 note - this is now going to be raycasting through ranges.
    #trick will be:

    #colrange @ row - add width, determine interior parity by rowranges that start and end at the col limits 
    #rowranges @ cols - determine which rowranges we intersect (ordered by cols) to do parity

    #... this is easier than that because you can just ignore the colranges by row [as the rowranges by cols all have them as limits]
    # in which case this is just adding oriented areas of rectangles from each range

    accum 


    
end

println("$(read_instructions("input2"))")
println("952408144115")
