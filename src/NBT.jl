module NBT

using GZip: gzdopen
export Tag
export get_tags, set_tags

"""
    struct Tag{T}

Represents an NBT tag, containing an id, a name, and data.

The following are all values of `T`, ordered by `id`, starting from 0x1, and their corresponding names on the wiki:

`[UInt8, Int16, Int32, Int64, Float32, Float64, UInt8[],    String, Tag[], Tag[],    Int32[],   Int64[]   ]`

`[Byte,  Short, Int,   Long,  Float,   Double,  Byte_Array, String, List,  Compound, Int_Array, Long_Array]`

# Properties
- `id::UInt8`: The id of the tag. See [minecraft wiki](https://minecraft.fandom.com/wiki/NBT_format).
- `name::String`: The name of the tag.
- `data::T`: The data in the tag. Its type is dictated by `id`. Do not use the wrong id-T combination or everything will break!
"""
struct Tag{T}
  id::UInt8
  name::String
  data::T
end

Base.isequal(x::Tag, y::Tag) = x.id == y.id && x.name == y.name && x.data == y.data
Base.:(==)(x::Tag, y::Tag) = x.id == y.id && x.name == y.name && x.data == y.data
Base.hash(x::Tag, h::UInt) = hash(x.id, hash(x.name, hash(x.data, hash(:Tag, h))))

Base.sizeof(t::Tag) = 1 + sizeof(t.name) + sizeof(t.data)
Base.sizeof(a::Array{Tag}) = length(a) == 0 ? 0 : sum(sizeof.(a))
Base.sizeof(a::SubArray{Tag, <:Any, <:Array}) = length(a) == 0 ? 0 : sum(sizeof.(a))

function Base.read(io::IO, ::Type{Tag})
  gzio = gzdopen(io)
  return _read_tag(gzio, read(gzio, UInt8))
end

"""
    read_nbt_uncompressed(io, ::Type{Tag})

Reads an nbt tag from an uncompressed `IO`. Not exported.
"""
read_nbt_uncompressed(io::IO, ::Type{Tag}) = _read_tag(io, read(io, UInt8))

function Base.write(io::IO, tag::Tag)
  gzio = gzdopen(io, "w")
  bytes = _write_tag(gzio, tag)
  close(gzio)
  return bytes
end

"""
    write_nbt_uncompressed(io, tag)

Writes an nbt tag to an uncompressed `IO`. Not exported.
"""
write_nbt_uncompressed(io::IO, tag::Tag) = _write_tag(io, tag)

function _read_tag(io::IO, id::UInt8; skipname::Bool=false)::Tag
  types = (Int8, Int16, Int32, Int64, Float32, Float64, Int8, nothing, nothing, nothing, Int32, Int64)
  name = ""
  if !skipname
    namelength = ntoh(read(io, UInt16))
    name = String(read(io, namelength))
  end

  if id < 0x7 # Singletons
    return Tag(id, name, ntoh(read(io, types[id])))

  elseif id == 0x7 || id == 0xb || id == 0xc # Arrays
    size = ntoh(read(io, Int32))
    return Tag(id, name, [ntoh(read(io, types[id])) for _ ∈ 1:size])

  elseif id == 0x8 # String
    size = ntoh(read(io, UInt16))
    return Tag(id, name, String(read(io, size)))

  elseif id == 0x9 # Tag list
    contentsid = read(io, UInt8)
    size = ntoh(read(io, Int32))
    if contentsid == 0x0 return Tag(0x9, name, Tag[]) end
    return Tag(id, name, [_read_tag(io, contentsid; skipname=true) for _ ∈ 1:size])

  elseif id == 0xa # Compound
    tags = Tag[]
    while true
      contentsid = read(io, UInt8)
      if contentsid == 0x0 break end
      push!(tags, _read_tag(io, contentsid))
    end
    return Tag(id, name, tags)

  else throw(error("invalid tag id ($id); file may be corrupt"))
  end
end

# Only needed while https://github.com/JuliaIO/GZip.jl/issues/93 is open
function _write_fixed(io::IO, b...)
  write(io, b...)
  return sum(sizeof.(b))
end

function _write_tag(io::IO, tag::Tag; skipname::Bool=false)::Int
  bytes_written = 0
  if !skipname
    namelength = hton(Int16(sizeof(tag.name)))
    bytes_written += _write_fixed(io, tag.id, namelength, tag.name)
  end

  if tag.id < 0x7 # Singletons
    bytes_written += _write_fixed(io, hton(tag.data))

  elseif tag.id == 0x7 || tag.id == 0xb || tag.id == 0xc # Arrays
    bytes_written += write(io, hton(Int32(length(tag.data)))) # Length
    bytes_written += _write_fixed(io, hton.(tag.data))

  elseif tag.id == 0x8 # String
    bytes_written += write(io, hton(UInt16(sizeof(tag.data)))) # Length
    bytes_written += write(io, tag.data)

  elseif tag.id == 0x9 # Tag list
    bytes_written += _write_fixed(io, length(tag.data) > 0x0 ? first(tag.data).id : 0x0) # Type
    bytes_written += write(io, hton(Int32(length(tag.data)))) # Length
    for t ∈ tag.data
      bytes_written += _write_tag(io, t; skipname = true)
    end

  elseif tag.id == 0xa # Compound
    for t ∈ tag.data
      bytes_written += _write_tag(io, t)
    end
    bytes_written += _write_fixed(io, 0x0)

  else
    throw(error("invalid tag id ($(tag.id)); tags may be corrupt"))
  end

  return bytes_written
end

function Base.show(io::IO, ::MIME"text/plain", tag::Tag)
  _show(io, tag)
end

function Base.show(io::IO, tag::Tag)
  print(io, "Tag{",
    ("Byte", "Int16", "Int32", "Int64", "Float32", "Float64", "Byte[]", "String", "Tag[]", "Tag[]", "Int32[]", "Int64[]")[tag.id],
    "} \"", tag.name, '"')
end

function _show(io::IO, tag::Tag; indent::String="")
  print(io, indent, "(", tag.id, ") ",
    ("Byte ", "Int16 ", "Int32 ", "Int64 ", "Float32 ", "Float64 ", "Byte[] ", "String ", "Tag[] ", "Tag[] ", "Int32[] ", "Int64[] ")[tag.id],
    (tag.name == "" ? "(unnamed)" : tag.name), ":")

  if tag.id < 0x7 || tag.id == 0x8
    print(io, " ", string(tag.data))

  else
    if tag.id == 0x7 || tag.id == 0xb || tag.id == 0xc
      for i ∈ eachindex(tag.data)
        print(io, "\n", indent, "▏ ", string(tag.data[i]))
        if i > 10
          print(io, "\n", indent, "▏ ...")
          break
        end
      end

    elseif tag.id == 0x9 || tag.id == 0xa
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
julia> ls()


julia> tag = read("xd.litematic", Tag);

julia> tag["Version"] === get_tags(tag, "Version"; depth=1)[1]
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
julia> tag = read("xd.litematic", Tag);

julia> tag["Version"] = Tag(0x3, "Version", 69420)
Int32 Version: 69420
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
julia> tag = read("xd.litematic", Tag);

julia> tag[0x3] === get_tags(tag, 0x3; depth=1)[1]
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
julia> tag = read("xd.litematic", Tag);

julia> tag[0x3] = Tag(0x3, "EEEE", 69420)
Int32 EEEE: 69420
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

end
