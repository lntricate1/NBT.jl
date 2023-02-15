# NBT.jl

| **Build Status**                        | **Quality**                     |
|:---------------------------------------:|:-------------------------------:|
| [![Build Status][build-img]][build-url] | [![Aqua QA][aqua-img]][aqua-url]|

NBT.jl is a Julia package for reading and writing Minecraft .nbt files, including .litematic files.

## Available Methods

### Base
  - `Base.read(::IO, ::Type{Tag}) -> Tag`
  - `Base.write(::IO, ::Tag) -> Int`
  - `Base.isequal(::Tag, ::Tag) -> Bool`
  - `Base.==(::Tag, ::Tag) -> Bool`
  - `Base.hash(::Tag, ::UInt) -> UInt`
  - `Base.sizeof(::Tag) -> Int`
  - `Base.show(::IO, ::MIME, ::Tag)`
  - `Base.getindex(::Tag, ::String) -> Union{Tag, Nothing}`
  - `Base.getindex(::Tag, ::Integer) -> Union{Tag, Nothing}`
  - `Base.setindex(::Tag, ::Tag, ::String) -> ::Tag`
  - `Base.setindex(::Tag, ::Tag, ::Integer) -> ::Tag`

### Exported
  - `get_tags(::Tag, ::String; depth=10) -> Vector{Tag}`
  - `get_tags(::Tag, ::Integer; depth=10) -> Vector{Tag}`
  - `set_tags(::Tag, ::String, ::Tag; depth=10) -> Tag`
  - `set_tags(::Tag, ::Integer, ::Tag; depth=10) -> Tag`

### Not exported
  - `read_nbt_uncompressed(::IO, ::Type{Tag}) -> Tag`
  - `write_nbt_uncompressed(::IO, ::Tag) -> Int`

## Examples
```julia
julia> using NBT

julia> t = read("/home/intricate/1.16.5/saves/cmp3/level.dat", Tag) # Read a Tag from NBT file
(10) Tag[] (unnamed):
▏ (10) Tag[] Data:
▏ ▏ (3) Int32 WanderingTraderSpawnChance: 75
▏ ▏ (6) Float64 BorderCenterZ: 0.0
▏ ▏ (1) Byte Difficulty: 3
▏ ▏ (4) Int64 BorderSizeLerpTime: 0
▏ ▏ (1) Byte raining: 0
▏ ▏ (4) Int64 Time: 1155557106
▏ ▏ (3) Int32 GameType: 1
▏ ▏ (9) Tag[] ServerBrands:
▏ ▏ ▏ (8) String (unnamed): fabric
▏ ▏ (6) Float64 BorderCenterX: 0.0
▏ ▏ (6) Float64 BorderDamagePerBlock: 26.0
▏ ▏ (6) Float64 BorderWarningBlocks: 5.0
▏ ▏ ...

julia> get_tags(t, "id") # Get all Tags named "id"
9-element Vector{Tag}:
 (8) String id: minecraft:wooden_axe
 (8) String id: minecraft:gray_concrete
 (8) String id: minecraft:light_blue_concrete
 (8) String id: minecraft:light_blue_stained_glass
 (8) String id: minecraft:pink_concrete
 (8) String id: minecraft:observer
 (8) String id: minecraft:note_block
 (8) String id: minecraft:repeater
 (8) String id: minecraft:arrow

julia> t["Data"]["Time"] # Get the Tag root/Data/Time
(4) Int64 Time: 1155557106

julia> get_tags(t, 2) # Get all Tags with id 2 (Int16)
5-element Vector{Tag}:
 (2) Int16 SleepTimer: 0
 (2) Int16 DeathTime: 0
 (2) Int16 Air: 300
 (2) Int16 Fire: 0
 (2) Int16 HurtTime: 0

julia> t["Data"][1] # Get the first tag with id 1 (Byte) inside root/Data
(1) Byte Difficulty: 3

julia> write("./nbtfile.dat", t) # Write tag into NBT file
5653
```

[build-img]: https://github.com/lntricate1/NBT.jl/actions/workflows/ci_unit.yml/badge.svg
[build-url]: https://github.com/lntricate1/NBT.jl/actions/workflows/ci_unit.yml

[aqua-img]: https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl
