using NBT
using Test
using LazyArtifacts
using Aqua
using BufferedStreams, CodecZlib, OrderedCollections

Aqua.test_all(NBT)

@testset "NBT.jl" begin
  rootdir = artifact"litematics"
  for f ∈ readdir(rootdir)
    print(f)
    f = joinpath(rootdir, f)
    lasttime = time()

    io = IOBuffer()
    parsed_data = NBT.read(f)
    bytecount = NBT.write_uncompressed(io, parsed_data)
    bytes = take!(io)
    newfile = tempname()
    NBT.write(newfile, parsed_data)


    # Check if write returns the right number
    @test length(bytes) == bytecount# 
    # Check if the uncompressed bytes match
    @test bytes == open(io -> read(GzipDecompressorStream(io)), f)
    # Compare hash
    @test hash(parsed_data) == hash(NBT.read(newfile))

    println(" (", round(1000(time() - lasttime); digits=2), "ms)")
  end
end
