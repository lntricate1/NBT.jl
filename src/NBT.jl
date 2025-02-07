module NBT

using CodecZlib, BufferedStreams
export Tag
export get_tags, set_tags

"""
    struct Tag{T}

Represents an NBT tag, containing an id, a name, and data.

The following are all values of `T`, ordered by `id`, starting from 0x1, and their corresponding names on the wiki:

`[UInt8, Int16, Int32, Int64, Float32, Float64, UInt8[],    String, Tag[], Tag[],    Int32[],   Int64[]   ]`

`[Byte,  Short, Int,   Long,  Float,   Double,  Byte_Array, String, List,  Compound, Int_Array, Long_Array]`

# Properties
- `id::UInt8`: The id of the tag. See [minecraft wiki](https://minecraft.wiki/NBT_format).
- `name::String`: The name of the tag.
- `data::T`: The data in the tag. Its type is dictated by `id`. Do not use the wrong id-T combination or everything will break!
"""
struct Tag{ID,T}
  id::Val{ID}
  name::String
  data::T
end

Tag(id::UInt8, name::String, data::T) where T = Tag(Val(id), name, data)

Base.isequal(x::Tag, y::Tag) = x.id == y.id && x.name == y.name && x.data == y.data
Base.:(==)(x::Tag, y::Tag) = x.id == y.id && x.name == y.name && x.data == y.data
Base.hash(x::Tag, h::UInt) = hash(x.id, hash(x.name, hash(x.data, hash(:Tag, h))))

Base.sizeof(t::Tag) = 1 + sizeof(t.name) + sizeof(t.data)
Base.sizeof(a::Array{Tag}) = length(a) == 0 ? 0 : sum(sizeof.(a))
Base.sizeof(a::SubArray{Tag, <:Any, <:Array}) = length(a) == 0 ? 0 : sum(sizeof.(a))

function Base.read(io::IO, ::Type{Tag})
  stream = BufferedInputStream(GzipDecompressorStream(io))
  type = read(stream, UInt8)
  tag = Tag(type, _read_name(stream), _read_tag(stream, Val(type)))
  close(stream)
  return tag
end

"""
    read_nbt_uncompressed(io, ::Type{Tag})

Reads an nbt tag from an uncompressed `IO`. Not exported.
"""
function read_nbt_uncompressed(io::IO, ::Type{Tag})
  type = read(io, UInt8)
  return Tag(type, _read_name(io), _read_tag(io, Val(type)))
end

function Base.write(io::IO, tag::Tag)
  stream = BufferedOutputStream(GzipCompressorStream(io))
  bytes = _write_tag(stream, tag, true)
  close(stream)
  return bytes
end

"""
    write_nbt_uncompressed(io, tag)

Writes an nbt tag to an uncompressed `IO`. Not exported.
"""
write_nbt_uncompressed(io::IO, tag::Tag) = _write_tag(io, tag, true)

_read_name(io::IO) = String(read(io, ntoh(read(io, UInt16))))
_read_tag(io::IO, ::Val{0x1}) = ntoh(read(io, UInt8))
_read_tag(io::IO, ::Val{0x2}) = ntoh(read(io, Int16))
_read_tag(io::IO, ::Val{0x3}) = ntoh(read(io, Int32))
_read_tag(io::IO, ::Val{0x4}) = ntoh(read(io, Int64))
_read_tag(io::IO, ::Val{0x5}) = ntoh(read(io, Float32))
_read_tag(io::IO, ::Val{0x6}) = ntoh(read(io, Float64))
_read_tag(io::IO, ::Val{0x7}) = [ntoh(read(io, Int8)) for _ in 1:ntoh(read(io, Int32))]
_read_tag(io::IO, ::Val{0xb}) = [ntoh(read(io, Int32)) for _ in 1:ntoh(read(io, Int32))]
_read_tag(io::IO, ::Val{0xc}) = [ntoh(read(io, Int64)) for _ in 1:ntoh(read(io, Int32))]
_read_tag(io::IO, ::Val{0x8}) = String(read(io, ntoh(read(io, UInt16))))
function _read_tag(io::IO, ::Val{0x9})
  contentsid = read(io, UInt8)
  size = ntoh(read(io, Int32))
  contentsid == 0x0 && return Tag{0x01, UInt8}[]
  tags = [Tag(contentsid, "", _read_tag(io, Val(contentsid))) for _ in 1:size]
  return tags
