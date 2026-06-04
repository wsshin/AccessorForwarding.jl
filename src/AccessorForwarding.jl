module AccessorForwarding

export @forward

function forward_arg_name(arg)
    arg isa Symbol && return arg

    if arg isa Expr
        if arg.head == :(::)
            return arg.args[1]
        elseif arg.head == :(...)
            return forward_arg_name(arg.args[1])
        end
    end

    error("@forward expects the accessor argument to be a symbol or typed symbol.")
end

function forward_rvalue(arg)
    if arg isa Symbol
        return arg
    elseif arg isa Expr
        if arg.head == :(::)
            return arg.args[1]
        elseif arg.head == :(...)
            return Expr(:..., forward_rvalue(arg.args[1]))
        elseif arg.head == :kw
            return arg.args[1]
        end
    end

    return arg
end

function forward_replace(arg, name::Symbol, replacement)
    if arg isa Symbol
        return arg == name ? replacement : arg
    elseif arg isa Expr
        if arg.head == :(::)
            return forward_replace(arg.args[1], name, replacement)
        elseif arg.head == :(...)
            return Expr(:..., forward_replace(arg.args[1], name, replacement))
        elseif arg.head == :kw
            return Expr(:kw, arg.args[1], arg.args[2])
        else
            return Expr(arg.head, (forward_replace(a, name, replacement) for a in arg.args)...)
        end
    end

    return arg
end

function forward_signature_arg(arg, name::Symbol, replacement)
    if arg isa Symbol
        return arg == name ? replacement : arg
    elseif arg isa Expr
        if arg.head == :(::)
            arg_name = forward_arg_name(arg)

            return arg_name == name ? replacement : arg
        elseif arg.head == :(...)
            return Expr(:..., forward_signature_arg(arg.args[1], name, replacement))
        elseif arg.head == :kw
            return Expr(:kw, arg.args[1], arg.args[2])
        else
            return Expr(arg.head, (forward_signature_arg(a, name, replacement) for a in arg.args)...)
        end
    end

    return arg
end

function forward_method(accessor::Symbol, accessor_arg, call::Expr)
    call.head == :call || error("@forward block entries must be function-call signatures.")

    name = forward_arg_name(accessor_arg)
    receiver = Expr(:call, accessor, name)

    call_args = call.args[2:end]
    lhs_args = map(call_args) do arg
        forward_signature_arg(arg, name, accessor_arg)
    end
    rhs_args = map(call_args) do arg
        forward_replace(forward_rvalue(arg), name, receiver)
    end

    lhs = Expr(:call, call.args[1], lhs_args...)
    rhs = Expr(:call, call.args[1], rhs_args...)

    return Expr(:(=), lhs, rhs)
end

"""
    @forward accessor(arg::WrapperType) begin
        f(arg)
        g(x, arg, y)
    end

Define forwarding methods that replace `arg` with `accessor(arg)` in the method body.
The macro is intended for one-line wrapper methods only.

The example above generates

```julia
f(arg::WrapperType) = f(accessor(arg))
g(x, arg::WrapperType, y) = g(x, accessor(arg), y)
```
"""
macro forward(accessor_call, block)
    accessor_call isa Expr && accessor_call.head == :call ||
        error("@forward expects an accessor call, e.g. inner(x::WrapperType).")

    length(accessor_call.args) == 2 ||
        error("@forward accessor call must have exactly one argument.")

    accessor = accessor_call.args[1]
    accessor isa Symbol ||
        error("@forward accessor must be a function name.")

    accessor_arg = accessor_call.args[2]
    body = block isa Expr && block.head == :block ? block.args : [block]
    methods = Expr[]

    for item in body
        item isa LineNumberNode && continue
        push!(methods, forward_method(accessor, accessor_arg, item))
    end

    return esc(Expr(:block, methods...))
end

end
