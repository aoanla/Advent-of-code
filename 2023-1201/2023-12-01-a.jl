
#part 2
open("input") do f
    accum = 0
    n_dict = Dict("1" => 1, "2" => 2, "3" => 3, "4" => 4, "5" => 5, "6" => 6, "7" => 7, "8" => 8, "9" => 9, "one" => 1, "two" => 2, "three" => 3, "four" => 4, "five" => 5, "six" => 6, "seven" => 7, "eight" => 8, "nine" => 9)
    for line in eachline(f)
        digit = n_dict[match(r"[0-9]|one|two|three|four|five|six|seven|eight|nine", line).match]
        lastdigit = n_dict[reverse(match(r"[0-9]|eno|owt|eerht|ruof|evif|xis|neves|thgie|enin", reverse(line)).match)]
        accum += digit*10 + lastdigit
    end
    println("$accum")
end

println("DONE")