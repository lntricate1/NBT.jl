module NBT

using CodecZlib, BufferedStreams

export TagCompound, TagList

"""
    struct TagCompound{T}

Represents an NBT compound tag, containing an array of Pairs name => data. See [minecraft wiki](https://minecraft.wiki/NBT_format).

# Properties
- `data::Vector{Pair{String, T}}`: The data in the tag.
"""
struct TagCompound{T}
  data::Vector{Pair{String, T}}
end

TagCompound() = TagCompound(Pair{String, Int8}[])

"""
    struct TagList{T}

Represents an NBT list tag, containing an array of T. See [minecraft wiki](https://minecraft.wiki/NBT_format).

# Properties
- `data::Vector{T}`: The data in the tag.
"""
struct TagList{T}
  data::Vector{T}
end

TagList() = TagList(Int8[])

const _type_to_id_dict = Dict(
  UInt8 => 0x1,
  Int16 => 0x2,
  Int32 => 0x3,
  Int64 => 0x4,
  Float32 => 0x5,
  Float64 => 0x6,
  Vector{Int8} => 0x7,
  String => 0x8,
  TagList => 0x9,
  TagCompound => 0xa,
  Vector{Int32} => 0xb,
  Vector{Int64} => 0xc
)
_n(name::String) = hton(Int16(sizeof(name)))
_id(::UInt8) = 0x1
_id(::Int16) = 0x2
_id(::Int32) = 0x3
_id(::Int64) = 0x4
_id(::Float32) = 0x5
_id(::Float64) = 0x6
_id(::Vector{Int8}) = 0x7
_id(::String) = 0x8
_id(::TagList{T}) where T = 0x9
_id(::TagCompound{T}) where T = 0xa
_id(::Vector{Int32}) = 0xb
_id(::Vector{Int64}) = 0xc


# Begin public api section
export begin_nbt_file, end_nbt_file, begin_compound, end_compound, begin_list, write_tag

"""
    write_tag(io, name => data)

Write the `name => data` pair and return the number of bytes written. Use only between [`begin_compound`](@ref) and [`end_compound`](@ref).
"""
write_tag(io::IO, data::Pair{String, T}) where T = write(io, _id(data.second), _n(data.first), data.first) + write_tag(io, data.second)

"""
    write_tag(io, data)

Write the `data` tag and return the number of bytes written. Use only after [`begin_list`](@ref).
"""
write_tag(io::IO, data::UInt8) =   write(io, data)
write_tag(io::IO, data::Int16) =   write(io, hton(data))
write_tag(io::IO, data::Int32) =   write(io, hton(data))
write_tag(io::IO, data::Int64) =   write(io, hton(data))
write_tag(io::IO, data::Float32) = write(io, hton(data))
write_tag(io::IO, data::Float64) = write(io, hton(data))
write_tag(io::IO, data::Vector{Int8}) =  write(io, hton(Int32(length(data))), hton.(data))
write_tag(io::IO, data::Vector{Int32}) = write(io, hton(Int32(length(data))), hton.(data))
write_tag(io::IO, data::Vector{Int64}) = write(io, hton(Int32(length(data))), hton.(data))
write_tag(io::IO, data::String) = write(io, hton(UInt16(sizeof(data))), data)
function write_tag(io::IO, data::TagList{T}) where T
  id = length(data) > 0 ? _id(data[1]) : 0x0
  bytes_written = write(io, id, hton(Int32(length(data.data))))
  for t in data.data
    bytes_written += write_tag(io, t)
  end
  return bytes_written
end
function write_tag(io::IO, data::TagCompound{T}) where T
  bytes_written = 0
  for t in data.data
    bytes_written += write(io, _id(t.second), _n(t.first), t.first)
    bytes_written += write_tag(io, t.second)
  end
  return bytes_written + write(io, 0x0)
end

"""
    begin_list(io, name, length, type)

Begin an NBT List tag with the specified length and element type and return the number of bytes written. Use only between [`begin_compound`](@ref) and [`end_compound`](@ref).
"""
function begin_list(io::IO, name::String, length::Integer, ::Type{T}) where T
  written = write(io, 0x9, _n(name), name)
  id = length > 0 ? _type_to_id_dict[T] : 0x0
  return written + write(io, id, hton(Int32(length)))
