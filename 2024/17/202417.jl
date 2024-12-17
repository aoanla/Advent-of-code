#this is a turing machine kinda thing.
#except with most of the operations being shr s, you expect it's going to have a limited
#set of outputs 

register = [0,0,0]

instructions = []
ip = 1
output = ""

combo(op) = op < 4 ? op : register[op-3]

adv(op) = global register[1] >>= combo(op)
bxl(op) = global register[2] ⊻= op
bst(op) = global register[2] = combo(op) & 7
jnz(op) = begin
    if register[1] != 0 
        global ip = op-2  #allow for auto movement after
    end
end
bxc(op) = global register[2] ⊻= register[3]
out(op) = print("$(combo(op) & 7)")
bdv(op) = global register[2] = register[1] >> combo(op)
cdv(op) = global register[3] = register[1] >> combo(op)

decoder = Dict([0=>adv, 1=>bxl, 2=>bst, 3=>jnz, 4=>bxc, 5=>out, 6=>bdv, 7=>cdv])

function op(opcode, operand)
    decoder[opcode](operand)
    ip+=2
end


lastindex = length(instructions)

while ip < lastindex
    op(instructions[ip], instructions[ip+1])
end 


#testoutput should be: 4,6,3,5,6,3,5,2,1,0