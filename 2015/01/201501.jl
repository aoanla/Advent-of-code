
f = read("input")

mapped = map(f) do i 
   1- ((i - 0x28) << 1) 
end

print("Pt1 = $(sum(mapped))\n")

tot = 0
for (n,i) ∈ enumerate(mapped)
    global tot += i 
    if tot == -1
        print("Pt2 = $n\n")
        break
    end
end