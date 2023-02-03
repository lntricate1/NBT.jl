using NBT
using Test

@testset "NBT.jl" begin
  @test hash(string(read_nbt("./xd.litematic"))) == 0x02af95d7ebdd5717
  @test hash(string(read_nbt("./peepee alignment.litematic"))) == 0x4da76d1be9eb5f11
  @test hash(string(read_nbt("./lamp_big.litematic"))) == 0xed0905100fb367a9
end
