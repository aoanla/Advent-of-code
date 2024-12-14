using LinearAlgebra
using Base.Iterators 
#this is just matrix maths - the parsing is harder than the problem for pt1

# no soln if det(A) == 0, else soln = A⁻¹B and sum is soln⋅cost 

struct problem
    A::Matrix{Rational{Int64}}
    B::Vector{Rational{Int64}}
end

const cost = (3,1)

#rational matrix inverse 
function rat_matinv(A::Matrix{Rational{Int64}})
    det = A[1,1]*A[2,2] - A[1,2]*A[2,1]
    cofactors = [A[2,2] -A[1,2] ; -A[2,1] A[1,1]] #transposed matrix of cofactors 
    cofactors .// det 
end 


function value(problem::problem)
    if det(problem.A) == 0
        #print("No solution: $problem\n")
        0
    else 
        #print("Solving: $problem\n")
        candidate = rat_matinv(problem.A)*problem.B
        if isinteger.(candidate) == [true ; true]
            #print("\tInteger solns, accepted: $candidate\n")
            candidate⋅cost
        else
            #print("\tNon-integral solns, rejected: $candidate\n")
            0
        end
    end
end

const button = r"X([+-]\d+), Y([+-]\d+)"
const prize = r"X=([-]?\d+), Y=([-]?\d+)"

function parse_problem(input)
    (a,b,p) = input[1:3]
    bA = match(button, a).captures
    bB = match(button, b).captures
    bp = parse.(Int64,match(prize, p).captures)
    A = parse.(Int64, [ bA ;; bB ])  
    problem(A, bp)
end

problems = partition(readlines("input"), 4) |> Base.Fix1(map, parse_problem)

pt1 = mapreduce(value,.+, problems)

print("Pt1: $pt1\n")

problems2 = map(problems) do prob 
    problem(prob.A, prob.B .+ 10000000000000)
end


pt2 = mapreduce(value,.+, problems2)

print("Pt2: $pt2\n")

#the question is, does the \ operator, which I was just reminded of, solve this correctly? (It should be faster if it does.)

function value_bs(problem::problem)
    if det(problem.A) == 0
        #print("No solution: $problem\n")
        0
    else 
        #print("Solving: $problem\n")
        candidate = problem.A\problem.B
        if isinteger.(candidate) == [true ; true]
            #print("\tInteger solns, accepted: $candidate\n")
            candidate⋅cost
        else
            #print("\tNon-integral solns, rejected: $candidate\n")
            0
        end
    end
end

pt2_bs = mapreduce(value_bs,.+, problems2)

print("Pt2bs: $pt2_bs\n")

##It does!