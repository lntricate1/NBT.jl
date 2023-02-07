using Test
using NBT
using Aqua
using GZip: open

Aqua.test_all(NBT)

@testset "NBT.jl" begin
  @test hash(string(read_nbt("./xd.litematic"))) == 0x4198c7f3a54c5f05
  @test hash(string(read_nbt("./peepee alignment.litematic"))) == 0x91ebeaa40afc6cdd
  @test hash(string(read_nbt("./lamp_big.litematic"))) == 0x2c93af3731fc191e

  @test take!(write_nbt_uncompressed(read_nbt("./xd.litematic"))) == read(open("./xd.litematic"))
  @test take!(write_nbt_uncompressed(read_nbt("./peepee alignment.litematic"))) == read(open("./peepee alignment.litematic"))
  @test take!(write_nbt_uncompressed(read_nbt("./lamp_big.litematic"))) == read(open("./lamp_big.litematic"))

  @test hash(string(get_tags_by_id(read_nbt("/home/intricate/schematics/xd.litematic"), 0x9))) == 0xd1e751f9fb1a96c8
  @test hash(string(get_tags_by_name(read_nbt("/home/intricate/schematics/xd.litematic"), ""))) == 0x9413c9758e9999de
end