end

"""
    begin_list(io, length, type)

Begin an NBT List tag with the specified length and element type and return the number of bytes written. Use only after [`begin_list`](@ref).
"""
function begin_list(io::IO, length::Integer, ::Type{T}) where T
  id = length > 0 ? _type_to_id_dict[T] : 0x0
  return write(io, id, hton(Int32(length)))
end

"""
    begin_compound(io, name)

Begin an NBT Compound tag and return the number of bytes written. Use only for the root tag (with an empty name) or between [`begin_compound`](@ref) and [`end_compound`](@ref).
"""
begin_compound(io::IO, name::String) = write(io, 0xa, _n(name), name)

"""
    begin_compound(io)

Begin an NBT Compound tag and return the number of bytes written. Use only after [`begin_list`](@ref).

*Note: This method just returns `0`, but is included for completeness and to allow for more readable code.*
"""
begin_compound(io::IO) = 0

"""
    end_compound(io)

End the current NBT Compound tag and return the number of bytes written.
"""
end_compound(io::IO) = write(io, 0x0)

"""
    begin_nbt_file(io)

Begin an NBT file and return a stream and the number of bytes written.
"""
function begin_nbt_file(io::IO)
  stream = BufferedOutputStream(GzipCompressorStream(io))
  bytes = write(stream, 0xa, _n(""))
  return stream, bytes
end

"""
    end_nbt_file(io)

End an NBT file and return the number of bytes written.
"""
function end_nbt_file(io::IO)
  write(io, 0x0)
  close(io)
  return 1
end

# Begin overloads

Base.isequal(x::TagCompound, y::TagCompound) = x.data == y.data
Base.isequal(x::TagList, y::TagList) = x.data == y.data
Base.:(==)(x::TagCompound, y::TagCompound) = x.data == y.data
Base.:(==)(x::TagList, y::TagList) = x.data == y.data
Base.hash(x::TagCompound, h::UInt) = hash(x.data, hash(:TagCompound, h))
Base.hash(x::TagList, h::UInt) = hash(x.data, hash(:TagCompound, h))
Base.sizeof(t::TagCompound) = sizeof(t.data)
Base.sizeof(t::TagList) = sizeof(t.data)
Base.length(t::TagCompound) = length(t.data)
Base.length(t::TagList) = length(t.data)

function Base.getindex(tag::TagCompound{T}, name::String) where T
  for t in tag.data
    t.first == name && return t.second
  end
end

function Base.setindex!(tag::TagCompound{T}, newtag::T, name::String) where T
  for i ∈ eachindex(tag.data)
    tag.data[i].first == name && return tag.data[i] = name => newtag
  end
  return name => newtag
end

Base.getindex(::TagCompound{T}, ::Integer) where T =
  throw(ArgumentError("NBT Compound tags do not have a consistent order. Use a String for indexing instead"))
Base.setindex(::TagCompound{T}, ::T, ::Integer) where T =
  throw(ArgumentError("NBT Compound tags do not have a consistent order. Use a String for indexing instead"))

function Base.getindex(tag::TagList{T}, i::Integer) where T
  return tag.data[i]
end

function Base.setindex!(tag::TagList{T}, newtag, i::Integer) where T
  return tag.data[i] = newtag
end

function Base.read(io::IO, ::Type{TagCompound})
  stream = BufferedInputStream(GzipDecompressorStream(io))
  type = read(stream, UInt8)
  tag = _read_name(stream) => _dict_read[type](stream)
  close(stream)
  return tag
end

function Base.write(io::IO, tag::Pair{String, TagCompound{T}}) where T
  stream = BufferedOutputStream(GzipCompressorStream(io))
  bytes = write(stream, 0xa, hton(Int16(sizeof(tag.first))), tag.first)
  bytes += write_tag(stream, tag.second)
  close(stream)
  return bytes
end

# Begin internal section

"""
    read_nbt_uncompressed(io, ::Type{Tag})

Reads an nbt tag from an uncompressed `IO`. Not exported.
"""
function read_nbt_uncompressed(io::IO, ::Type{TagCompound})
  type = read(io, UInt8)
  return _read_name(io) => _dict_read[type](io)
