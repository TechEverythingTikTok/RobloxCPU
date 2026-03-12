local Memory = {}

Memory.MemorySize = 67_108_864
Memory.Memory = buffer.create(Memory.MemorySize)
Memory.FramebufferAddress = 0

function Memory.writeu8(addr, val)
    buffer.writeu8(Memory.Memory, addr, val)
end

function Memory.writeu16(addr, val)
    buffer.writeu16(Memory.Memory, addr, val)
end

function Memory.writeu32(addr, val)
    buffer.writeu32(Memory.Memory, addr, val)
end

function Memory.readu8(addr)
    return buffer.readu8(Memory.Memory, addr)
end

function Memory.readu16(addr)
    return buffer.readu16(Memory.Memory, addr)
end

function Memory.readu32(addr)
    return buffer.readu32(Memory.Memory, addr)
end

return Memory