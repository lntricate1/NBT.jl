using Test
using NBT
using Aqua
using GZip: open

Aqua.test_all(NBT)

@testset "NBT.jl" begin
  @test hash(string(read_nbt("./xd.litematic"))) == 0xada1766e6013d8c5
  @test hash(string(read_nbt("./peepee alignment.litematic"))) == 0xfb880b252ee7849a
  @test hash(string(read_nbt("./lamp_big.litematic"))) == 0x20727cb2d2cc2fe0
  @test take!(write_nbt_uncompressed(read_nbt("./xd.litematic"))) == read(open("./xd.litematic"))
  @test take!(write_nbt_uncompressed(read_nbt("./peepee alignment.litematic"))) == read(open("./peepee alignment.litematic"))
  @test take!(write_nbt_uncompressed(read_nbt("./lamp_big.litematic"))) == read(open("./lamp_big.litematic"))
end
