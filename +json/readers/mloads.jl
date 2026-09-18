"""
    MLoads

Read MATLAB `json.mdumps` format-2 payloads in Julia. Reference implementation
of the format in `+json/FORMAT.md`. Read-only: there is no Julia writer.

Deliberately **parser-agnostic** — it takes an already-parsed JSON value, so it
adds no dependency of its own and works with whichever JSON package a project
already has:

```julia
include("mloads.jl")
using .MLoads, JSON            # or JSON3

obj = mloads(JSON.parse(row_text))            # JSON.jl
obj = mloads(JSON3.read(row_text, Any))       # JSON3.jl
```

Type mapping
------------
| MATLAB                    | Julia                                          |
|:--------------------------|:-----------------------------------------------|
| scalar struct             | `Dict{String,Any}`                             |
| struct array              | `Vector{Dict{String,Any}}`, column-major       |
| cell array                | `Vector{Any}`, column-major                    |
| numeric / logical array   | `Array{T,N}` with MATLAB's shape               |
| numeric / logical scalar  | `Float64` / `Int64` / `Bool` / ...             |
| char (row vector, empty)  | `String`                                       |
| char (2-D, >1 row)        | `Vector{String}`, one per row                  |
| string array              | `Vector{String}` (`String` if scalar)          |

Multidimensional cell and struct arrays come back as column-major vectors;
`mloads(x; with_meta=true)` returns `(value, meta)` with every node's MATLAB
class and dims if you need the shape.

Leaves are stored flattened column-major, which is Julia's own memory order, so
`reshape` is correct as written and needs no permuting.
"""
module MLoads

export mloads, MLoadsError

struct MLoadsError <: Exception
    msg::String
end
Base.showerror(io::IO, e::MLoadsError) = print(io, "MLoadsError: ", e.msg)

const TYPES = Dict{String,DataType}(
    "double"  => Float64,
    "single"  => Float32,
    "int8"    => Int8,
    "uint8"   => UInt8,
    "int16"   => Int16,
    "uint16"  => UInt16,
    "int32"   => Int32,
    "uint32"  => UInt32,
    "int64"   => Int64,
    "uint64"  => UInt64,
    "logical" => Bool,
)

"""
    mloads(parsed; with_meta=false)

Rebuild a MATLAB value from a parsed `json.mdumps` payload. Pass the result of
`JSON.parse` / `JSON3.read(..., Any)`, not the raw text.
"""
function mloads(parsed; with_meta::Bool = false)
    obj = _asdict(parsed)
    if obj === nothing || !haskey(obj, "vals") || !haskey(obj, "info")
        throw(MLoadsError("not a json.mdumps payload (no vals/info)"))
    end

    if !haskey(obj, "fmt")
        @warn """format-1 (legacy) payload: returning "vals" as plain JSON \
                 without restoring MATLAB types or shapes. Re-save it with the \
                 current json.mdumps for a faithful decode."""
        return with_meta ? (obj["vals"], Dict()) : obj["vals"]
    end
    Int(obj["fmt"]) == 2 || throw(MLoadsError("unsupported format version $(obj["fmt"])"))

    info = obj["info"]
    info isa AbstractVector || throw(MLoadsError("info must be a list"))

    value, idx = _build(obj["vals"], info, 1)
    idx == length(info) + 1 ||
        @warn "consumed $(idx - 1) of $(length(info)) info entries; payload may be malformed"

    if with_meta
        meta = Dict(Tuple(_aslist(get(e, "p", []))) =>
                    (String(e["t"]), Tuple(Int.(_aslist(e["d"])))) for e in _asdict.(info))
        return value, meta
    end
    return value
end

# ---------------------------------------------------------------------------
# JSON3 hands back its own object type rather than a Dict, so normalise once
# here instead of special-casing the parser everywhere below.
_asdict(x::AbstractDict) = x
function _asdict(x)
    if !(x isa AbstractVector) && !(x isa AbstractString) && !(x isa Number) &&
       x !== nothing && applicable(keys, x) && applicable(getindex, x, :a)
        return Dict{String,Any}(String(k) => x[k] for k in keys(x))
    end
    return nothing
end

