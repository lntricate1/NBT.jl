using Test
using LazyArtifacts
using NBT
using Aqua
using GZip: open

Aqua.test_all(NBT)

@testset "NBT.jl" begin
  rootdir = artifact"litematics"
  for f ∈ readdir(rootdir)
    println(f)
    f = joinpath(rootdir, f)
    io = IOBuffer()
    tag = read(f, Tag)
    bytecount = NBT.write_nbt_uncompressed(io, tag)
    bytes = take!(io)
    newfile = tempname()
    write(newfile, tag)

    @test length(bytes) == bytecount # Check if write returns the right number
    @test bytes == open(read, f) # Check if the uncompressed bytes match
    @test hash(tag) == hash(read(newfile, Tag)) # Compare hash

    # Compare hash after get_tags
    @test hash(get_tags(tag, 0x9)) == hash(get_tags(read(newfile, Tag), 0x9))
    @test hash(get_tags(tag, "x")) == hash(get_tags(read(newfile, Tag), "x"))
    @test (t = get_tags(tag, 0x3, depth=1);
      tag[0x3] === (length(t) == 0 ? nothing : first(t)))
    @test (t = get_tags(tag, "Version", depth=1);
      tag["Version"] === (length(t) == 0 ? nothing : first(t)))
  end
end
