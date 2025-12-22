module NBT

using CodecZlib, BufferedStreams, OrderedCollections

include("readwrite.jl")

public read, write, read_uncompressed, write_uncompressed, pretty_print
public write_tag, begin_list, begin_compound, end_compound, begin_nbt_file, end_nbt_file

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
  tag = _read_name(stream) => _lut_read[type](stream)
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
  return _read_name(io) => _lut_read[type](io)
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
write_tag(io::IO, data::Pair{String, T}) where T = Base.write(io, _id(data.second), write_name_length(data.first), data.first) + write_tag(io, data.second)

"""
    begin_list(io, name, length, type)

Begin an NBT List tag with the specified length and element type and return the number of bytes written. Use only between [`begin_compound`](@ref) and [`end_compound`](@ref).
"""
function begin_list(io::IO, name::String, length::Integer, ::Type{T}) where T
  written = Base.write(io, 0x9, write_name_length(name), name)
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
begin_compound(io::IO, name::String) = Base.write(io, 0xa, write_name_length(name), name)

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
  bytes = Base.write(stream, 0xa, write_name_length(""))
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

"""
    pretty_print(data, tab="  ")

Print the NBT data in `data`, using `tab` as the tab character. `data` can be an `AbstractDict`, a `Vector`, or a `Pair{String, <:AbstractDict}` (as output by [`read`](@ref)).
"""
function pretty_print(pair::Pair{String, <:AbstractDict}, tab="  ")
  name, data = pair
  if isempty(name)
    println("Unnamed NBT file with ", length(data), " entries:")
  else
    println("NBT file \"", name, "\" with ", length(data), " entries:")
  end
  pretty_print(data, tab)
end

function pretty_print(data::AbstractDict, tab="  ", indent="")
  for (key, value) in data
    if value isa AbstractDict
      println(indent, key, ": {")
      pretty_print(value, tab, indent * tab)
      println(indent, "}")
    elseif value isa Union{Vector{<:AbstractDict}, Vector{Vector}}
      println(indent, key, ": [")
      pretty_print(value, tab, indent * tab)
      println(indent, "]")
    elseif value isa Union{UInt8, Vector, String}
      print(indent, key, ": ")
      show(value)
      println()
    else
      println(indent, key, " (", typeof(value), "): ", value)
    end
  end
end

function pretty_print(data::Vector, tab="  ", indent="")
  for value in data
    if value isa AbstractDict
      println(indent, "{")
      pretty_print(value, tab, indent * tab)
      println(indent, "}")
    else
      println(indent, "[")
      pretty_print(value, tab, indent * tab)
      println(indent, "]")
    end
  end
end

end