end
function _read_tag(io::IO, ::Val{0xa})
  tags = Tag[]
  while (contentsid = read(io, UInt8)) != 0x0
    push!(tags, Tag(contentsid, _read_name(io), _read_tag(io, Val(contentsid))))
  end
  return tags
end

@inline function _write_name(io::IO, tag::Tag{ID, T}, should::Bool) where {ID, T}
  return should ? write(io, ID, hton(Int16(sizeof(tag.name))), tag.name) : 0
end
_write_tag(io::IO, tag::Tag{0x1, UInt8}, name::Bool) =    (_write_name(io, tag, name) + write(io, hton(tag.data)))
_write_tag(io::IO, tag::Tag{0x2, Int16}, name::Bool) =   (_write_name(io, tag, name) + write(io, hton(tag.data)))
_write_tag(io::IO, tag::Tag{0x3, Int32}, name::Bool) =   (_write_name(io, tag, name) + write(io, hton(tag.data)))
_write_tag(io::IO, tag::Tag{0x4, Int64}, name::Bool) =   (_write_name(io, tag, name) + write(io, hton(tag.data)))
_write_tag(io::IO, tag::Tag{0x5, Float32}, name::Bool) = (_write_name(io, tag, name) + write(io, hton(tag.data)))
_write_tag(io::IO, tag::Tag{0x6, Float64}, name::Bool) = (_write_name(io, tag, name) + write(io, hton(tag.data)))
_write_tag(io::IO, tag::Tag{0x7, Vector{Int8}}, name::Bool) =  (_write_name(io, tag, name) + write(io, hton(Int32(length(tag.data)))) + write(io, hton.(tag.data)))
_write_tag(io::IO, tag::Tag{0xb, Vector{Int32}}, name::Bool) = (_write_name(io, tag, name) + write(io, hton(Int32(length(tag.data)))) + write(io, hton.(tag.data)))
_write_tag(io::IO, tag::Tag{0xc, Vector{Int64}}, name::Bool) = (_write_name(io, tag, name) + write(io, hton(Int32(length(tag.data)))) + write(io, hton.(tag.data)))
_write_tag(io::IO, tag::Tag{0x8, String}, name::Bool) = _write_name(io, tag, name) + write(io, hton(UInt16(sizeof(tag.data)))) + write(io, tag.data)
function _write_tag(io::IO, tag::Tag{0x9, Vector{Tag{ID, T}}}, name::Bool) where {ID, T}
  bytes_written = _write_name(io, tag, name)
  bytes_written += write(io, length(tag.data) > 0 ? ID : 0x0)
  bytes_written += write(io, hton(Int32(length(tag.data))))
  for t in tag.data
    bytes_written += _write_tag(io, t, false)
  end
  return bytes_written
end
function _write_tag(io::IO, tag::Tag{0xa, Vector{Tag}}, name::Bool)
  bytes_written = _write_name(io, tag, name)
  for t in tag.data
    bytes_written += _write_tag(io, t, true)
  end
  return bytes_written + write(io, 0x0)
end
_write_tag(::IO, ::Tag{ID, T}, ::Bool) where {ID, T} = throw(error("invalid tag id ($(ID)); tags may be corrupt"))

function Base.show(io::IO, ::MIME"text/plain", tag::Tag)
  _show(io, tag)
end

function Base.show(io::IO, tag::Tag{ID, T}) where {ID, T}
  print(io, "Tag{",
    ("Byte", "Int16", "Int32", "Int64", "Float32", "Float64", "Byte[]", "String", "Tag[]", "Tag[]", "Int32[]", "Int64[]")[ID],
    "} \"", tag.name, '"')
