local CPU = require("@game/ReplicatedStorage/Shared/CPU/CPU")
local Instructions = require("@game/ReplicatedStorage/Shared/CPU/Instructions")
local Registers = require("@game/ReplicatedStorage/Shared/CPU/Registers")
local Memory = require("@game/ReplicatedStorage/Shared/Memory/Memory")

local Framebuffer = require("@game/ReplicatedStorage/Shared/GPU/Framebuffer")

Memory.writeu8(0x00, Instructions.L_MOVI)
Memory.writeu8(0x01, Registers.R2)
Memory.writeu16(0x02, 0)
Memory.writeu32(0x04, 0xFFFF)

Memory.writeu8(0x08, Instructions.SET_FB_ADDR)
Memory.writeu8(0x09, Registers.R2)
Memory.writeu16(0x0A, 0)

Memory.writeu8(0x0C, Instructions.L_FBDRAW_RECTI)
Memory.writeu8(0x0D, 0)
Memory.writeu16(0x0E, 0)
Memory.writeu16(0x10, 0)
Memory.writeu16(0x12, 0)
Memory.writeu32(0x14, 0xFF0000FF)
Memory.writeu16(0x18, Framebuffer.WIDTH)
Memory.writeu16(0x1A, Framebuffer.HEIGHT)

Memory.writeu8(0x1C, Instructions.WAIT)
Memory.writeu8(0x1D, 10)
Memory.writeu16(0x1E, 0)

Memory.writeu8(0x20, Instructions.L_FBDRAW_RECTI)
Memory.writeu8(0x21, 0)
Memory.writeu16(0x22, 0)
Memory.writeu16(0x24, 0)
Memory.writeu16(0x26, 0)
Memory.writeu32(0x28, 0xFF00FF00)
Memory.writeu16(0x2C, Framebuffer.WIDTH)
Memory.writeu16(0x2E, Framebuffer.HEIGHT)

Memory.writeu8(0x30, Instructions.WAIT)
Memory.writeu8(0x31, 10)
Memory.writeu16(0x32, 0)

Memory.writeu8(0x34, Instructions.L_FBDRAW_RECTI)
Memory.writeu8(0x35, 0)
Memory.writeu16(0x36, 0)
Memory.writeu16(0x38, 0)
Memory.writeu16(0x3A, 0)
Memory.writeu32(0x3C, 0xFFFF0000)
Memory.writeu16(0x40, Framebuffer.WIDTH)
Memory.writeu16(0x42, Framebuffer.HEIGHT)

Memory.writeu8(0x44, Instructions.WAIT)
Memory.writeu8(0x45, 10)
Memory.writeu16(0x46, 0)

Memory.writeu8(0x48, Instructions.L_JMPI)
Memory.writeu8(0x49, 0)
Memory.writeu16(0x4A, 0)
Memory.writeu32(0x4C, 0x0C)

CPU.SetRunTrue()

CPU.FDE()
