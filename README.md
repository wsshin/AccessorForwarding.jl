# AccessorForwarding

[![Build Status](https://github.com/wsshin/AccessorForwarding.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/wsshin/AccessorForwarding.jl/actions/workflows/CI.yml?query=branch%3Amain)

AccessorForwarding provides `@forward`, a small macro for defining wrapper methods that
forward selected arguments through accessor functions.

```julia
using AccessorForwarding

struct Wrapper{T}
    value::T
end

wrapped_value(w::Wrapper) = w.value
f(x) = x
g(x, y) = (x, y)

@forward wrapped_value(w::Wrapper) begin
    f(w)
    g(x, w)
end
```

This generates methods equivalent to

```julia
f(w::Wrapper) = f(wrapped_value(w))
g(x, w::Wrapper) = g(x, wrapped_value(w))
```

## Related packages

AccessorForwarding is intentionally small: it forwards explicitly listed method
signatures through an accessor function. Depending on the shape of the wrapper,
these packages may also be useful:

- [ForwardMethods.jl](https://github.com/curtd/ForwardMethods.jl) provides
  broader method- and interface-forwarding macros, including support for
  forwarding to fields, properties, indexing expressions, and accessor calls.
- [`@forward` in Lazy.jl](https://github.com/MikeInnes/Lazy.jl/blob/master/src/macros.jl)
  provides a compact field-forwarding helper with syntax like
  `@forward Wrapper.value Base.length, Base.getindex`.
- [MethodForwarding.jl](https://github.com/cshen/MethodForwarding.jl) explores
  automatic method forwarding for composition and wrapper types.
- [ProxyInterfaces.jl](https://github.com/jolin-io/ProxyInterfaces.jl) defines
  standard proxy interfaces for common wrapper patterns and includes a compact
  `@forward` helper for forwarding selected functions to a struct field.
- [ReusePatterns.jl](https://github.com/gcalderone/ReusePatterns.jl) supports
  composition-oriented reuse patterns, including forwarding existing methods
  from a wrapper type to a field.