end

"""
    write_nbt_uncompressed(io, tag)

Writes an nbt tag to an uncompressed `IO`. Not exported.
"""
function write_nbt_uncompressed(io::IO, tag::Pair{String, TagCompound{T}}) where T
  bytes = write(io, 0xa, hton(Int16(sizeof(tag.first))), tag.first)
  return bytes + write_tag(io, tag.second)
end

_read_name(io::IO) = String(read(io, ntoh(read(io, UInt16))))
_read_tag1(io::IO) = read(io, UInt8)
_read_tag2(io::IO) = ntoh(read(io, Int16))
_read_tag3(io::IO) = ntoh(read(io, Int32))
_read_tag4(io::IO) = ntoh(read(io, Int64))
_read_tag5(io::IO) = ntoh(read(io, Float32))
_read_tag6(io::IO) = ntoh(read(io, Float64))
_read_tag7(io::IO) = [read(io, Int8) for _ in 1:ntoh(read(io, Int32))]
_read_tagb(io::IO) = [ntoh(read(io, Int32)) for _ in 1:ntoh(read(io, Int32))]
_read_tagc(io::IO) = [ntoh(read(io, Int64)) for _ in 1:ntoh(read(io, Int32))]
_read_tag8(io::IO) = String(read(io, ntoh(read(io, UInt16))))
function _read_tag9(io::IO)
  contentsid = read(io, UInt8)
  size = ntoh(read(io, Int32))
  contentsid == 0x0 && return TagList(Int8[])
  tags = [_dict_read[contentsid](io) for _ in 1:size]
  return TagList(tags)
end
function _read_taga(io::IO)
  tags = Pair{String, Any}[]
  while (contentsid = read(io, UInt8)) != 0x0
    push!(tags, _read_name(io) => _dict_read[contentsid](io))
  end
  return TagCompound(tags)
end

const _dict_read = Dict(
0x1 => _read_tag1,
0x2 => _read_tag2,
0x3 => _read_tag3,
0x4 => _read_tag4,
0x5 => _read_tag5,
0x6 => _read_tag6,
0x7 => _read_tag7,
0x8 => _read_tag8,
0x9 => _read_tag9,
0xa => _read_taga,
0xb => _read_tagb,
0xc => _read_tagc)

function Base.show(io::IO, ::MIME"text/plain", tag::Pair{String, TagCompound{T}}) where T
  _show(io, tag.second)
end

function Base.show(io::IO, ::MIME"text/plain", tag::Pair{String, TagList{T}}) where T
  _show(io, tag.second)
end

function Base.show(io::IO, ::MIME"text/plain", tag::TagCompound{T}) where T
  _show(io, tag)
end

function Base.show(io::IO, ::MIME"text/plain", tag::TagList{T}) where T
  _show(io, tag)
end

function _show(io::IO, tag::TagCompound{T}; indentstart = "", indent::String="", indentend::String="") where T
  for i in eachindex(tag.data)
    t = tag.data[i]
    if t.second isa TagCompound || t.second isa TagList
      println(io, i == 1 ? indentstart : indent, t.first, ":")
      _show(io, t.second; indentstart = indent * "|", indent = indent * "|", indentend = i == length(tag.data) ? indentend * "└" : indent * "└")
    else
      println(io, i == length(tag.data) ? indentend : i == 1 ? indentstart : indent, t.first, " => ", t.second)
    end
  end
end

function _show(io::IO, tag::TagList{T}; indentstart::String="", indent::String="", indentend::String="") where T
  if T<:TagCompound || T<:TagList
    for i in eachindex(tag.data)
      t = tag.data[i]
      m = length(t.data) == 1 ? "-" : "└"
      _show(io, t; indentstart = indent * "┌", indent = indent * "|", indentend = i == length(tag.data) ? indentend * m : indent * m)
    end
  else
    for i in eachindex(tag.data)
      t = tag.data[i]
      println(io, i == length(tag.data) ? indentend : i == 1 ? indentstart : indent, t)
    end
  end
end

