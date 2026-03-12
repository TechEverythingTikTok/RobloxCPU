local CPU = require(game:GetService("ReplicatedStorage")
    :WaitForChild("Shared"):WaitForChild("CPU"):WaitForChild("CPU")    
)
local Instructions = require(game:GetService("ReplicatedStorage")
    :WaitForChild("Shared"):WaitForChild("CPU"):WaitForChild("Instructions")
)

local Registers = require(game:GetService("ReplicatedStorage")
    :WaitForChild("Shared"):WaitForChild("CPU"):WaitForChild("Registers")
)

local Memory = require(game:GetService("ReplicatedStorage")
    :WaitForChild("Shared"):WaitForChild("Memory"):WaitForChild("Memory")
)

Memory.writeu8(0x00, Instructions.L_MOVI)
Memory.writeu8(0x01, Registers.R0)
Memory.writeu8(0x02, 0)
Memory.writeu8(0x03, 0)
Memory.writeu32(0x04, 0x14)   -- addr of rect drawing loop

Memory.writeu8(0x08, Instructions.L_MOVI)
Memory.writeu8(0x09, Registers.R1)
Memory.writeu8(0x0A, 0)
Memory.writeu8(0x0B, 0)
Memory.writeu32(0x0C, 0xFFFF)   -- framebuffer addr

Memory.writeu8(0x10, Instructions.SET_FB_ADDR)
Memory.writeu8(0x11, Registers.R1)
Memory.writeu8(0x12, 0)
Memory.writeu8(0x13, 0)

-- first rect (white)
Memory.writeu8(0x14, Instructions.L_FBDRAW_RECTI)
Memory.writeu8(0x15, 0)
Memory.writeu8(0x16, 0)
Memory.writeu8(0x17, 0)
Memory.writeu16(0x18, 0)  -- x coord of left corner
Memory.writeu16(0x1A, 0)  -- y coord of left corner
Memory.writeu32(0x1C, 0xFFFFFFFF)   -- color white
Memory.writeu16(0x20, 800)  -- x size
Memory.writeu16(0x22, 600)  -- y size

-- seccond rect (black)
Memory.writeu8(0x24, Instructions.L_FBDRAW_RECTI)
Memory.writeu8(0x25, 0)
Memory.writeu8(0x26, 0)
Memory.writeu8(0x27, 0)
Memory.writeu16(0x28, 0)  -- x coord of left corner
Memory.writeu16(0x2A, 0)  -- y coord of left corner
Memory.writeu32(0x2C, 0x00000000)   -- color black
Memory.writeu16(0x30, 800)  -- x size
Memory.writeu16(0x32, 600)  -- y size

-- loop back to drawing
Memory.writeu8(0x34, Instructions.JMP)
Memory.writeu8(0x35, Registers.R0)
Memory.writeu8(0x36, 0)
Memory.writeu8(0x37, 0)

CPU.SetRunTrue()

task.spawn(function()
    CPU.FDE()
end)

task.wait(10)

CPU.SetRunFalse()

return 1