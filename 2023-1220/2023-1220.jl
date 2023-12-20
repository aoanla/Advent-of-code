#No time just a quick note that this is (even as explained) a quick state machine / cycle detection situation [as in a previous puzzle this year...]

#Build graph
#UInt64 for states [there's 58 devices!] (and thus a fast xor with the accumulated state history for cycles)
state_vector = UInt64[]

checkstates(curr_state) =  findfirst(state_vector .⊻ curr_state)

#message queue for messages

#Profit?