using Test
using NBT
using Aqua
using GZip: open

Aqua.test_all(NBT)

@testset "NBT.jl" begin
  files = readdir("schematics"; join=true)
  for f ∈ files
    io = IOBuffer()
    tag = read_nbt(f)
    bytecount = write(io, tag)
    bytes = take!(io)
    newfile = tempname()
    write_nbt(newfile, tag)

    println(f)
    @test length(bytes) == bytecount # Check if write returns the right number
    @test bytes == open(read, f) # Check if the uncompressed bytes match
    @test hash(tag) == hash(read_nbt(newfile)) # Compare hash

    # Compare hash after get_tags
    @test hash(get_tags(tag, 0x9)) == hash(get_tags(read_nbt(newfile), 0x9))
    @test hash(get_tags(tag, "x")) == hash(get_tags(read_nbt(newfile), "x"))
    @test (t = get_tags(tag, 0x3, depth=1);
      tag[0x3] === (length(t) == 0 ? nothing : first(t)))
    @test (t = get_tags(tag, "Version", depth=1);
      tag["Version"] === (length(t) == 0 ? nothing : first(t)))
  end
end
