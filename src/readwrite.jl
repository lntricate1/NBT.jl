using OrderedCollections
include("structs.jl")

_n(name::String) = hton(Int16(sizeof(name)))
_id(::UInt8) = 0x1;              _id(::Type{UInt8}) = 0x1
_id(::Int16) = 0x2;              _id(::Type{Int16}) = 0x2
_id(::Int32) = 0x3;              _id(::Type{Int32}) = 0x3
_id(::Int64) = 0x4;              _id(::Type{Int64}) = 0x4
_id(::Float32) = 0x5;            _id(::Type{Float32}) = 0x5
_id(::Float64) = 0x6;            _id(::Type{Float64}) = 0x6
_id(::Vector{Int8}) = 0x7;       _id(::Type{Vector{Int8}}) = 0x7
_id(::String) = 0x8;             _id(::Type{String}) = 0x8
_id(::TagList{T}) where T = 0x9; _id(::Type{TagList{T}}) where T = 0x9
# _id(::TagCompound{T}) where T = 0xa
_id(::Vector{T}) where T = 0x9;  _id(::Type{Vector{T}}) where T = 0x9
_id(::T) where T<:AbstractDict{String} = 0xa; _id(::Type{T}) where T<:AbstractDict{String} = 0xa

_id(::Vector{Int32}) = 0xb;      _id(::Type{Vector{Int32}}) = 0xb
_id(::Vector{Int64}) = 0xc;      _id(::Type{Vector{Int64}}) = 0xc

"""
    write_tag(io, data)

Write the `data` tag and return the number of bytes written. Use only after [`begin_list`](@ref).
"""
write_tag(io::IO, data::UInt8) =   Base.write(io, data)
write_tag(io::IO, data::Int16) =   Base.write(io, hton(data))
write_tag(io::IO, data::Int32) =   Base.write(io, hton(data))
write_tag(io::IO, data::Int64) =   Base.write(io, hton(data))
write_tag(io::IO, data::Float32) = Base.write(io, hton(data))
write_tag(io::IO, data::Float64) = Base.write(io, hton(data))
write_tag(io::IO, data::Vector{Int8}) =  Base.write(io, hton(Int32(length(data))), hton.(data))
write_tag(io::IO, data::Vector{Int32}) = Base.write(io, hton(Int32(length(data))), hton.(data))
write_tag(io::IO, data::Vector{Int64}) = Base.write(io, hton(Int32(length(data))), hton.(data))
write_tag(io::IO, data::String) = Base.write(io, hton(UInt16(sizeof(data))), data)
function write_tag(io::IO, data::TagList{T}) where T
  id = length(data) > 0 ? _id(data[1]) : 0x0
  bytes_written = Base.write(io, id, hton(Int32(length(data.data))))
  for t in data.data
    bytes_written += write_tag(io, t)
  end
  return bytes_written
end
function write_tag(io::IO, data::Vector{T}) where T
  id = length(data) > 0 ? _id(data[1]) : 0x0
  bytes_written = Base.write(io, id, hton(Int32(length(data))))
  for t in data
    bytes_written += write_tag(io, t)
  end
  return bytes_written
end
function write_tag(io::IO, data::AbstractDict{String, T}) where T
  bytes_written = 0
  for t in data
    bytes_written += Base.write(io, _id(t.second), _n(t.first), t.first)
    bytes_written += write_tag(io, t.second)
  end
  return bytes_written + Base.write(io, 0x0)
end

_read_name(io::IO) = String(Base.read(io, ntoh(Base.read(io, UInt16))))
_read_tag1(io::IO) = Base.read(io, UInt8)
_read_tag2(io::IO) = ntoh(Base.Base.read(io, Int16))
_read_tag3(io::IO) = ntoh(Base.read(io, Int32))
_read_tag4(io::IO) = ntoh(Base.read(io, Int64))
_read_tag5(io::IO) = ntoh(Base.read(io, Float32))
_read_tag6(io::IO) = ntoh(Base.read(io, Float64))
_read_tag7(io::IO) = [Base.read(io, Int8) for _ in 1:ntoh(Base.read(io, Int32))]
_read_tagb(io::IO) = [ntoh(Base.read(io, Int32)) for _ in 1:ntoh(Base.read(io, Int32))]
_read_tagc(io::IO) = [ntoh(Base.read(io, Int64)) for _ in 1:ntoh(Base.read(io, Int32))]
_read_tag8(io::IO) = String(Base.read(io, ntoh(Base.read(io, UInt16))))
function _read_tag9(io::IO)
  contentsid = Base.read(io, UInt8)
  size = ntoh(Base.read(io, Int32))
  contentsid == 0x0 && return TagList(Int8[])
  tags = [_dict_read[contentsid](io) for _ in 1:size]
  return TagList(tags)
end
function _read_taga(io::IO)
  # tags = Pair{String, Any}[]
  tags = LittleDict(String[], Any[])
  while (contentsid = Base.read(io, UInt8)) != 0x0
    push!(tags, _read_name(io) => _dict_read[contentsid](io))
  end
  # return TagCompound(tags)
  # return freeze(tags)
  return isempty(tags) ? tags : freeze(tags)
end

# This is significantly faster than dispatch for reading because the types are not known until the data is read
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

# const _type_to_id_dict = Dict(
#   UInt8 => 0x1,
#   Int16 => 0x2,
#   Int32 => 0x3,
#   Int64 => 0x4,
#   Float32 => 0x5,
#   Float64 => 0x6,
#   Vector{Int8} => 0x7,
#   String => 0x8,
#   # TagList => 0x9,
#   # TagCompound => 0xa,
#   LittleDict => 0x9,
#   Vector => 0xa,
#   Vector{Int32} => 0xb,
#   Vector{Int64} => 0xc
# )
