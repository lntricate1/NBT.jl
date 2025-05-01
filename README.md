# NBT.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://lntricate1.github.io/NBT.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://lntricate1.github.io/NBT.jl/dev/)
[![Build Status](https://github.com/lntricate1/NBT.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/lntricate1/NBT.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/lntricate1/NBT.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/lntricate1/NBT.jl)

NBT.jl is a Julia package for reading and writing Minecraft .nbt files.

## NBT object - Julia object equivalence

| Byte | NBT object | Julia object produced| Julia objects accepted                                                         |
| ---- | ---------- | ---------------------| ------------------------------------------------------------------------------ |
| `01` | Byte       | `UInt8`              | `UInt8`                                                                        |
| `02` | Short      | `Int16`              | `Int16`                                                                        |
| `03` | Int        | `Int32`              | `Int32`                                                                        |
| `04` | Long       | `Int64`              | `Int64`                                                                        |
| `05` | Float      | `Float32`            | `Float32`                                                                      |
| `06` | Double     | `Float64`            | `Float64`                                                                      |
| `07` | Byte Array | `Vector{Int8}`       | `Vector{Int8}`                                                                 |
| `08` | String     | `String`             | `String`                                                                       |
| `09` | List       | `Vector`             | `Vector` (or `NBT.TagList` if you want a vector of 07, 0b, 0c for some reason) |
| `0a` | Compound   | `LittleDict{String}` | `AbstractDict{String, Any}`                                                    |
| `0b` | Int Array  | `Vector{Int32}`      | `Vector{Int32}`                                                                |
| `0c` | Long Array | `Vector{Int64}`      | `Vector{Int64}`                                                                |

## Examples
```julia
using NBT

# NBT.read and NBT.write are the main read and write methods
T = NBT.read("poop.litematic")
NBT.write("poop_copy.litematic", T)

# More advanced usage: There are also methods for writing directly
# without needing to turn the data into a specific Julia object first
# this runs faster and uses less memory
# here is some example code from Litematica.jl that uses this
function Base.write(io::IO, litematic::Litematic)
  s, bytes = begin_nbt_file(io)
  # write_tag(stream, "name" => data) works within Compound tags
  bytes += write_tag(s, "MinecraftDataVersion" => litematic.data_version)
  bytes += write_tag(s, "Version" => Int32(5))
  bytes += write_tag(s, "Metadata" => litematic.metadata)
  # begin_compound(stream, "name") begins a nested Compound tag
  bytes += begin_compound(s, "Regions")

  for region in litematic.regions
    bytes += begin_compound(s, region.name)
    bytes += write_tag(s, "BlockStates" => CompressedPalettedContainer(_permutedims(region.blocks, (1, 3, 2)), 2).data)
    bytes += write_tag(s, "PendingBlockTicks" => TagList())
    bytes += write_tag(s, "Position" => _writetriple(region.pos))
    bytes += write_tag(s, "BlockStatePalette" => TagList(_Tag.(region.blocks.pool)))
    bytes += write_tag(s, "Size" => _writetriple(Int32.(size(region.blocks))))
    bytes += write_tag(s, "PendingFluidTicks" => TagList())
    bytes += write_tag(s, "TileEntities" => TagList(TagCompound{Any}[t for t in region.tile_entities if t !== nothing]))
    bytes += write_tag(s, "Entities" => TagList())
    bytes += end_compound(s)
  end

  bytes += end_compound(s)
  bytes += end_nbt_file(s)
  return bytes
end
```

[build-img]: https://github.com/lntricate1/NBT.jl/actions/workflows/ci_unit.yml/badge.svg
[build-url]: https://github.com/lntricate1/NBT.jl/actions/workflows/ci_unit.yml

[aqua-img]: https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl
