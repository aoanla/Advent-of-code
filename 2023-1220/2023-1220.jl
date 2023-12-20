#No time just a quick note that this is (even as explained) a quick state machine / cycle detection situation [as in a previous puzzle this year...]

#Build graph
#The one wrinkle here is & modules need us to know how many things push into them to build their internal state vector (len = number of things that push to it)
#& modules actually have no long-term-state we care about (our long term state vector only needs to remember the % states), their state is set by receiving messages 
conj_state_pulse(conj_state) = all(conj_state) ? true : false 

#UInt64 for states [there's 58 devices!] (and thus a fast xor with the accumulated state history for cycles)
state_vector = UInt64[]

checkstates(curr_state) =  findfirst(state_vector .⊻ curr_state)

#message queue for messages

#Profit?