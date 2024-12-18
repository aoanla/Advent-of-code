#this is a turing machine kinda thing.
#except with most of the operations being shr s, you expect it's going to have a limited
#set of outputs 

#ip = item 4
register::Vector{Int128} = [729,0,0, 1]

instructions = [0,1,5,4,3,0]


input = readlines("input")
for i ∈ 1:3
    register[i] = parse(Int128, input[i][12:end])
end
instructions = parse.(Int, split(input[5][9:end], ','))

print("Initial state:\n Registers: $register\nProgram: $instructions\n")

combo(op, reg) = op < 4 ? op : reg[op-3]

adv(op, reg) = reg[1] >>= combo(op, reg)
bxl(op, reg) = reg[2] ⊻= op
bst(op, reg) = reg[2] = combo(op, reg) & 7
jnz(op, reg) = begin
    if reg[1] != 0 
        reg[4] = op-1  #allow for auto movement after; this is "op-2" but plus 1 because Julia indexes at 1 not 0
    end
end
bxc(_, reg) = reg[2] ⊻= reg[3]
out(op, reg) = print("$(combo(op, reg) & 7),")
bdv(op, reg) = global reg[2] = reg[1] >> combo(op, reg)
cdv(op, reg) = global reg[3] = reg[1] >> combo(op, reg)

decoder = Dict([0=>adv, 1=>bxl, 2=>bst, 3=>jnz, 4=>bxc, 5=>out, 6=>bdv, 7=>cdv])

function op(opcode, operand, reg)
    decoder[opcode](operand, reg)
    reg[4]+=2
end


function runtape(instructions, register)
    lastindex = length(instructions)
    while register[4] < lastindex
        op(instructions[register[4]], instructions[register[4]+1], register)
    end 
    print("\n")
end

runtape(instructions, register)

#testoutput should be: 4,6,3,5,6,3,5,2,1,0

#Pt2 

#so, this is a turing machine in a turing machine - and this explains all those "hidden" shift-rights 
# we're reading parts of A each loop - so we need to work out what math is done to the part of A we read each time to work out how to encode the 
# sequence in it. The output sequence is 16 digits => 16*3 = at least 48 bits needed in A, assuming only shifts right by a max of 3

#okay so this loop (and all loops like it) establishes a recurrence relation between sets of triple bits in A 
# we can resolve this starting from the far end (because the recurrence is between the current and *higher* bits, and there are no higher bits for the far end)
# and then repeatedly unpick 

function decode(instructions) 
    value = 0
    for nibble ∈ reverse(instructions)

        tmp = ( nibble ⊻ (value >> B) ) & 7 #the issue here is knowing the value of B here so we do need to actually run the code backwards
        value <<= 3
        value += tmp
    end
    value
end 

value = decode(instructions)

print("Result: $value\n")
#test 
print("Test:")
runtape(instructions, [value, 0, 0, 1])
