module NBT

using GZip: open
export Tag, read_nbt, read_nbt_uncompressed, write_nbt, write_nbt_uncompressed

struct Tag{T}
  id::UInt8
  name::String
  data::T
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

"""
    write_nbt(filename::String)

Parses a tree of nested `Tag` objects, each of which contains a `name` and `data`, into an NBT file.
"""
function write_nbt(filename::String, tag::Tag)::IO
  stream = open(filename)
  _write_tag(tag, stream)
  return stream
end

"""
    write_nbt_uncompressed(io::io)

Parses a tree of nested `Tag` objects, each of which contains a `name` and `data`, into an uncompressed NBT file.
"""
function write_nbt_uncompressed(tag::Tag)::IO
  stream = IOBuffer();
  _write_tag(tag, stream)
  return stream
end

function _read_tag(id::UInt8, stream::IO; skipname::Bool=false)::Tag
  types = (Int8, Int16, Int32, Int64, Float32, Float64, Int8, nothing, nothing, nothing, Int32, Int64)
  name = ""
  if !skipname
    namelength = ntoh(read(stream, UInt16))
    for _ ∈ 1:namelength
      name *= read(stream, Char)
    end
  end

  if id < 0x7 # Singletons
    return Tag(id, name, ntoh(read(stream, types[id])))

  elseif id == 0x7 || id == 0xb || id == 0xc # Arrays
    size = ntoh(read(stream, Int32))
    return Tag(id, name, types[id][ntoh(read(stream, types[id])) for _ ∈ 1:size])

  elseif id == 0x8 # String
    size = ntoh(read(stream, UInt16))
    string = ""
    for _ ∈ 1:size string *= read(stream, Char) end
    return Tag(id, name, string)

  elseif id == 0x9 # Tag list
    contentsid = read(stream, UInt8)
    size = ntoh(read(stream, Int32))
    if contentsid == 0x0 return Tag(id, name, Tag[]) end
    return Tag(id, name, Tag[_read_tag(contentsid, stream; skipname=true) for _ ∈ 1:size])

  elseif id == 0xa # Compound
    tags = Tag[]
    while true
      contentsid = read(stream, UInt8)
      if contentsid == 0x0 break end
      push!(tags, _read_tag(contentsid, stream))
    end
    return Tag(id, name, tags)

  else throw(error("invalid tag id ($id); file may be corrupt"))
  end
end

function _write_tag(tag::Tag, stream::IO; skipname::Bool=false)
  if !skipname
    write(stream, tag.id)
    write(stream, hton(Int16(length(tag.name))))
    for c ∈ tag.name write(stream, c) end
  end

  if tag.id < 0x7
    write(stream, hton(tag.data))

  elseif tag.id == 0x7 || tag.id == 0xb || tag.id == 0xc
    write(stream, hton(Int32(length(tag.data))))
    for n ∈ tag.data write(stream, hton(n)) end

  elseif tag.id == 0x8
    write(stream, hton(UInt16(length(tag.data))))
    for c ∈ tag.data write(stream, c) end

  elseif tag.id == 0x9
    write(stream, length(tag.data) > 0x0 ? first(tag.data).id : 0x0)
    write(stream, hton(Int32(length(tag.data))))
    for t ∈ tag.data
      _write_tag(t, stream; skipname = true)
    end

  elseif tag.id == 0xa
    for t ∈ tag.data
      _write_tag(t, stream)
    end
    write(stream, 0x0)

  else
    throw(error("invalid tag id ($(tag.id)); tags may be corrupt"))
  end
end

function Base.show(io::IO, tag::Tag)
  _show(io, tag)
end

function _show(io::IO, tag::Tag; indent::String="")
  print(io, indent *
    ("Byte ", "Int16 ", "Int32 ", "Int64 ", "Float32 ", "Float64 ", "Byte[] ", "String ", "Tag[] ", "Tag[] ", "Int32[] ", "Int64[] ")[tag.id] *
    (tag.name == "" ? "(unnamed)" : tag.name) * ":")

  if tag.id < 0x7 || tag.id == 0x8
    println(io, " " * string(tag.data))

  else
    print(io, "\n")
    if tag.id == 0x7 || tag.id == 0xb || tag.id == 0xc
      for i ∈ eachindex(tag.data)
        println(io, indent * "▏ " * string(tag.data[i]))
        if i > 10
          println(io, indent * "▏ ...")
          break
        end
      end

    elseif tag.id == 0x9 || tag.id == 0xa
      for i ∈ eachindex(tag.data)
        _show(io, tag.data[i]; indent=indent * "▏ ")
        if i > 10
          println(io, indent * "▏ ...")
          break
        end
      end
    end
  end
end

end
