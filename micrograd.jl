using Graphviz_jll
using Printf
import Base: +, *, tanh

mutable struct Value
    data::Float64
    grad::Float64
    _backward::Function
    _prev::Set{Value}
    _op::String
    label::String
end


Value(x::Float64;
      grad=0.0, 
      children=Set{Value}(), 
      op="",
      label="") = Value(x, grad, () -> nothing, children, op, label)

import Base: +, *

+(a::Value, b::Value) = begin 
    out = Value(
        a.data + b.data;
        children=Set([a, b]),
        op="+"
    )
    out._backward = function ()
        a.grad += 1.0 * out.grad
        b.grad += 1.0 * out.grad
    end
    return out
end

*(a::Value, b::Value) = begin 
  out = Value(
      a.data * b.data;
      children=Set([a, b]),
      op="*"
  )
  out._backward = function ()
    a.grad += b.data * out.grad
    b.grad += a.data * out.grad
  end
  return out
end

import Base: tanh

tanh(a::Value) = begin 
    x = a.data
    t = (exp(2a.data) - 1) / (exp(2a.data) + 1)
    out = Value(
    t,
    children=Set([a]),
    op="tanh"
    )
    out._backward = function ()
        a.grad += (1 - t^2) * out.grad
    end
    return out
end

# inputs x1, x2
x1 = Value(2.0; label="x1")
x2 = Value(0.0; label="x2")

# weights w1, w2
w1 = Value(-3.0; label="w1")
w2 = Value(1.0; label="w2")

# bias
b = Value(6.8813735870195432; label="b")

# forward pass
x1w1   = x1 * w1;              x1w1.label   = "x1*w1"
x2w2   = x2 * w2;              x2w2.label   = "x2*w2"
x1w1x2w2 = x1w1 + x2w2;        x1w1x2w2.label = "x1*w1 + x2*w2"
n      = x1w1x2w2 + b;         n.label      = "n"
o      = tanh(n);              o.label      = "o"

function build!(v, nodes::Set, edges::Set)
    if !(v in nodes)
        push!(nodes, v)
        for child in v._prev
            push!(edges, (child, v))
            build!(child, nodes, edges)
        end
    end
end

function trace(root)
    nodes, edges = Set(), Set()
    build!(root, nodes, edges)
    return nodes, edges
end

function draw_dot(root)
    nodes, edges = trace(root)

    io = IOBuffer()
    println(io, "digraph G {")
    println(io, "rankdir=LR;")

    for n in nodes
        uid = string(objectid(n))
        @printf(io,
            "\"%s\" [label=\"{ %s | data %.4f | grad %.4f }\" shape=record];\n",
            uid, n.label, n.data, n.grad)

        if !isempty(n._op)
            opid = uid * n._op
            println(io, "\"$opid\" [label=\"$(n._op)\"];")
            println(io, "\"$opid\" -> \"$uid\";")
        end
    end

    for (n1, n2) in edges
        println(io, "\"$(objectid(n1))\" -> \"$(objectid(n2))$(n2._op)\";")
    end

    println(io, "}")
    return String(take!(io))
end

function draw_dot_svg(root)
    dot_src = draw_dot(root)
    cmd = pipeline(`$(Graphviz_jll.dot()) -Tsvg`, stdin=IOBuffer(dot_src))
    return read(cmd, String)
end

svg_str = draw_dot_svg(L)
display("image/svg+xml", svg_str)