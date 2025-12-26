```@meta
CurrentModule = NBT
```

# NBT.jl

[NBT.jl](https://github.com/lntricate1/NBT.jl) is a Julia package for reading and writing [Minecraft NBT files](https://minecraft.wiki/w/NBT_format#Binary_format). The main reading and writing methods convert the NBT file into corresponding Julia types and back.

## NBT object - Julia object equivalence

| Byte | NBT object | Julia object produced| Julia objects accepted                       |
| ---- | ---------- | ---------------------| -------------------------------------------- |
| `01` | Byte       | `UInt8`              | `UInt8`                                      |
| `02` | Short      | `Int16`              | `Int16`                                      |
| `03` | Int        | `Int32`              | `Int32`                                      |
| `04` | Long       | `Int64`              | `Int64`                                      |
| `05` | Float      | `Float32`            | `Float32`                                    |
| `06` | Double     | `Float64`            | `Float64`                                    |
| `07` | Byte Array | `Vector{Int8}`       | `Vector{Int8}`                               |
| `08` | String     | `String`             | `String`                                     |
| `09` | List       | `Vector{T}`          | `Vector{T}`                                  |
| `0a` | Compound   | `LittleDict{String}` | `AbstractDict{String}` or `Nothing` if empty |
| `0b` | Int Array  | `Vector{Int32}`      | `Vector{Int32}`                              |
| `0c` | Long Array | `Vector{Int64}`      | `Vector{Int64}`                              |

### Edge cases

- When reading an empty NBT list with element type `0`, NBT.jl produces `Any[]`. Similarly writing `Any[]` will produce an empty NBT list with element type `0`.
- When reading an NBT list with element type `03` or `04`, NBT.jl produces `Int32[]` and `Int64[]` respectively. Trying to write this back into an NBT file will produce a tag of type `0b` and `0c` respectively. Note that this doesn't affect lists of element type `01` since those produce `UInt8[]`, which is distinct from the `Int8[]` produced by tags of type `07`.

## Reading

The main way to read an NBT file is to use [`NBT.read`](@ref). The main method takes a filename and returns a pair `name => data`. NBT files always consist of a single Compound tag filled with other tags, but the main outer tag is almost always unnamed, so typically [`NBT.read`](@ref) will output `"" => LittleDict(...)` and it's necessary to access the right element to get the data.

NBT files are almost always compressed with GZip, but rarely aren't. To read NBT data from an uncompressed file, there is [`NBT.read_uncompressed`](@ref) which works in the same way as [`NBT.read`](@ref). Both functions can also take an `IO` instead of a filename.

```@docs
NBT.read
```

```@docs
NBT.read_uncompressed
```

```julia-repl
julia> T = NBT.read("/home/intricate/mc/instances/1.17.1/minecraft/saves/New World/level.dat")
"" => OrderedCollections.LittleDict{String, Any, Vector{String}, Vector{Any}}("Data" => OrderedCollections.LittleDict{String, Any, Vector{String}, Vector{Any}}("WanderingTraderSpawnChance" => 25, "BorderCenterZ" => 0.0, "Difficulty" => 0x00, "BorderSizeLerpTime" => 0, "raining" => 0x00, "Time" => 265, "GameType" => 1, "ServerBrands" => ["fabric"], "BorderCenterX" => 0.0, "BorderDamagePerBlock" => 0.2…))

julia> T[2]
OrderedCollections.LittleDict{String, Any, Vector{String}, Vector{Any}} with 1 entry:
  "Data" => LittleDict{String, Any, Vector{String}, Vector{Any}}("WanderingTraderSpawnChance"=…

julia> T[2]["Data"]
OrderedCollections.LittleDict{String, Any, Vector{String}, Vector{Any}} with 42 entries:
  "WanderingTraderSpawnChance" => 25
  "BorderCenterZ"              => 0.0
  "Difficulty"                 => 0x00
  "BorderSizeLerpTime"         => 0
  "raining"                    => 0x00
  "Time"                       => 265
  "GameType"                   => 1
  "ServerBrands"               => ["fabric"]
  "BorderCenterX"              => 0.0
  "BorderDamagePerBlock"       => 0.2
  "BorderWarningBlocks"        => 5.0
  "WorldGenSettings"           => LittleDict{String, Any, Vector{String}, Vector{Any}}("bonus_…
  "DragonFight"                => LittleDict{String, Any, Vector{String}, Vector{Any}}("NeedsS…
  "BorderSizeLerpTarget"       => 6.0e7
  "Version"                    => LittleDict{String, Any, Vector{String}, Vector{Any}}("Snapsh…
  "DayTime"                    => 265
  "initialized"                => 0x01
  "WasModded"                  => 0x01
  "allowCommands"              => 0x01
  "WanderingTraderSpawnDelay"  => 24000
  "CustomBossEvents"           => LittleDict{String, Any, Vector{String}, Vector{Any}}()
  "GameRules"                  => LittleDict{String, Any, Vector{String}, Vector{Any}}("doFire…
  "Player"                     => LittleDict{String, Any, Vector{String}, Vector{Any}}("Brain"…
  "SpawnY"                     => 1
  "rainTime"                   => 169707
  "thunderTime"                => 123751
  "SpawnZ"                     => 8
  "hardcore"                   => 0x00
  "DifficultyLocked"           => 0x00
  "SpawnX"                     => 8
  "clearWeatherTime"           => 0
  "thundering"                 => 0x00
  "SpawnAngle"                 => 0.0
  "version"                    => 19133
  "BorderSafeZone"             => 5.0
  "LastPlayed"                 => 1766296821236
  "BorderWarningTime"          => 15.0
  "ScheduledEvents"            => Any[]
  "LevelName"                  => "New World2"
  "BorderSize"                 => 6.0e7
  "DataVersion"                => 2730
  "DataPacks"                  => LittleDict{String, Any, Vector{String}, Vector{Any}}("Enable…
```

For convenience, `NBT.jl` provides the [`NBT.pretty_print`](@ref) function for printing the read data into the REPL. However, note that this will dump the **entire** file which may be very large.

```@docs
NBT.pretty_print
```

```julia-repl
julia> NBT.pretty_print(T)
Unnamed NBT file with 1 entries:
Data: {
  WanderingTraderSpawnChance (Int32): 25
  BorderCenterZ (Float64): 0.0
  Difficulty: 0x00
  BorderSizeLerpTime (Int64): 0
  raining: 0x00
  Time (Int64): 265
  GameType (Int32): 1
  ServerBrands: ["fabric"]
  BorderCenterX (Float64): 0.0
  BorderDamagePerBlock (Float64): 0.2
  BorderWarningBlocks (Float64): 5.0
  WorldGenSettings: {
    bonus_chest: 0x00
    seed (Int64): -7293489413437051478
    generate_features: 0x01
    dimensions: {
      minecraft:overworld: {
        generator: {
          settings: "minecraft:overworld"
          seed (Int64): -7293489413437051478
          biome_source: {
            seed (Int64): -7293489413437051478
            large_biomes: 0x00
            type: "minecraft:vanilla_layered"
          }
          type: "minecraft:noise"
        }
        type: "minecraft:overworld"
      }
      # [I'm cutting it off here to save space]
```

## Writing

Writing works basically the same as reading. There is [`NBT.write`](@ref) which takes a filename and a `name => data` pair, and writes the data to the file. Similarly there is [`NBT.write_uncompressed`](@ref) for skipping compression.

```@docs
NBT.write
```

```@docs
NBT.write_uncompressed
```

## Advanced writing

Sometimes you have existing data you want written to an NBT file, but it is not already in a nested `Dict` format, and converting would be an unnecessary intermediate step. To avoid having to convert the data to a specific format before writing, `NBT.jl` provides some lower-level writing functions. The main method is [`NBT.write_tag`](@ref):

```@docs
NBT.write_tag
```

This function can take a pair `name => data`, or just `data`. The first method is intended for writing entries in a Compound tag, and the second for writing entries in a List tag. Combining [`NBT.write_tag`](@ref) with [`NBT.begin_nbt_file`](@ref), [`NBT.end_nbt_file`](@ref), [`NBT.begin_compound`](@ref), [`NBT.end_compound`](@ref), [`NBT.begin_list`](@ref), and [`NBT.end_list`](@ref), you can build an NBT file manually. Here is an example of how this can be used, taken from [`Litematica.jl`](https://github.com/lntricate1/litematica.jl):

```julia
function Base.write(io::IO, litematic::Litematic)
  s, bytes = begin_nbt_file(io)
  bytes += write_tag(s, "MinecraftDataVersion" => litematic.data_version)
  bytes += write_tag(s, "Version" => Int32(5))
  bytes += write_tag(s, "Metadata" => litematic.metadata)
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

```@docs
NBT.begin_nbt_file
```
```@docs
NBT.end_nbt_file
```
```@docs
NBT.begin_compound
```
```@docs
NBT.end_compound
```
```@docs
NBT.begin_list
```
```@docs
NBT.end_list
```

# Index

```@index
```
