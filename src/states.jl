import Base: ==, +, -, *, /, length, copy
import LinearAlgebra: norm, normalize, normalize!

"""
Abstract base class for [`Bra`](@ref) and [`Ket`](@ref) states.

The state vector class stores the coefficients of an abstract state
in respect to a certain basis. These coefficients are stored in the
`data` field and the basis is defined in the `basis`
field.
"""
abstract type StateVector{B<:Basis,T<:AbstractVector} end

"""
    Bra(b::Basis[, data])

Bra state defined by coefficients in respect to the basis.
"""
mutable struct Bra{B<:Basis,T<:AbstractVector} <: StateVector{B,T}
    basis::B
    data::T
    function Bra{B,T}(b::B, data::T) where {B<:Basis,T<:AbstractVector}
        (length(b)==length(data)) || throw(DimensionMismatch("Tried to assign data of length $(length(data)) to Hilbert space of size $(length(b))"))
        new(b, data)
    end
end

"""
    Ket(b::Basis[, data])

Ket state defined by coefficients in respect to the given basis.
"""
mutable struct Ket{B<:Basis,T<:AbstractVector} <: StateVector{B,T}
    basis::B
    data::T
    function Ket{B,T}(b::B, data::T) where {B<:Basis,T<:AbstractVector}
        (length(b)==length(data)) || throw(DimensionMismatch("Tried to assign data of length $(length(data)) to Hilbert space of size $(length(b))"))
        new(b, data)
    end
end

Bra{B}(b::B, data::T) where {B<:Basis,T} = Bra{B,T}(b, data)
Ket{B}(b::B, data::T) where {B<:Basis,T} = Ket{B,T}(b, data)

Bra(b::B, data::T) where {B<:Basis,T} = Bra{B,T}(b, data)
Ket(b::B, data::T) where {B<:Basis,T} = Ket{B,T}(b, data)

Bra{B}(b::B) where B<:Basis = Bra{B}(b, zeros(ComplexF64, length(b)))
Ket{B}(b::B) where B<:Basis = Ket{B}(b, zeros(ComplexF64, length(b)))
Bra(b::Basis) = Bra(b, zeros(ComplexF64, length(b)))
Ket(b::Basis) = Ket(b, zeros(ComplexF64, length(b)))

copy(a::T) where {T<:StateVector} = T(a.basis, copy(a.data))
length(a::StateVector) = length(a.basis)::Int
basis(a::StateVector) = a.basis

==(x::Ket{B}, y::Ket{B}) where {B<:Basis} = (samebases(x, y) && x.data==y.data)
==(x::Bra{B}, y::Bra{B}) where {B<:Basis} = (samebases(x, y) && x.data==y.data)
==(x::Ket, y::Ket) = false
==(x::Bra, y::Bra) = false

Base.isapprox(x::Ket{B}, y::Ket{B}; kwargs...) where {B<:Basis} = (samebases(x, y) && isapprox(x.data,y.data;kwargs...))
Base.isapprox(x::Bra{B}, y::Bra{B}; kwargs...) where {B<:Basis} = (samebases(x, y) && isapprox(x.data,y.data;kwargs...))
Base.isapprox(x::Ket, y::Ket; kwargs...) = false
Base.isapprox(x::Bra, y::Bra; kwargs...) = false

# Arithmetic operations
+(a::Ket{B}, b::Ket{B}) where {B<:Basis} = Ket(a.basis, a.data+b.data)
+(a::Bra{B}, b::Bra{B}) where {B<:Basis} = Bra(a.basis, a.data+b.data)
+(a::Ket, b::Ket) = throw(IncompatibleBases())
+(a::Bra, b::Bra) = throw(IncompatibleBases())

-(a::Ket{B}, b::Ket{B}) where {B<:Basis} = Ket(a.basis, a.data-b.data)
-(a::Bra{B}, b::Bra{B}) where {B<:Basis} = Bra(a.basis, a.data-b.data)
-(a::Ket, b::Ket) = throw(IncompatibleBases())
-(a::Bra, b::Bra) = throw(IncompatibleBases())

-(a::T) where {T<:StateVector} = T(a.basis, -a.data)

*(a::Bra{B}, b::Ket{B}) where {B<:Basis} = transpose(a.data)*b.data
*(a::Bra, b::Ket) = throw(IncompatibleBases())
*(a::Number, b::Ket) = Ket(b.basis, a*b.data)
*(a::Number, b::Bra) = Bra(b.basis, a*b.data)
*(a::StateVector, b::Number) = b*a

/(a::Ket, b::Number) = Ket(a.basis, a.data ./ b)
/(a::Bra, b::Number) = Bra(a.basis, a.data ./ b)


"""
    dagger(x)

Hermitian conjugate.
"""
dagger(x::Bra) = Ket(x.basis, conj(x.data))
dagger(x::Ket) = Bra(x.basis, conj(x.data))
Base.adjoint(a::StateVector) = dagger(a)

"""
    tensor(x::Ket, y::Ket, z::Ket...)

Tensor product ``|x⟩⊗|y⟩⊗|z⟩⊗…`` of the given states.
"""
tensor(a::Ket, b::Ket) = Ket(tensor(a.basis, b.basis), kron(b.data, a.data))
tensor(a::Bra, b::Bra) = Bra(tensor(a.basis, b.basis), kron(b.data, a.data))
tensor(state::StateVector) = state
tensor(states::Ket...) = reduce(tensor, states)
tensor(states::Bra...) = reduce(tensor, states)
tensor(states::Vector{T}) where T<:StateVector = reduce(tensor, states)

# Normalization functions
"""
    norm(x::StateVector)

Norm of the given bra or ket state.
"""
norm(x::StateVector) = norm(x.data)

"""
    normalize(x::StateVector)

Return the normalized state so that `norm(x)` is one.
"""
normalize(x::StateVector) = x/norm(x)

"""
    normalize!(x::StateVector)

In-place normalization of the given bra or ket so that `norm(x)` is one.
"""
normalize!(x::StateVector) = (normalize!(x.data); x)

function permutesystems(state::T, perm::Vector{Int}) where T<:Ket
    @assert length(state.basis.bases) == length(perm)
    @assert isperm(perm)
    data = reshape(state.data, state.basis.shape...)
    data = permutedims(data, perm)
    data = reshape(data, length(data))
    Ket(permutesystems(state.basis, perm), data)
end
function permutesystems(state::T, perm::Vector{Int}) where T<:Bra
    @assert length(state.basis.bases) == length(perm)
    @assert isperm(perm)
    data = reshape(state.data, state.basis.shape...)
    data = permutedims(data, perm)
    data = reshape(data, length(data))
    Bra(permutesystems(state.basis, perm), data)
end

# Creation of basis states.
"""
    basisstate(b, index; sparse=false, dType=ComplexF64)

Basis vector specified by `index` as ket state.

For a composite system `index` can be a vector which then creates a tensor
product state ``|i_1⟩⊗|i_2⟩⊗…⊗|i_n⟩`` of the corresponding basis states.
"""
function basisstate(b::Basis, indices::Vector{Int}; sparse=false, dType=ComplexF64)
    @assert length(b.shape) == length(indices)
    x = if sparse
        spzeros(dType, length(b))
    else
        zeros(dType, length(b))
    end
    x[LinearIndices(tuple(b.shape...))[indices...]] = one(dType)
    Ket(b, x)
end

function basisstate(b::Basis, index::Int; sparse=false, dType=ComplexF64)
    data = if sparse
        spzeros(dType, length(b))
    else
        zeros(dType, length(b))
    end
    data[index] = one(dType)
    Ket(b, data)
end


# Helper functions to check validity of arguments
function check_multiplicable(a::Bra, b::Ket)
    if a.basis != b.basis
        throw(IncompatibleBases())
    end
end

samebases(a::Ket{B}, b::Ket{B}) where {B} = samebases(a.basis, b.basis)::Bool
samebases(a::Bra{B}, b::Bra{B}) where {B} = samebases(a.basis, b.basis)::Bool

# Array-like functions
Base.size(x::StateVector) = size(x.data)
@inline Base.axes(x::StateVector) = axes(x.data)
Base.ndims(x::StateVector) = 1
Base.ndims(::Type{<:StateVector}) = 1
Base.eltype(x::StateVector) = eltype(x.data)

# Broadcasting
Base.broadcastable(x::StateVector) = x

# Custom broadcasting style
abstract type StateVectorStyle{B<:Basis} <: Broadcast.BroadcastStyle end
struct KetStyle{B<:Basis} <: StateVectorStyle{B} end
struct BraStyle{B<:Basis} <: StateVectorStyle{B} end

# Style precedence rules
Broadcast.BroadcastStyle(::Type{<:Ket{B}}) where {B<:Basis} = KetStyle{B}()
Broadcast.BroadcastStyle(::Type{<:Bra{B}}) where {B<:Basis} = BraStyle{B}()
Broadcast.BroadcastStyle(::KetStyle{B1}, ::KetStyle{B2}) where {B1<:Basis,B2<:Basis} = throw(IncompatibleBases())
Broadcast.BroadcastStyle(::BraStyle{B1}, ::BraStyle{B2}) where {B1<:Basis,B2<:Basis} = throw(IncompatibleBases())

# Broadcast with scalars (of use in ODE solvers checking for tolerances, e.g. `.* reltol .+ abstol`)
Broadcast.BroadcastStyle(::T, ::Broadcast.DefaultArrayStyle{0}) where {B<:Basis, T<:KetStyle{B}} = T()
Broadcast.BroadcastStyle(::T, ::Broadcast.DefaultArrayStyle{0}) where {B<:Basis, T<:BraStyle{B}} = T()

# Out-of-place broadcasting
@inline function Base.copy(bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B<:Basis,Style<:KetStyle{B},Axes,F,Args<:Tuple}
    bcf = Broadcast.flatten(bc)
    b = find_basis(bcf)
    T = find_dType(bcf)
    data = zeros(T, length(b))
    @inbounds @simd for I in eachindex(bcf)
        data[I] = bcf[I]
    end
    return Ket{B}(b, data)
end
@inline function Base.copy(bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B<:Basis,Style<:BraStyle{B},Axes,F,Args<:Tuple}
    bcf = Broadcast.flatten(bc)
    b = find_basis(bcf)
    T = find_dType(bcf)
    data = zeros(T, length(b))
    @inbounds @simd for I in eachindex(bcf)
        data[I] = bcf[I]
    end
    return Bra{B}(b, data)
end
for f ∈ [:find_basis,:find_dType]
    @eval ($f)(bc::Broadcast.Broadcasted) = ($f)(bc.args)
    @eval ($f)(args::Tuple) = ($f)(($f)(args[1]), Base.tail(args))
    @eval ($f)(x) = x
    @eval ($f)(::Any, rest) = ($f)(rest)
end
find_basis(a::StateVector, rest) = a.basis
find_dType(a::StateVector, rest) = eltype(a)
Base.getindex(st::StateVector, idx) = getindex(st.data, idx)

# In-place broadcasting for Kets
@inline function Base.copyto!(dest::Ket{B}, bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B<:Basis,Style<:KetStyle{B},Axes,F,Args}
    axes(dest) == axes(bc) || throwdm(axes(dest), axes(bc))
    bc′ = Base.Broadcast.preprocess(dest, bc)
    dest′ = dest.data
    @inbounds @simd for I in eachindex(bc′)
        dest′[I] = bc′[I]
    end
    return dest
end
@inline Base.copyto!(dest::Ket{B1}, bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B1<:Basis,B2<:Basis,Style<:KetStyle{B2},Axes,F,Args} =
    throw(IncompatibleBases())

# In-place broadcasting for Bras
@inline function Base.copyto!(dest::Bra{B}, bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B<:Basis,Style<:BraStyle{B},Axes,F,Args}
    axes(dest) == axes(bc) || throwdm(axes(dest), axes(bc))
    bc′ = Base.Broadcast.preprocess(dest, bc)
    dest′ = dest.data
    @inbounds @simd for I in eachindex(bc′)
        dest′[I] = bc′[I]
    end
    return dest
end
@inline Base.copyto!(dest::Bra{B1}, bc::Broadcast.Broadcasted{Style,Axes,F,Args}) where {B1<:Basis,B2<:Basis,Style<:BraStyle{B2},Axes,F,Args} =
    throw(IncompatibleBases())

@inline Base.copyto!(A::T,B::T) where T<:StateVector = (copyto!(A.data,B.data); A)

# A few more standard interfaces: These do not necessarily make sense for a StateVector, but enable transparent use of DifferentialEquations.jl
Base.eltype(::Type{Ket{B,A}}) where {B,N,A<:AbstractVector{N}} = N # ODE init
Base.eltype(::Type{Bra{B,A}}) where {B,N,A<:AbstractVector{N}} = N
Base.zero(k::StateVector) = typeof(k)(k.basis, zero(k.data)) # ODE init
Base.any(f::Function, x::StateVector; kwargs...) = any(f, x.data; kwargs...) # ODE nan checks
Base.all(f::Function, x::StateVector; kwargs...) = all(f, x.data; kwargs...)
Broadcast.similar(k::StateVector, t) = typeof(k)(k.basis, copy(k.data))
using RecursiveArrayTools
RecursiveArrayTools.recursivecopy!(dst::Ket{B,A},src::Ket{B,A}) where {B,A} = copy!(dst.data,src.data) # ODE in-place equations
RecursiveArrayTools.recursivecopy!(dst::Bra{B,A},src::Bra{B,A}) where {B,A} = copy!(dst.data,src.data)