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

function op(opcode, operand, reg, decoder)
    decoder[opcode](operand, reg)
    reg[4]+=2
end


function runtape(instructions, register, decoder)
    lastindex = length(instructions)
    while register[4] < lastindex
        op(instructions[register[4]], instructions[register[4]+1], register, decoder)
    end 
end

runtape(instructions, register, decoder)
print("\n")

#testoutput should be: 4,6,3,5,6,3,5,2,1,0

#Pt2 

#so, this is a turing machine in a turing machine - and this explains all those "hidden" shift-rights 
# we're reading parts of A each loop - so we need to work out what math is done to the part of A we read each time to work out how to encode the 
# sequence in it. The output sequence is 16 digits => 16*3 = at least 48 bits needed in A, assuming only shifts right by a max of 3

#okay so this loop (and all loops like it) establishes a recurrence relation between sets of triple bits in A 
# we can resolve this starting from the far end (because the recurrence is between the current and *higher* bits, and there are no higher bits for the far end)
# and then repeatedly unpick 
# we do need to backtrack if we find ourselves out of options though... 

null(_, _) = nothing 
out2(op, reg) = reg[5] = combo(op, reg) & 7
decoder2 = Dict([0=>adv, 1=>bxl, 2=>bst, 3=>null, 4=>bxc, 5=>out2, 6=>bdv, 7=>cdv])


function decode2(instructions)
    value = 0
    idx = length(instructions) #final index
    mini = 1 #to start with, as we can't have a non-zero terminal value
    flag = false 
    while idx > 0
        value <<= 3
        nibble = instructions[idx]
        i = mini  
        #min i = last one we tried+1 (we which can get from value)
        while i < 8   #
            reg = [value+i, 0, 0, 1, 0]
            runtape(instructions, reg, decoder2)
            nibble == reg[5] && break 
            #nibble == i ⊻ ( (value + i) >> (i⊻4)) & 7  && break  #a general solution would parse the specifics of the instruction code to get this test
            i += 1 
        end 
        if i == 8 
            print("failed to find solution for position $idx, backtracking\n")
            mini = 8
            while mini == 8 #reverse course until we have a value we haven't exhausted options for 
                value >>= 3
                idx += 1
                mini = value & 7 + 1
            end
            print("\ttrying: min i=$mini at $idx \n")
            value >>= 3 #this one undoes the shift at the start
            continue 
        end  #at this point we need to backtrack and try a higher i        
        print("Success at $idx with value $i\n")
        value += i
        idx -= 1
        mini = 0
    end
    value
end

value = decode2(instructions)

print("Result: $value (high nibble = $(value >> 45)\n")
#test 
print("Test:")
runtape(instructions, [value, 0, 0, 1], decoder)
print("\n")
