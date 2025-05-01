module NBT

using CodecZlib, BufferedStreams, OrderedCollections

export TagList
export begin_nbt_file, end_nbt_file, begin_compound, end_compound, begin_list, write_tag

include("api.jl")

# function Base.show(io::IO, ::MIME"text/plain", tag::Pair{String, TagCompound{T}}) where T
#   _show(io, tag.second)
# end
#
# function Base.show(io::IO, ::MIME"text/plain", tag::Pair{String, TagList{T}}) where T
#   _show(io, tag.second)
# end
#
# function Base.show(io::IO, ::MIME"text/plain", tag::TagCompound{T}) where T
#   _show(io, tag)
# end
#
# function Base.show(io::IO, ::MIME"text/plain", tag::TagList{T}) where T
#   _show(io, tag)
# end
#
# function _show(io::IO, tag::TagCompound{T}; indentstart = "", indent::String="", indentend::String="") where T
#   for i in eachindex(tag.data)
#     t = tag.data[i]
#     if t.second isa TagCompound || t.second isa TagList
#       println(io, i == 1 ? indentstart : indent, t.first, ":")
#       _show(io, t.second; indentstart = indent * "|", indent = indent * "|", indentend = i == length(tag.data) ? indentend * "└" : indent * "└")
#     else
#       println(io, i == length(tag.data) ? indentend : i == 1 ? indentstart : indent, t.first, " => ", t.second)
#     end
#   end
# end
#
# function _show(io::IO, tag::TagList{T}; indentstart::String="", indent::String="", indentend::String="") where T
#   if T<:TagCompound || T<:TagList
#     for i in eachindex(tag.data)
#       t = tag.data[i]
#       m = length(t.data) == 1 ? "-" : "└"
#       _show(io, t; indentstart = indent * "┌", indent = indent * "|", indentend = i == length(tag.data) ? indentend * m : indent * m)
#     end
#   else
#     for i in eachindex(tag.data)
#       t = tag.data[i]
#       println(io, i == length(tag.data) ? indentend : i == 1 ? indentstart : indent, t)
#     end
#   end
# end

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
