using AccessorForwarding
using Test

@testset "AccessorForwarding.jl" begin
    struct Wrapper{T}
        value::T
    end

    wrapped_value(w::Wrapper) = w.value

    noarg(x) = (:noarg, x)
    leading_arg(x, y) = (:leading_arg, x, y)
    trailing_arg(x, y) = (:trailing_arg, x, y)
    typed_arg(x::Integer, y) = (:typed_arg, x, y)
    array_or_callable(A::AbstractArray{<:Number}, y) = (:array, A, y)
    array_or_callable(f::Any, y) = (:callable, f, y)
    keyword_arg(x, y; scale=1) = (:keyword_arg, x, y, scale)
    vararg(x, y...) = (:vararg, x, y)

    @forward wrapped_value(w::Wrapper) begin
        noarg(w)
        leading_arg(x, w)
        trailing_arg(w, y)
        typed_arg(x::Integer, w)
        array_or_callable(A::AbstractArray{<:Number}, w)
        keyword_arg(w, y; kwargs...)
        vararg(w, y...)
    end

    w = Wrapper(:inner)

    @test noarg(w) == (:noarg, :inner)
    @test leading_arg(:x, w) == (:leading_arg, :x, :inner)
    @test trailing_arg(w, :y) == (:trailing_arg, :inner, :y)
    @test typed_arg(1, w) == (:typed_arg, 1, :inner)
    @test array_or_callable([1, 2], w) == (:array, [1, 2], :inner)
    @test array_or_callable(sin, w) == (:callable, sin, w)
    @test keyword_arg(w, :y; scale=2) == (:keyword_arg, :inner, :y, 2)
    @test vararg(w, :y, :z) == (:vararg, :inner, (:y, :z))

    @test_throws MethodError typed_arg(1.2, w)
end
