using Graphviz_jll
using Printf
import Base: +, *, tanh

mutable struct Value
    data::Float64
    grad::Float64
    _prev::Set{Value}
    _op::String
    label::String
end

Value(x::Float64; grad=0.0, children=Set{Value}(), op="", label="") =
    Value(x, grad, children, op, label)

import Base: +, *

+(a::Value, b::Value) = Value(
    a.data + b.data;
    children=Set([a, b]),
    op="+"
)

*(a::Value, b::Value) = Value(
    a.data * b.data;
    children=Set([a, b]),
    op="*"
)

import Base: tanh

tanh(a::Value) = Value(
    (exp(2a.data) - 1) / (exp(2a.data) + 1);
    children=Set([a]),
    op="tanh"
)


a = Value(2.0, label="a")
b = Value(-3.0, label="b")
c = Value(10.0, label="c")
e = a*b; e.label = "e"
d = e + c; d.label = "d"
f = Value(-2.0, label="f")
L = d*f; L.label="L"







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