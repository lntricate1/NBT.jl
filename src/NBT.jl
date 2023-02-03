module NBT

using GZip: open
export Tag, read_nbt, read_nbt_uncompressed

struct Tag
  name::Union{String, Nothing}
  data::Any
end

"""
    read_nbt(filename::String)

Parses an NBT file into a tree of nested `Tag` objects, each of which contains a `name` and `data`.
"""
function read_nbt(filename::String)::Tag
  read_nbt_uncompressed(open(filename))
end

"""
    read_nbt_uncompressed(io::io)

Parses an uncompressed NBT file into a tree of nested `Tag` objects, each of which contains a `name` and `data`.
"""
function read_nbt_uncompressed(stream::IO)::Tag
  _read_tag(read(stream, UInt8), stream)
end

function _read_tag(id::UInt8, stream::IO; skipname::Bool=false)::Tag
  types = (Int8, Int16, Int32, Int64, Float32, Float64,
    Int8, nothing, nothing, nothing, Int32, Int64)
  if id == 0x0
    return Tag(nothing, nothing)
  else
    name = ""
    if !skipname
      namelength = ntoh(read(stream, UInt16))
      for _ ∈ 1:namelength
        name *= read(stream, Char)
      end
    end

    if id < 0x7 # Singletons
      return Tag(name, bswap(read(stream, types[id])))

    elseif id == 0x7 || id == 0xb || id == 0xc # Arrays
      size = ntoh(read(stream, Int32))
      return Tag(name, [read(stream, types[id]) for _ ∈ 1:size])

    elseif id == 0x8 # String
      size = ntoh(read(stream, UInt16))
      string = ""
      for _ ∈ 1:size string *= read(stream, Char) end
      return Tag(name, string)

    elseif id == 0x9 # Tag list
      contentsid = read(stream, UInt8)
      size = ntoh(read(stream, Int32))
      return Tag(name, [_read_tag(contentsid, stream; skipname=true) for _ ∈ 1:size])

    elseif id == 0xa # Compound
      tags = Tag[]
      while true
        tag = _read_tag(read(stream, UInt8), stream)
        push!(tags, tag)
        if tag.name === nothing break end
      end
      return Tag(name, tags)

    else throw(error("invalid tag id ($id); file may be corrupt"))
    end
  end
end

end