# _skipsave1(io::IO) = read(io, UInt8)
# _skipsave2(io::IO) = ntoh(read(io, Int16))
# _skipsave3(io::IO) = ntoh(read(io, Int32))
# _skipsave4(io::IO) = ntoh(read(io, Int64))
# _skipsave5(io::IO) = ntoh(read(io, Float32))
# _skipsave6(io::IO) = ntoh(read(io, Float64))
# # _skipsave7(io::IO) = ntuple(i -> read(io, Int8), ntoh(read(io, Int32)))
# # _skipsaveb(io::IO) = ntuple(i -> ntoh(read(io, Int32)), ntoh(read(io, Int32)))
# # _skipsavec(io::IO) = ntuple(i -> ntoh(read(io, Int64)), ntoh(read(io, Int32)))
# function _skipsave7(io::IO)
#   l = ntoh(read(io, Int32))
#   n = position(io)
#   skip(io, l)
#   return n, l
# end
# function _skipsaveb(io::IO)
#   l = ntoh(read(io, Int32))
#   n = position(io)
#   for _ in 1:4 skip(io, l) end
#   return n, l
# end
# function _skipsavec(io::IO)
#   l = ntoh(read(io, Int32))
#   n = position(io)
#   for _ in 1:8 skip(io, l) end
#   return n, l
# end
# _skipsave8(io::IO) = String(read(io, ntoh(read(io, UInt16))))
# function _skipsave9(io::IO)
#   contentsid = read(io, UInt8)
#   size_ = ntoh(read(io, Int32))
#   if contentsid == 0x0
#     return ()
#   else
#     @inbounds f = _dict1[contentsid]
#     @inbounds out = Vector{_types[contentsid]}(undef, size_)
#     for i in 1:size_ out[i] = f(io) end
#     # return [f(io) for _ in 1:size_]
#     # return (size_)
#     return out
#   end
# end
# function __test(io::IO, f::Function, size_::Int32)
#   return Tuple(f(io) for _ in 1:size_)
# end
# function _skipsavea(io::IO)
#   tags = ()
#   while (contentsid = read(io, UInt8)) != 0x0
#     name = _read_name(io)
#     @inbounds tag = _dict1[contentsid](io)
#     @inbounds tags = (tags..., name => tag)
#   end
#   return tags
# end
#
# const _types = Dict(
# 0x1 => UInt8,
# 0x2 => Int16,
# 0x3 => Int32,
# 0x4 => Int64,
# 0x5 => Float32,
# 0x6 => Float64,
# 0x7 => Tuple{Int, Int32},
# 0x8 => String,
# 0x9 => Vector,
# 0xa => Tuple,
# 0xb => Tuple{Int, Int32},
# 0xc => Tuple{Int, Int32})
# const _dict1 = Dict(
# 0x1 => _skipsave1,
# 0x2 => _skipsave2,
# 0x3 => _skipsave3,
# 0x4 => _skipsave4,
# 0x5 => _skipsave5,
# 0x6 => _skipsave6,
# 0x7 => _skipsave7,
# 0x8 => _skipsave8,
# 0x9 => _skipsave9,
# 0xa => _skipsavea,
# 0xb => _skipsaveb,
# 0xc => _skipsavec)
#
# _skip1(io::IO) = skip(io, 1)
# _skip2(io::IO) = skip(io, 2)
# _skip3(io::IO) = skip(io, 4)
# _skip4(io::IO) = skip(io, 8)
# _skip5(io::IO) = skip(io, 4)
# _skip6(io::IO) = skip(io, 8)
# _skip7(io::IO) = skip(io, ntoh(read(io, Int32)))
# # Multiplying s allocates for some reason, so we do for loop instead
# _skipb(io::IO) = (s = ntoh(read(io, Int32)); for _ in 1:4 skip(io, s) end)
# _skipc(io::IO) = (s = ntoh(read(io, Int32)); for _ in 1:8 skip(io, s) end)
# _skip8(io::IO) = skip(io, ntoh(read(io, UInt16)))
# const _skipsize = (1, 2, 4, 8, 4, 8)
# function _skip9(io::IO)
#   contentsid = read(io, UInt8)
#   size = ntoh(read(io, Int32))
#   if contentsid == 0x0
#     return
#   elseif contentsid <= 0x6
#     skip(io, _skipsize[contentsid] * size)
#   else
#     for _ in 1:size
#       @inbounds _dict[contentsid](io)
#     end
#   end
# end
# function _skipa(io::IO)
#   while (contentsid = read(io, UInt8)) != 0x0
#     namesize = ntoh(read(io, UInt16))
#     skip(io, namesize)
#     @inbounds _dict[contentsid](io)
#   end
# end
#
# const _dict = Dict(0x1 => _skip1, 0x2 => _skip2, 0x3 => _skip3, 0x4 => _skip4, 0x5 => _skip5, 0x6 => _skip6, 0x7 => _skip7, 0x8 => _skip8, 0x9 => _skip9, 0xa => _skipa, 0xb => _skipb, 0xc => _skipc)
#
# # _skip(io::IO, ::Val{0x1}) = skip(io, 1)
# # _skip(io::IO, ::Val{0x2}) = skip(io, 2)
# # _skip(io::IO, ::Val{0x3}) = skip(io, 4)
# # _skip(io::IO, ::Val{0x4}) = skip(io, 8)
# # _skip(io::IO, ::Val{0x5}) = skip(io, 4)
# # _skip(io::IO, ::Val{0x6}) = skip(io, 8)
# # _skip(io::IO, ::Val{0x7}) = skip(io, ntoh(read(io, Int32)))
# # # Multiplying s allocates for some reason, so we do for loop instead
# # _skip(io::IO, ::Val{0xb}) = (s = ntoh(read(io, Int32)); for _ in 1:4 skip(io, s) end)
# # _skip(io::IO, ::Val{0xc}) = (s = ntoh(read(io, Int32)); for _ in 1:8 skip(io, s) end)
# # _skip(io::IO, ::Val{0x8}) = skip(io, ntoh(read(io, UInt16)))
# # function _skip(io::IO, ::Val{0x9})
# #   contentsid = read(io, UInt8)
# #   size = ntoh(read(io, Int32))
# #   if contentsid == 0x0
# #     return
# #   elseif contentsid <= 0x6
# #     skip(io, _skipsize[contentsid] * size)
# #   else
# #     for _ in 1:size
# #       _skip(io, Val(contentsid))
# #     end
# #   end
# # end
# # function _skip(io::IO, ::Val{0xa})
# #   while (contentsid = read(io, UInt8)) != 0x0
# #     namesize = ntoh(read(io, UInt16))
# #     skip(io, namesize)
# #     _skip(io, Val(contentsid))
# #   end
# # end
#
# function _read_tag(filename::String, dict::Dict{String, Pair{Symbol, Function}})
#   io = open(filename)
#   stream = BufferedInputStream(GzipDecompressorStream(io))
#   read(stream, UInt8) != 0xa && throw(error("Sussy root tag!! sussy!!!!"))
#   namesize = ntoh(read(stream, UInt16))
#   skip(stream, namesize)
#   out = _read_tag(stream, Val(0xa), dict)
#   close(io)
#   return out
# end
#
# function _read_tag(io::IO, ::Val{0xa}, dict::Dict{String, Pair{Symbol, Function}})
#   acc = NamedTuple()
#   while (type = read(io, UInt8)) != 0x0
#     name = String(read(io, ntoh(read(io, UInt16))))
#     if haskey(dict, name)
#       i, f = dict[name]
#       data = f(io, Val(type))
#       acc = (; acc..., i => data)
#     else
#       @inbounds _dict[type](io)
#     end
#   end
#   return acc
# end
#
# function _read_tag(io::IO, ::Val{0xa}, f::Function, ::Type{T}) where T
#   acc = T[]
#   while (type = read(io, UInt8)) != 0x0
#     name = String(read(io, ntoh(read(io, UInt16))))
#     data = f(io, Val(type), name)
#     push!(acc, data)
#   end
#   return acc
# end
#
# function _read_tag(io::IO, ::Val{0x9}, f::Function, ::Type{T}) where T
#   type = read(io, UInt8)
#   size = ntoh(read(io, Int32))
#   V = Val(type)
#   # return [f(io, V) for _ in 1:size]
#   acc = Vector{T}(undef, size)
#   for i in 1:size
#     acc[i] = f(io, V)
#   end
#   return acc
# end

end