"""A JSON scalar stands in for a one-element array; normalise to a vector."""
_aslist(x::AbstractVector) = collect(x)
_aslist(::Nothing) = Any[]
_aslist(x) = Any[x]

"""The `n` raw child blocks of a container."""
function _elements(raw, n::Int)
    n == 0 && return Any[]
    if raw isa AbstractVector
        length(raw) == n && return collect(raw)
        n == 1 && return Any[raw]
        throw(MLoadsError("expected $n container elements, found $(length(raw))"))
    end
    n == 1 && return Any[raw]
    raw === nothing && return Any[nothing for _ in 1:n]
    throw(MLoadsError("expected $n container elements, found a $(typeof(raw))"))
end

function _build(raw, info, i::Int)
    i <= length(info) || throw(MLoadsError("ran out of info entries"))
    e = _asdict(info[i])
    e === nothing && throw(MLoadsError("info entry $i is not an object"))
    i += 1

    dims = Int.(_aslist(e["d"]))
    n = prod(dims)
    t = String(e["t"])
    get(e, "as", nothing) == "struct" && (t = "struct")

    if t == "cell"
        kids = _elements(raw, n)
        out = Vector{Any}(undef, n)
        for k in 1:n
            out[k], i = _build(kids[k], info, i)
        end
        return out, i

    elseif t == "struct"
        fields = String.(_aslist(get(e, "f", [])))
        if n == 1
            src = _asdict(raw)
            out = Dict{String,Any}()
            for name in fields
                v, i = _build(src === nothing ? nothing : get(src, name, nothing), info, i)
                out[name] = v
            end
            return out, i
        end
        kids = _elements(raw, n)
        out = Vector{Dict{String,Any}}(undef, max(n, 0))
        for k in 1:n
            src = _asdict(kids[k])
            elem = Dict{String,Any}()
            for name in fields
                v, i = _build(src === nothing ? nothing : get(src, name, nothing), info, i)
                elem[name] = v
            end
            out[k] = elem
        end
        return out, i

    elseif t == "char"
        s = raw isa AbstractString ? String(raw) : ""
        if length(dims) == 2 && dims[1] > 1
            rows, cols = dims[1], dims[2]
            ch = collect(s)
            length(ch) < rows * cols && append!(ch, fill(' ', rows * cols - length(ch)))
            # stored column-major: element (r, c) sits at r + rows * (c - 1)
            return [String([ch[r + rows * (c - 1)] for c in 1:cols]) for r in 1:rows], i
        end
        return s, i

    elseif t == "string"
        items = [x isa AbstractString ? String(x) : "" for x in _aslist(raw)]
        while length(items) < n
            push!(items, "")
        end
        items = items[1:n]
        return n == 1 ? items[1] : items, i

    elseif haskey(TYPES, t)
        T = TYPES[t]
        flat = _numeric_leaf(raw, e, n, T)
        if n == 1 && all(==(1), dims)
            return flat[1], i
        end
        return reshape(flat, dims...), i
    end

    throw(MLoadsError("unknown MATLAB class \"$t\" in info"))
end

function _numeric_leaf(raw, e, n::Int, ::Type{T}) where {T}
    if haskey(e, "s") && !isempty(_aslist(e["s"]))
        # exact decimal strings for 64-bit ints beyond 2^53
        return T[parse(T, String(x)) for x in _aslist(e["s"])][1:n]
    end

    vals = _aslist(raw)
    flat = Vector{T}(undef, n)
    filler = T <: AbstractFloat ? T(NaN) : zero(T)
    for k in 1:n
        if k <= length(vals) && vals[k] !== nothing
            flat[k] = T <: Bool ? T(vals[k] != 0) : T(vals[k])
        else
            flat[k] = filler
        end
    end

    nf = _asdict(get(e, "nf", nothing))
    if nf !== nothing && T <: AbstractFloat
        idxs = _aslist(get(nf, "i", []))
        kinds = _aslist(get(nf, "k", []))
        for (pos, kind) in zip(idxs, kinds)
            j = Int(pos)
            1 <= j <= n || continue
            k = String(kind)
            flat[j] = k == "NaN" ? T(NaN) : k == "Inf" ? T(Inf) : k == "-Inf" ? T(-Inf) : flat[j]
        end
    end
    return flat
end

end # module
