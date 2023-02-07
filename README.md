# NBT.jl

| **Build Status**                        | **Quality**                     |
|:---------------------------------------:|:-------------------------------:|
| [![Build Status][build-img]][build-url] | [![Aqua QA][aqua-img]][aqua-url]|

NBT.jl is a Julia package for reading and writing Minecraft .nbt files, including .litematic files.

DONE: NBT reading, NBT writing, printing, get tag by id, get tag by name.

TODO:
  - Conversion to blockstate matrix: Decide if it should go here or in a different package.

## Examples
```julia
julia> using NBT

julia> t = read_nbt("~/1.16.5/saves/cmp3/level.dat")
Tag[] (unnamed):
▏ Tag[] Data:
▏ ▏ Int32 WanderingTraderSpawnChance: 75
▏ ▏ Float64 BorderCenterZ: 0.0
▏ ▏ Byte Difficulty: 3
▏ ▏ Int64 BorderSizeLerpTime: 0
▏ ▏ Byte raining: 0
▏ ▏ Int64 Time: 1155557106
▏ ▏ Int32 GameType: 1
▏ ▏ Tag[] ServerBrands:
▏ ▏ ▏ String (unnamed): fabric
▏ ▏ Float64 BorderCenterX: 0.0
▏ ▏ Float64 BorderDamagePerBlock: 26.0
▏ ▏ Float64 BorderWarningBlocks: 5.0
▏ ▏ ...


julia> write_nbt("./nbtfile.dat", t)
GZipStream(./nbtfile.dat (closed))
```

[build-img]: https://github.com/lntricate1/NBT.jl/actions/workflows/ci_unit.yml/badge.svg
[build-url]: https://github.com/lntricate1/NBT.jl/actions/workflows/ci_unit.yml

[aqua-img]: https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl
