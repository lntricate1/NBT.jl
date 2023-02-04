using NBT
using GZip: open
using Test

@testset "NBT.jl" begin
  @test hash(string(read_nbt("./xd.litematic"))) == 0x67ce6d2ade66fa3e
  @test hash(string(read_nbt("./peepee alignment.litematic"))) == 0x2d031b25729fa18d
  @test hash(string(read_nbt("./lamp_big.litematic"))) == 0x7d8ee08d40304a7a
  @test take!(write_nbt_uncompressed(read_nbt("./xd.litematic"))) == read(open("./xd.litematic"))
  @test take!(write_nbt_uncompressed(read_nbt("./peepee alignment.litematic"))) == read(open("./peepee alignment.litematic"))
  @test take!(write_nbt_uncompressed(read_nbt("./lamp_big.litematic"))) == read(open("./lamp_big.litematic"))
end
