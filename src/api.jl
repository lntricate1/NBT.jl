include("readwrite.jl")

"""
    read(filename)

Read an NBT file and return the data as Julia objects.
"""
read(filename::String) = open(read, filename)

"""
    read(io)

Read NBT data from an IO and return the data as Julia objects.
"""
function read(io::IO)
  stream = BufferedInputStream(GzipDecompressorStream(io))
  type = Base.read(stream, UInt8)
  tag = _read_name(stream) => _dict_read[type](stream)
  close(stream)
  return tag
end

"""
    write(filename)

Write an NBT file and return the number of bytes written.
"""
write(file::String, tag::Pair{String, LittleDict{String, T, A, B}}) where {T,A,B} = open(file; create=true, write=true) do io write(io, tag) end

"""
    write(io)

Write NBT data to an IO and return the number of bytes written.
"""
function write(io::IO, tag::Pair{String, LittleDict{String, T, A, B}}) where {T,A,B}
  stream = BufferedOutputStream(GzipCompressorStream(io))
  t = tag
  bytes = Base.write(stream, 0xa, hton(Int16(sizeof(t.first))), t.first)
  bytes += write_tag(stream, t.second)
  close(stream)
  return bytes
end

"""
    read_uncompressed(io, ::Type{Tag})

Reads an nbt tag from an uncompressed `IO`. Not exported.
"""
function read_uncompressed(io::IO)
  type = Base.read(io, UInt8)
  return _read_name(io) => _dict_read[type](io)
end

"""
    write_uncompressed(io, tag)

Writes an nbt tag to an uncompressed `IO`. Not exported.
"""
function write_uncompressed(io::IO, tag::LittleDict{String, T, A, B}) where {T,A,B}
  bytes = Base.write(io, 0xa, hton(Int16(sizeof(tag.first))), tag.first)
  return bytes + write_tag(io, tag.second)
end

"""
    write_tag(io, name => data)

Write the `name => data` pair and return the number of bytes written. Use only between [`begin_compound`](@ref) and [`end_compound`](@ref).
"""
write_tag(io::IO, data::Pair{String, T}) where T = Base.write(io, _id(data.second), _n(data.first), data.first) + write_tag(io, data.second)

"""
    begin_list(io, name, length, type)

Begin an NBT List tag with the specified length and element type and return the number of bytes written. Use only between [`begin_compound`](@ref) and [`end_compound`](@ref).
"""
function begin_list(io::IO, name::String, length::Integer, ::Type{T}) where T
  written = Base.write(io, 0x9, _n(name), name)
  # id = length > 0 ? _type_to_id_dict[T] : 0x0
  id = length > 0 ? _id(T) : 0x0
  return written + Base.write(io, id, hton(Int32(length)))
end

"""
    begin_list(io, length, type)

Begin an NBT List tag with the specified length and element type and return the number of bytes written. Use only after [`begin_list`](@ref).
"""
function begin_list(io::IO, length::Integer, ::Type{T}) where T
  # id = length > 0 ? _type_to_id_dict[T] : 0x0
  id = length > 0 ? _id(T) : 0x0
  return Base.write(io, id, hton(Int32(length)))
end

"""
    begin_compound(io, name)

Begin an NBT Compound tag and return the number of bytes written. Use only for the root tag (with an empty name) or between [`begin_compound`](@ref) and [`end_compound`](@ref).
"""
begin_compound(io::IO, name::String) = Base.write(io, 0xa, _n(name), name)

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
end_compound(io::IO) = Base.write(io, 0x0)

"""
    begin_nbt_file(io)

Begin an NBT file and return a stream and the number of bytes written.
"""
function begin_nbt_file(io::IO)
  stream = BufferedOutputStream(GzipCompressorStream(io))
  bytes = Base.write(stream, 0xa, _n(""))
  return stream, bytes
end

"""
    end_nbt_file(io)

End an NBT file and return the number of bytes written.
"""
function end_nbt_file(io::IO)
  Base.write(io, 0x0)
  close(io)
  return 1
end
