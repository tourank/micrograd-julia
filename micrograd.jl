using CairoMakie
import Base: +, *

f(x) = 3x^2 - 4x + 5

println(f(3.0))

# Sample some points
xs = -5:0.25:5
ys = f.(xs)

# Plot the function
lines(xs, ys)

mutable struct Value
    data::Float64
end

+(a::Value, b::Value) = Value(a.data + b.data)
*(a::Value, b::Value) = Value(a.data * b.data)

a = Value(2.0)
b = Value(-3.0)
c = Value(10.0)
d = a*b + c