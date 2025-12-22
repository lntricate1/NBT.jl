using NBT
using Test
using LazyArtifacts
using Aqua
using GZip: open

Aqua.test_all(NBT)

@testset "NBT.jl" begin
  rootdir = artifact"litematics"
  for f ∈ readdir(rootdir)
    print(f)
    f = joinpath(rootdir, f)
    lasttime = time()

    io = IOBuffer()
    tag = NBT.read(f)
    bytecount = NBT.write_nbt_uncompressed(io, tag)
    bytes = take!(io)
    newfile = tempname()
    write(newfile, tag)

    @test length(bytes) == bytecount # Check if write returns the right number
    @test bytes == open(read, f) # Check if the uncompressed bytes match
    @test hash(tag) == hash(NBT.read(newfile)) # Compare hash

    println(" (", round(1000(time() - lasttime); digits=2), "ms)")
  end
end
