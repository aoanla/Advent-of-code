
file = readlines("input")
#preprocessing needed for pt2, also easier if all one line
oneline = "do()"*reduce(*,file)

pt1 = mapreduce(+, eachmatch(r"mul\(([1-9][0-9]?[0-9]?),([1-9][0-9]?[0-9]?)\)", oneline)) do m
        parse(Int,m[1])*parse(Int,m[2])
end

print("pt1 = $pt1\n")

#we could also do two eachmatches - one for sequences which have a do() and a don't() bracket them
# and then the pt1 eachmatch over each of those 
# we'd need to prepend a do() to the start of the string...
#this is less stateful and doesn't need the global, so I guess "cleaner"?
pt2 = mapreduce(+, eachmatch(r"do\(\).*?don't\(\)|do\(\).*?$", oneline)) do dodont 
        mapreduce(+, eachmatch(r"mul\(([1-9][0-9]?[0-9]?),([1-9][0-9]?[0-9]?)\)", dodont.match)) do m
            parse(Int,m[1])*parse(Int,m[2])
    end
end


print("pt2: $pt2 \n")