end

function _show(io::IO, tag::Tag{ID, T}; indent::String="") where {ID, T}
  print(io, indent, "(", ID, ") ",
    ("Byte ", "Int16 ", "Int32 ", "Int64 ", "Float32 ", "Float64 ", "Byte[] ", "String ", "Tag[] ", "Tag[] ", "Int32[] ", "Int64[] ")[ID],
    (tag.name == "" ? "(unnamed)" : tag.name), ":")

  if ID < 0x7 || ID == 0x8
    print(io, " ", string(tag.data))

  else
    if ID == 0x7 || ID == 0xb || ID == 0xc
      for i ∈ eachindex(tag.data)
        print(io, "\n", indent, "▏ ", string(tag.data[i]))
        if i > 10
          print(io, "\n", indent, "▏ ...")
          break
        end
      end

    elseif ID == 0x9 || ID == 0xa
      for i ∈ eachindex(tag.data)
        println(io)
        _show(io, tag.data[i]; indent=indent * "▏ ")
        if i > 10
          print(io, "\n", indent, "▏ ...")
          break
        end
      end
    end
  end
end

"""
    get_tags(tag, name::String; depth=10)

Returns a `Vector{Tag}` containing all `Tag`s in `tag` named `name`, with an optional search depth limit.

For convenience, [`getindex`](@ref) is implemented, and only gets the first match on depth 1:

```jldoctest
julia> tag = Tag(0xa, "", [
         Tag(0x3, "test_int", Int32(5)),
         Tag(0x4, "test_long", Int64(5)),
         Tag(0x3, "test_int_2", Int32(5))
       ])
(10) Tag[] (unnamed):
▏ (3) Int32 test_int: 5
▏ (4) Int64 test_long: 5
▏ (3) Int32 test_int_2: 5

julia> tag["test_int"]
(3) Int32 test_int: 5

julia> tag["test_int"] === get_tags(tag, "test_int"; depth=1)[1]
true
```

See also [`get_tags`](@ref)
"""
function get_tags(tag::Tag, name::String; depth::Int=10)
  tags = Tag[]
  if depth > 0 && (tag.id == 0x9 || tag.id == 0xa)
    for t::Tag ∈ tag.data
      tags = vcat(tags, get_tags(t, name; depth=depth-1))
    end
  end

  if tag.name == name
    push!(tags, tag)
  end

  return tags
end

"""
    set_tags(tag, name::String, newtag; depth=10)

Sets all `Tag`s in `tag` named `name` to `newtag`, with an optional search depth limit.

For convenience, [`setindex!`](@ref) is implemented, and only sets the first match on depth 1:

```jldoctest
julia> tag = Tag(0xa, "", [
         Tag(0x3, "test_int", Int32(5)),
         Tag(0x4, "test_long", Int64(5)),
         Tag(0x3, "test_int_2", Int32(5))
       ])
(10) Tag[] (unnamed):
▏ (3) Int32 test_int: 5
▏ (4) Int64 test_long: 5
▏ (3) Int32 test_int_2: 5

julia> tag["test_long"] = Tag(0x4, "test_long", 69420)
(4) Int64 test_long: 69420
```

See also [`get_tags`](@ref)
"""
function set_tags(tag::Tag, name::String, newtag::Tag; depth::Int=10)
  if depth > 0 && (tag.id == 0x9 || tag.id == 0xa)
    for i ∈ eachindex(tag.data)
      tag.data[i] = set_tags(tag.data[i], name, newtag; depth=depth-1)
    end
  end

  if tag.name == name
    return newtag
  end

  return tag
end

function Base.getindex(tag::Tag, name::String)
  for t::Tag ∈ tag.data
    if t.name == name return t end
  end
end

function Base.setindex!(tag::Tag, newtag::Tag, name::String)
  for i ∈ eachindex(tag.data)
    if tag.data[i].name == name return tag.data[i] = newtag end
  end
  return newtag
