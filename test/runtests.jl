using Test
using NBT
using Aqua
using GZip: open

Aqua.test_all(NBT)

@testset "NBT.jl" begin
  @test hash(read_nbt("xd.litematic")) == 0x0da2fb0dc1b40a7f
  @test hash(read_nbt("peepee alignment.litematic")) == 0x7323f76519897493
  @test hash(read_nbt("lamp_big.litematic")) == 0xb8969d8855c126b1

  @test take!(write_nbt_uncompressed(read_nbt("xd.litematic"))) == read(open("./xd.litematic"))
  @test take!(write_nbt_uncompressed(read_nbt("peepee alignment.litematic"))) == read(open("./peepee alignment.litematic"))
  @test take!(write_nbt_uncompressed(read_nbt("lamp_big.litematic"))) == read(open("./lamp_big.litematic"))

  @test hash(get_tags(read_nbt("xd.litematic"), 0x9)) == 0xc34a74db0052bb44
  @test hash(get_tags(read_nbt("xd.litematic"), "")) == 0x87fb1ce558228142

  @test (tag = read_nbt("peepee alignment.litematic"); tag[0x3] === get_tags(tag, 0x3; depth=1)[1])
  @test (tag = read_nbt("peepee alignment.litematic"); tag["Version"] === get_tags(tag, "Version"; depth=1)[1])
end
