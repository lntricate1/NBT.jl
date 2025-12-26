using StructUtils
using Accessors
include("readwrite.jl")

_skip_name(io::IO) = skip(io, ntoh(Base.read(io, UInt16)))
_skip_tag1(io::IO) = skip(io, 1)
_skip_tag2(io::IO) = skip(io, 2)
_skip_tag3(io::IO) = skip(io, 4)
_skip_tag4(io::IO) = skip(io, 8)
_skip_tag5(io::IO) = skip(io, 4)
_skip_tag6(io::IO) = skip(io, 8)
_skip_tag7(io::IO) = skip(io, 1ntoh(Base.read(io, Int32)))
_skip_tagb(io::IO) = skip(io, 4ntoh(Base.read(io, Int32)))
_skip_tagc(io::IO) = skip(io, 8ntoh(Base.read(io, Int32)))
_skip_tag8(io::IO) = skip(io, ntoh(Base.read(io, UInt16)))
function _skip_tag9(io::IO)
  contentsid = Base.read(io, UInt8)
  size = ntoh(Base.read(io, Int32))
  contentsid == 0x0 && return io
  for _ in 1:size
    _lut_skip[contentsid](io)
  end
  return io
end
function _skip_taga(io::IO)
  while (contentsid = Base.read(io, UInt8)) != 0x0
    _skip_name(io)
    _lut_skip[contentsid](io)
  end
  return io
end

parse(filename::String, ::Type{S}) where S = open(io -> parse(io, S), filename)
function parse(io::IO, ::Type{S}) where S
  stream = BufferedInputStream(GzipDecompressorStream(io))
  type = Base.read(stream, UInt8)
  _skip_name(stream)
  out = _lut_parse[type](stream, S)
  close(stream)
  return out
end

_parse_tag1(io::IO, T::Type{<:Number})       = convert(T, _read_tag1(io))
_parse_tag2(io::IO, T::Type{<:Number})       = convert(T, _read_tag2(io))
_parse_tag3(io::IO, T::Type{<:Number})       = convert(T, _read_tag3(io))
_parse_tag4(io::IO, T::Type{<:Number})       = convert(T, _read_tag4(io))
_parse_tag5(io::IO, T::Type{<:Number})       = convert(T, _read_tag5(io))
_parse_tag6(io::IO, T::Type{<:Number})       = convert(T, _read_tag6(io))
_parse_tag7(io::IO, ::Type{Vector{Int8}})    = _read_tag7(io)
_parse_tagb(io::IO, ::Type{Vector{Int32}})   = _read_tagb(io)
_parse_tagc(io::IO, ::Type{Vector{Int64}})   = _read_tagc(io)
_parse_tag8(io::IO, ::Type{String})          = _read_tag8(io)
_parse_tag9(io::IO, ::Type{<:AbstractArray}) = _read_tag9(io)
_parse_taga(io::IO, ::Type{<:AbstractDict})  = _read_taga(io)

function _parse_taga(io::IO, ::Type{Vector{S}}) where S
  out = S[]
  while (contentsid = Base.read(io, UInt8)) != 0x0
    _skip_name(io)
    push!(out, _lut_parse[contentsid](io, S))
  end
  return out
end

@generated function _parse_taga(io::IO, ::Type{S}) where S
  names = fieldnames(S)
  types = fieldtypes(S)
  nested_if = :(name == $(String(names[1])) && begin
    field_1 = _lut_parse[contentsid](io, $(types[1]))
    true
  end)
  for i in 2:length(names)
    nested_if = :($nested_if || (name == $(String(names[i])) && begin
    $(Symbol("field_", i)) = _lut_parse[contentsid](io, $(types[i]))
    true
    end))
  end
  quote
    local $((:($(Symbol("field_", a))::$b) for (a,b) in enumerate(types))...)
    while (contentsid = Base.read(io, UInt8)) != 0x0
      name = _read_name(io)
      ($nested_if) || _lut_skip[contentsid](io)
    end
    return S($((Symbol("field_", a) for a in 1:length(names))...))
  end
end

const _lut_parse = [
_parse_tag1,
_parse_tag2,
_parse_tag3,
_parse_tag4,
_parse_tag5,
_parse_tag6,
_parse_tag7,
_parse_tag8,
_parse_tag9,
_parse_taga,
_parse_tagb,
_parse_tagc]

const _lut_skip = [
_skip_tag1,
_skip_tag2,
_skip_tag3,
_skip_tag4,
_skip_tag5,
_skip_tag6,
_skip_tag7,
_skip_tag8,
_skip_tag9,
_skip_taga,
_skip_tagb,
_skip_tagc]