end

"""
    get_tags(tag, id::Integer; depth=10)

Returns a `Vector{Tag}` containing all `Tag`s in `tag` with id `id`, with an optional search depth limit.

For convenience, [`getindex`](@ref) is implemented, and only gets the first match on depth 1:

```jldoctest
julia> tag = Tag(0xa, "", [
         Tag(0x3, "test_int", Int32(5)),
         Tag(0x4, "test_long", Int64(5)),
         Tag(0x3, "test_int_2", Int32(5))
       ])
(10) Tag[] (unnamed):
▏ (3) Int32 test_int: 5
▏ (4) Int64 test_long: 5
▏ (3) Int32 test_int_2: 5

julia> tag[4]
(4) Int64 test_long: 5

julia> tag[3]
(3) Int32 test_int: 5

julia> tag[3] === get_tags(tag, 3; depth=1)[1]
true
```

See also [`get_tags`](@ref)
"""
function get_tags(tag::Tag, id::Integer; depth::Int=10)
  tags = Tag[]
  if depth > 0 && (tag.id == 0x9 || tag.id == 0xa)
    for t::Tag ∈ tag.data
      tags = vcat(tags, get_tags(t, id; depth=depth-1))
    end
  end

  if tag.id == id
    push!(tags, tag)
  end

  return tags
end

"""
    set_tags(tag, id::Integer, newtag; depth=10)

Sets all `Tag`s in `tag` with id `id` to `newtag`, with an optional search depth limit.

For convenience, [`setindex!`](@ref) is implemented, and only sets the first match on depth 1:

```jldoctest
julia> tag = Tag(0xa, "", [
         Tag(0x3, "test_int", Int32(5)),
         Tag(0x4, "test_long", Int64(5)),
         Tag(0x3, "test_int_2", Int32(5))
       ])
(10) Tag[] (unnamed):
▏ (3) Int32 test_int: 5
▏ (4) Int64 test_long: 5
▏ (3) Int32 test_int_2: 5

julia> tag[4] = Tag(0x4, "test_long", 69420)
(4) Int64 test_long: 69420
```

See also [`get_tags`](@ref)
"""
function set_tags(tag::Tag, id::Integer, newtag::Tag; depth::Int=10)
  if depth > 0 && (tag.id == 0x9 || tag.id == 0xa)
    for i ∈ eachindex(tag.data)
      tag.data[i] = set_tags(tag.data[i], id, newtag; depth=depth-1)
    end
  end

  if tag.id == id
    return newtag
  end

  return tag
end

function Base.getindex(tag::Tag, id::Integer)
  for t::Tag ∈ tag.data
    if t.id == id return t end
  end
end

function Base.setindex!(tag::Tag, newtag::Tag, id::Integer)
  for i ∈ eachindex(tag.data)
    if tag.data[i].id == id return tag.data[i] = newtag end
  end
  return newtag
end

_skip1(io::IO) = skip(io, 1)
_skip2(io::IO) = skip(io, 2)
_skip3(io::IO) = skip(io, 4)
_skip4(io::IO) = skip(io, 8)
_skip5(io::IO) = skip(io, 4)
_skip6(io::IO) = skip(io, 8)
_skip7(io::IO) = skip(io, ntoh(read(io, Int32)))
# Multiplying s allocates for some reason, so we do for loop instead
_skipb(io::IO) = (s = ntoh(read(io, Int32)); for _ in 1:4 skip(io, s) end)
_skipc(io::IO) = (s = ntoh(read(io, Int32)); for _ in 1:8 skip(io, s) end)
_skip8(io::IO) = skip(io, ntoh(read(io, UInt16)))
const _skipsize = (1, 2, 4, 8, 4, 8)
function _skip9(io::IO)
  contentsid = read(io, UInt8)
  size = ntoh(read(io, Int32))
  if contentsid == 0x0
    return
  elseif contentsid <= 0x6
    skip(io, _skipsize[contentsid] * size)
  else
    for _ in 1:size
      @inbounds _dict[contentsid](io)
    end
  end
