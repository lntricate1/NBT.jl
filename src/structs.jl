# """
#     struct TagCompound{T}
#
# Represents an NBT compound tag, containing an array of Pairs name => data. See [minecraft wiki](https://minecraft.wiki/NBT_format).
#
# # Properties
# - `data::Vector{Pair{String, T}}`: The data in the tag.
# """
# struct TagCompound{T}
#   data::Vector{Pair{String, T}}
# end
#
# TagCompound() = TagCompound(Pair{String, Int8}[])

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

# Base.isequal(x::TagCompound, y::TagCompound) = x.data == y.data
Base.isequal(x::TagList, y::TagList) = x.data == y.data
# Base.:(==)(x::TagCompound, y::TagCompound) = x.data == y.data
Base.:(==)(x::TagList, y::TagList) = x.data == y.data
# Base.hash(x::TagCompound, h::UInt) = hash(x.data, hash(:TagCompound, h))
Base.hash(x::TagList, h::UInt) = hash(x.data, hash(:TagCompound, h))
# Base.sizeof(t::TagCompound) = sizeof(t.data)
Base.sizeof(t::TagList) = sizeof(t.data)
# Base.length(t::TagCompound) = length(t.data)
Base.length(t::TagList) = length(t.data)

# function Base.getindex(tag::TagCompound{T}, name::String) where T
#   for t in tag.data
#     t.first == name && return t.second
#   end
# end
#
# function Base.setindex!(tag::TagCompound{T}, newtag::T, name::String) where T
#   for i ∈ eachindex(tag.data)
#     tag.data[i].first == name && return tag.data[i] = name => newtag
#   end
#   return name => newtag
# end
#
# Base.getindex(::TagCompound{T}, ::Integer) where T =
#   throw(ArgumentError("NBT Compound tags do not have a consistent order. Use a String for indexing instead"))
# Base.setindex(::TagCompound{T}, ::T, ::Integer) where T =
#   throw(ArgumentError("NBT Compound tags do not have a consistent order. Use a String for indexing instead"))

function Base.getindex(tag::TagList{T}, i::Integer) where T
  return tag.data[i]
end

function Base.setindex!(tag::TagList{T}, newtag, i::Integer) where T
  return tag.data[i] = newtag
end
