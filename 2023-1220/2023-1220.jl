#=Pt 2 analysis:

Node rf is written by node &pt (which is a conjugator - essentially a NAND with more than 2 inputs), and also broadcast (which sets it high initally to start us off)
Node pt has inputs dj, fl, rf(! - so once rf fires it unsets pt), sk, sd, mv
So, we need to determine when dj, fl, sk, sd, mv are all low simultaneously.
One imagines that this is another LCM problem, tracking the states of dj, fl, sk, sd, mv and finding their cyclic periods?

=#


#No time just a quick note that this is (even as explained) a quick state machine / cycle detection situation [as in a previous puzzle this year...]

#Build graph
#The one wrinkle here is & modules need us to know how many things push into them to build their internal state vector (len = number of things that push to it)
#& modules have a lot of state (1 bit per input), so they'll need a mask of more than 1 zero.

#UInt128 for states [there's 58 devices, but a lot of conjugators so we actually need more than 80 bits... ]
state_vector = ~UInt128(0) #set "low" everywhere == true because Erik wants to mess with us and have inverters on "low" not "high" bits

low_pulse = ~UInt128(0) 
high_pulse = UInt128(0)

checkstates(curr_state) =  findfirst(==(0), state_vector .⊻ curr_state)

#message queue for messages

#Profit?

@enum NodeType::UInt8 begin
    flipflop
    conjunction
    broadcast
end

nodes_out = Dict{String, Vector{String}}()
nodes_in = Dict{String, Vector{String}}()
node_types = Dict{String, NodeType}()
dest_src_mask = Dict{String, Dict{String, UInt128}}()
masks = Dict{String, UInt128}()

function parse_input!(ff)
    open(ff) do fd
        for line in readlines(ff)
            n, ns = split(line, " -> ")
            n_head, n_tail = n[begin], n[begin+1:end]
            node_t = n_head ==  '%' ? flipflop : 
                     n_head ==  '&' ? conjunction : broadcast 
            node_types[n_tail] = node_t 
            nodes_out[n_tail] = split(ns, ", ")
            for nn in nodes_out[n_tail]
                if !haskey(nodes_in, nn)
                    nodes_in[nn] = []
                end
                push!(nodes_in[nn], n_tail) #important for state vector
            end
            if node_t == conjunction #set here so logic in masks can know to treat these existing entries specially
                dest_src_mask[n_tail]=Dict{String,UInt128}()
            end
        end    
    end

end

#sort out masks 
function masks!() 
    #for anything but a conjugator, dest_src_mask maps [dest][src] to the same state mask. for conj [dest][src] maps each src to a separate bit in src's mask
    offset = UInt128(0x0000000000000001) #start at 1
    for n in keys(nodes_in)
        mask = UInt128(0) | offset 
        if haskey(dest_src_mask, n) 
            for i in values(nodes_in[n])
                mask |= offset
                dest_src_mask[n][i] = offset;
                offset <<= 1    
            end
            masks[n] = mask
            continue
        end
        #not a conjugator so we need to make it an entry that's identical for all srcs 
        dest_src_mask[n] = Dict{String, UInt128}() 
        for i in values(nodes_in[n])
            dest_src_mask[n][i] = mask;  
        end
        masks[n] = mask 
        offset <<= 1

    end
    masks

end


get_state(n) = state_vector & masks[n]
pulses = [0,0] #high, low

queue = []


function pulse!(src, srcsrc, low)

    bit = dest_src_mask[src][srcsrc] & low

    !haskey(nodes_out, src) && return #if this node just isn't connected to anything, it can't send anything!

    if node_types[src] == flipflop
    #flipflop - we've picked "low" to be "true" so state xor low flips appropriately [low is actually "all 1s"]
    #yes, this means "off" = "true" in the mask as well, and "on" = false
        state = get_state(src)
        new = bit ⊻ state
        if new != state
            global state_vector ⊻= masks[src] #flip the bit here too
            push!(queue, (src, state == high_pulse #=old state, new state is opposite!=# ? low_pulse : high_pulse)) 
            #return  (src, state == high_pulse #=old state, new state is opposite!=# ? low_pulse : high_pulse)
            
        end 
        return 
    end
    #conj 
    #set just this bit from the mask... mask
                    #zero the bit                       #and or it with the new value
    global state_vector =  (state_vector & ~dest_src_mask[src][srcsrc]) | bit 
    #low is true, so "all high" here is == 0
    push!(queue,  get_state(src) == 0 ? (src, low_pulse) #="low"=# : (src, high_pulse) #="high"=#);
end 


function send_pulse!(source_low)
    source, low = source_low
    #make ourselves a new queue of things to process *once this is done*
    #queue = []

    for dest in nodes_out[source]
  
        pulses[low == 0 ? 1 : 2 ] += 1
        out = pulse!(dest, source, low)
        #queue up the messages that result
        #!isnothing(out) && push!(queue, out)
    end
    
    #queue
end



parse_input!("input")
println("$nodes_in")
println("")
println("$nodes_out")

masks!()

stopall = false
function push_the_button!()
    pulses[2] += 1 ; #the button pulse itself
    push!(queue, ("roadcaster", low_pulse))
    epoch = 1
    while !isempty(queue) 
        msg = popfirst!(queue)
        
        send_pulse!(msg)
        ##append!(qq, send_pulse!(msg))
        #queue = qq
        #println("Queue epoch $epoch, queue length $(length(queue))")
        epoch += 1

    end
end 



old_vector = [UInt128(0)];

counter = 1
while isnothing(findfirst(==(UInt128(0)), old_vector .⊻ state_vector)) && counter < 1002
    
    push!(old_vector, state_vector) 
    push_the_button!()
    #println("$(bitstring(state_vector))")
    #println("$pulses")
    if counter > 990
        println("Counter $counter $(pulses)  $(prod(pulses))")
    end
    if stopall == true
        break
    end
    global counter += 1
end

#pt 1 (after making my state vector 128bits to hold all the state!)