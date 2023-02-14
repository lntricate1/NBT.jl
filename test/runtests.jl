using Test
using NBT
using Aqua
using GZip: open

Aqua.test_all(NBT)

@testset "NBT.jl" begin
  files = readdir("schematics")

  function test1()
    for f ∈ files
      io = IOBuffer()
      write(io, read_nbt("schematics/" * f))
      a = take!(io) != open(read, "schematics/" * f)
      println(f, ", ", a)
      if a
        return false
      end
    end
    return true
  end
  @test test1()

  @test hash(read_nbt("schematics/xd.litematic")) == 0x0da2fb0dc1b40a7f
  @test hash(read_nbt("schematics/peepee alignment.litematic")) == 0x7323f76519897493
  @test hash(read_nbt("schematics/lamp_big.litematic")) == 0xb8969d8855c126b1

  @test hash(get_tags(read_nbt("schematics/xd.litematic"), 0x9)) == 0xc34a74db0052bb44
  @test hash(get_tags(read_nbt("schematics/xd.litematic"), "")) == 0x87fb1ce558228142

  @test (tag = read_nbt("schematics/peepee alignment.litematic"); tag[0x3] === get_tags(tag, 0x3; depth=1)[1])
  @test (tag = read_nbt("schematics/peepee alignment.litematic"); tag["Version"] === get_tags(tag, "Version"; depth=1)[1])
end
