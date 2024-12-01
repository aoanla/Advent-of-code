using DelimitedFiles

file = readdlm("input")

l = sort(file[:,1])
r = sort(file[:,2])

res = sum(abs.(l .- r))

print("Pt 1: $res\n")

d = Dict(Float64 => Int32)

function matchiter(l,r)
    oldi = -1
    count = 0 #counting *ls*
    li,nxt = iterate(l)
    brk = false
    tot = 0
    for ri ∈ r
        #this can only happen if we already found a suitable candidate
        if ri == oldi
            tot+=oldi*count
            continue
        end
        count = 0
        #skip forward until match or past
        while ri > li
            state = iterate(l,nxt)
            if isnothing(state)
                brk = true
                break
            end
            li, nxt = state
        end
        brk && break
        #count up all the identical elements in l (because our total contribution is count(ls)*count(rs)*val)
        while ri == li
            count += 1
            state = iterate(l,nxt)
            if isnothing(state)
                brk=true
                break
            end
            li, nxt = state
        end
        oldi = ri
        tot += oldi * count
        brk && break #out of ls
    end
    tot
end

print("Pt 2: $(matchiter(l,r))\n")