end
function _skipa(io::IO)
  while (contentsid = read(io, UInt8)) != 0x0
    namesize = ntoh(read(io, UInt16))
    skip(io, namesize)
    @inbounds _dict[contentsid](io)
  end
end

const _dict = Dict(0x1 => _skip1, 0x2 => _skip2, 0x3 => _skip3, 0x4 => _skip4, 0x5 => _skip5, 0x6 => _skip6, 0x7 => _skip7, 0x8 => _skip8, 0x9 => _skip9, 0xa => _skipa, 0xb => _skipb, 0xc => _skipc)

_skip(io::IO, ::Val{0x1}) = skip(io, 1)
_skip(io::IO, ::Val{0x2}) = skip(io, 2)
_skip(io::IO, ::Val{0x3}) = skip(io, 4)
_skip(io::IO, ::Val{0x4}) = skip(io, 8)
_skip(io::IO, ::Val{0x5}) = skip(io, 4)
_skip(io::IO, ::Val{0x6}) = skip(io, 8)
_skip(io::IO, ::Val{0x7}) = skip(io, ntoh(read(io, Int32)))
# Multiplying s allocates for some reason, so we do for loop instead
_skip(io::IO, ::Val{0xb}) = (s = ntoh(read(io, Int32)); for _ in 1:4 skip(io, s) end)
_skip(io::IO, ::Val{0xc}) = (s = ntoh(read(io, Int32)); for _ in 1:8 skip(io, s) end)
_skip(io::IO, ::Val{0x8}) = skip(io, ntoh(read(io, UInt16)))
const _skipsize = (1, 2, 4, 8, 4, 8)
function _skip(io::IO, ::Val{0x9})
  contentsid = read(io, UInt8)
  size = ntoh(read(io, Int32))
  if contentsid == 0x0
    return
  elseif contentsid <= 0x6
    skip(io, _skipsize[contentsid] * size)
  else
    for _ in 1:size
      _skip(io, Val(contentsid))
    end
  end
end
function _skip(io::IO, ::Val{0xa})
  while (contentsid = read(io, UInt8)) != 0x0
    namesize = ntoh(read(io, UInt16))
    skip(io, namesize)
    _skip(io, Val(contentsid))
  end
end

function _read_tag(filename::String, dict::Dict{String, Pair{Symbol, Function}})
  io = open(filename)
  stream = BufferedInputStream(GzipDecompressorStream(io))
  read(stream, UInt8) != 0xa && throw(error("Sussy root tag!! sussy!!!!"))
  namesize = ntoh(read(stream, UInt16))
  skip(stream, namesize)
  out = _read_tag(stream, Val(0xa), dict)
  close(io)
  return out
end

function _read_tag(io::IO, ::Val{0xa}, dict::Dict{String, Pair{Symbol, Function}})
  acc = NamedTuple()
  while (type = read(io, UInt8)) != 0x0
    name = String(read(io, ntoh(read(io, UInt16))))
    if haskey(dict, name)
      i, f = dict[name]
      data = f(io, Val(type))
      acc = (; acc..., i => data)
    else
      _skip(io, Val(type))
    end
  end
  return acc
end

function _read_tag(io::IO, ::Val{0xa}, f::Function, ::Type{T}) where T
  acc = T[]
  while (type = read(io, UInt8)) != 0x0
    name = String(read(io, ntoh(read(io, UInt16))))
    data = f(io, Val(type), name)
    push!(acc, data)
  end
  return acc
end

function _read_tag(io::IO, ::Val{0x9}, f::Function, ::Type{T}) where T
  type = read(io, UInt8)
  size = ntoh(read(io, Int32))
  V = Val(type)
  # return [f(io, V) for _ in 1:size]
  acc = Vector{T}(undef, size)
  for i in 1:size
    acc[i] = f(io, V)
  end
  return acc
end

end
