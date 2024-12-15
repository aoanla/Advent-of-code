#the trick here is that we need to efficiently determine if a barrel is "fixed" along an axis [because it impinges on a wall] or not
#we can do this by propagating fixedness from walls and having efficient updates on them as they update.


#a Cell can be fixed, hypothetically from *both* sides if there's a line of them between 2 walls 
struct Cell
    obs::Bool #is an obstruction
    wall::Bool 
    fixed_axes::Tuple{Bool,Bool}
    fixed_from::Set{Tuple{Int8,Int8}} #can be fixed in multiple directions
    fixing_in::Set{Tuple{Int8,Int8}}   #so we can unstick cells to the other side of it when it moves
end 

function move(loc, dir)
    candidate = loc .+ dir
    cand_cell = grid[candidate...]
    cand_cell.obs || return candidate #unblocked cell easy
    cand_cell.fixed_axes .* dir == (0,0) && return loc #blocked cell, fixed in this dir 
    #now we deal with the unfixed axis 

    #unfix Cells this Cell fixes 
    foreach(cand_cell.fixing_in) do cc
        setdiff!(cc.fixed_from, candidate) #remove candidate 
        #unfix if necessary - hm, this is not as easy using 1 set for all fixed_from dirs. Bitstring would be better...
    end

    #"delete" and move cell
    grid[candidate...]... 
    grid[(candidate.+dir)...] = 


end

#hm is it easier just to propagate attempted moves?