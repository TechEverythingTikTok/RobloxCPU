--!optimize 2
--!native
local CPU = {}

CPU[0x00] 	= 0	-- R0
CPU[0x01]	= 0 -- R1
CPU[0x02]	= 0 -- R2
CPU[0x03]	= 0 -- R3
CPU[0x04]	= 0 -- R4
CPU[0x05]	= 0 -- R5
CPU[0x06]	= 0 -- R6
CPU[0x07]	= 0 -- R7
CPU[0x08]	= 0 -- R8
CPU[0x09]	= 0 -- R9
CPU[0x0A]	= 0 -- R10
CPU[0x0B]	= 0 -- R11
CPU[0x0C]	= 0 -- R12
CPU[0x0D]	= 0 -- R13
CPU[0x0E]	= 0 -- R14
CPU[0x0F]	= 0 -- R15
CPU[0x10]	= 0 -- RSP
CPU[0x11]	= 0	-- RFLAGS
-- Bit 7 = Carry
-- Bit 6 = Zero
-- Bit 5 = Overflow
-- Bit 4 = Negative
CPU[0x12]	= 0 -- RPC
CPU[0x13]	= 0 -- RITA	(Register Interrupt Table Address)
CPU[0x14]	= 0	-- ITF (Interrupt Flag)
CPU[0x15]	= 0	-- RR (Register Reserved)
CPU.Cycles 	= 0

local Running = false

function CPU.SetRunTrue()
	Running = true
end

function CPU.SetRunFalse()
	Running = false
end

function CPU.GetRunning()
	return Running
end

local RegisterSize = 0xFFFFFFFF

local MemModule = require("../Memory/Memory")
local Instructions = require("./Instructions")
local Framebuffer = require("../GPU/Framebuffer")

local MemorySize = MemModule.MemorySize
local Memory = MemModule.Memory

table.freeze(Instructions)

local readu8 = buffer.readu8
local writeu8 = buffer.writeu8
local readu16 = buffer.readu16
local writeu16 = buffer.writeu16
local readu32 = buffer.readu32
local writeu32 = buffer.writeu32
--local readf32 = buffer.readf32
--local writef32 = buffer.writef32
--local readf64 = buffer.readf64
--local writef64 = buffer.writef64

local band = bit32.band
local bor = bit32.bor
local bxor = bit32.bxor
local bnot = bit32.bnot
local lshift = bit32.lshift
local rshift = bit32.rshift

local floor = math.floor

local Dispatch = {}
Dispatch[Instructions.NOP] = function()
	-- No operation
end

Dispatch[Instructions.ADD] = function(reg1: number, reg2: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end
	
	local flags = 0
	local a = CPU[reg1]
	local b = CPU[reg2]

	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end

	local raw = a + b
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.ADDI] = function(reg1: number, imm_lower: number, imm_upper: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end
	
	local a = CPU[reg1]
	
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end
	
	imm_lower = band(imm_lower, 0xFF)
	imm_upper = band(imm_upper, 0xFF)
	
	local b = bor(lshift(imm_upper, 8), imm_lower)
	local flags = 0

	local raw = a + b
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.MOV] = function(reg1: number, reg2: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end
	
	if not CPU[reg1] or not CPU[reg2] then
		Dispatch[Instructions.INT](0)
		return
	end
	
	CPU[reg1] = CPU[reg2]
end

Dispatch[Instructions.MOVI] = function(reg1: number, imm_lower: number, imm_upper: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end
	
	imm_lower = band(imm_lower, 0xFF)
	imm_upper = band(imm_upper, 0xFF)
	
	if not CPU[reg1] then
		Dispatch[Instructions.INT](0)
		return
	end
	
	local imm = bor(lshift(imm_upper, 8), imm_lower)
	
	CPU[reg1] = imm
end

Dispatch[Instructions.LOAD] = function(reg1: number, reg2: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end
	
	local b = CPU[reg2]	-- addr
	
	if not CPU[reg1] or not b then
		Dispatch[Instructions.INT](0)
		return
	end
	
	if b >= MemorySize then
		Dispatch[Instructions.INT](2)
		return
	end
	
	CPU[reg1] = readu32(Memory, b)
end

Dispatch[Instructions.STORE] = function(reg1: number, reg2: number)
	local a = CPU[reg1]	-- addr
	local b = CPU[reg2]	-- value
	
	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end

	if a > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end
	
	if a >= MemorySize then
		Dispatch[Instructions.INT](2)
		return
	end
	
	writeu32(Memory, a, b)
end

Dispatch[Instructions.LUI] = function(reg1: number, imm_lower: number, imm_upper: number)
	imm_lower = band(imm_lower, 0xFF)
	imm_upper = band(imm_upper, 0xFF)
	
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end
	
	if not CPU[reg1] then
		Dispatch[Instructions.INT](0)
		return
	end
	
	local imm = bor(lshift(imm_upper, 24), lshift(imm_lower, 16))
	CPU[reg1] = imm
end

Dispatch[Instructions.LLI] = function(reg1: number, imm_lower: number, imm_upper: number)
	imm_lower = band(imm_lower, 0xFF)
	imm_upper = band(imm_upper, 0xFF)

	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	if not CPU[reg1] then
		Dispatch[Instructions.INT](0)
		return
	end

	local imm = bor(lshift(imm_upper, 8), imm_lower)
	CPU[reg1] = imm
end

Dispatch[Instructions.SUB] = function(reg1: number, reg2: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	local b = CPU[reg2]

	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end

	local raw = a - b
	local result = band(raw, 0xFFFFFFFF)
	
	CPU[reg1] = result
	
	if a < b then
		flags = bor(flags, 0b10000000)
	end
	
	if result == 0 then
		flags = bor(flags, 0b01000000)
	end
	
	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end
	
	local overflow = band(bxor(a, b), bxor(a, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.SUBI] = function(reg1: number, imm_lower: number, imm_upper: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end
	
	imm_lower = band(imm_lower, 0xFF)
	imm_upper = band(imm_upper, 0xFF)

	local b = bor(lshift(imm_upper, 8), imm_lower)
	
	local raw = a - b
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if a < b then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, b), bxor(a, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.MUL] = function(reg1: number, reg2: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	local b = CPU[reg2]

	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end

	local raw = a * b
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end
	
	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.MULI] = function(reg1: number, imm_lower: number, imm_upper: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	imm_lower = band(imm_lower, 0xFF)
	imm_upper = band(imm_upper, 0xFF)

	local b = bor(lshift(imm_upper, 8), imm_lower)
	local flags = 0

	local raw = a * b
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.DIV] = function(reg1: number, reg2: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	local b = CPU[reg2]

	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end
	
	if b == 0 then
		Dispatch[Instructions.INT](3)
		return
	end
	
	local raw = floor(a / b)
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.DIVI] = function(reg1: number, imm_lower: number, imm_upper: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end
	
	imm_lower = band(imm_lower, 0xFF)
	imm_upper = band(imm_upper, 0xFF)

	local b = bor(lshift(imm_upper, 8), imm_lower)
	
	if b == 0 then
		Dispatch[Instructions.INT](3)
		return
	end

	local raw = math.floor(a / b)
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.MOD] = function(reg1: number, reg2: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	local b = CPU[reg2]

	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end
	
	if b == 0 then
		Dispatch[Instructions.INT](3)
		return
	end
	
	local raw = a % b
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.MODI] = function(reg1: number, imm_lower: number, imm_upper: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end
	
	imm_lower = band(imm_lower, 0xFF)
	imm_upper = band(imm_upper, 0xFF)

	local b = bor(lshift(imm_upper, 8), imm_lower)
	
	if b == 0 then
		Dispatch[Instructions.INT](3)
		return
	end

	local raw = a % b
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.CMP] = function(reg1: number, reg2: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	local b = CPU[reg2]

	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end

	local raw = a - b
	local result = band(raw, 0xFFFFFFFF)

	if a < b then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, b), bxor(a, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.CMPI] = function(reg1: number, imm_lower: number, imm_upper: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	imm_lower = band(imm_lower, 0xFF)
	imm_upper = band(imm_upper, 0xFF)

	local b = bor(lshift(imm_upper, 8), imm_lower)

	local raw = a - b
	local result = band(raw, 0xFFFFFFFF)

	if a < b then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, b), bxor(a, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.AND] = function(reg1: number, reg2: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	local b = CPU[reg2]

	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end
	
	local result = band(a, b)
	CPU[reg1] = result
	
	if result == 0 then
		flags = bor(flags, 0b01000000)
	end
	
	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end
	
	CPU[0x11] = flags
end

Dispatch[Instructions.OR] = function(reg1: number, reg2: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	local b = CPU[reg2]

	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end

	local result = bor(a, b)
	CPU[reg1] = result

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.XOR] = function(reg1: number, reg2: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	local b = CPU[reg2]

	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end

	local result = bxor(a, b)
	CPU[reg1] = result

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.NOT] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	local result = band(bnot(a), RegisterSize)
	CPU[reg1] = result

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.SHL] = function(reg1: number, imm8: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	local flags = 0
	local shift = band(imm8, 31)
	
	local result = band(lshift(a, shift), RegisterSize)
	
	CPU[reg1] = result

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.SHR] = function(reg1: number, imm8: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end
	
	local flags = 0
	
	local shift = band(imm8, 31)
	local result = rshift(a, shift)

	CPU[reg1] = band(result, 0xFFFFFFFF)
	
	if result == 0 then
		flags = bor(flags, 0b01000000)
	end
	
	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.JMP] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end
	
	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end
	
	CPU[0x12] = a
end

Dispatch[Instructions.JE] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end
	
	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end
	
	if band(CPU[0x11], 0b01000000) ~= 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.JNE] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b01000000) == 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.JC] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b10000000) ~= 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.JNC] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b10000000) == 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.JN] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b00010000) ~= 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.JNN] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b00010000) == 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.JO] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b00100000) ~= 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.JNO] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b00100000) == 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.JI] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if CPU[0x14] ~= 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.JNI] = function(reg1: number)
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if CPU[0x14] == 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.CLC] = function()
	CPU[0x11] = band(CPU[0x11], 0b01111111)
end

Dispatch[Instructions.CLE] = function()
	CPU[0x11] = band(CPU[0x11], 0b10111111)
end

Dispatch[Instructions.CLO] = function()
	CPU[0x11] = band(CPU[0x11], 0b11011111)
end

Dispatch[Instructions.CLN] = function()
	CPU[0x11] = band(CPU[0x11], 0b11101111)
end

Dispatch[Instructions.CLI] = function()
	CPU[0x14] = 0
end

Dispatch[Instructions.STC] = function()
	CPU[0x11] = bor(CPU[0x11], 0b10000000)
end

Dispatch[Instructions.STE] = function()
	CPU[0x11] = bor(CPU[0x11], 0b01000000)
end

Dispatch[Instructions.STO] = function()
	CPU[0x11] = bor(CPU[0x11], 0b00100000)
end

Dispatch[Instructions.STN] = function()
	CPU[0x11] = bor(CPU[0x11], 0b00010000)
end

Dispatch[Instructions.STI] = function()
	CPU[0x14] = 1
end

Dispatch[Instructions.PUSH] = function(reg1: number)
	local sp = CPU[0x10]
	
	sp -= 4
	
	if sp < 0 then
		Dispatch[Instructions.INT](4)
		return
	end
	
	if not CPU[reg1] then
		Dispatch[Instructions.INT](0)
		return
	end
	
	writeu32(Memory, sp, CPU[reg1])
	
	CPU[0x10] = sp
end

Dispatch[Instructions.POP] = function(reg1: number)
	local sp = CPU[0x10]
	
	if not CPU[reg1] then
		Dispatch[Instructions.INT](0)
		return
	end
	
	if sp >= MemorySize then
		Dispatch[Instructions.INT](5)
		return
	end
	
	local value = readu32(Memory, sp)
	
	sp += 4
	
	CPU[0x10] = sp
	CPU[reg1] = value
end

Dispatch[Instructions.PUSHA] = function()
	local PUSH = Dispatch[Instructions.PUSH]
	for reg_num = 0x00, 0x0F do
		PUSH(reg_num)
	end
end

Dispatch[Instructions.POPA] = function()
	local POP = Dispatch[Instructions.POP]
	for reg_num = 0x0F, 0x00, -1 do
		POP(reg_num)
	end
end

Dispatch[Instructions.CALL] = function(reg1: number)
	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end
	
	if a >= MemorySize then
		Dispatch[Instructions.INT](2)
		return
	end
	
	Dispatch[Instructions.PUSH](0x12)
	
	CPU[0x12] = a
end

Dispatch[Instructions.RET] = function()
	Dispatch[Instructions.POP](0x12)
end


Dispatch[Instructions.SET_FB_ADDR] = function(reg1: number)
	local a = CPU[reg1]
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if a >= MemorySize then
		Dispatch[Instructions.INT](2)
		return
	end

	MemModule.FramebufferAddress = a
end

Dispatch[Instructions.FBDRAW_PIXEL] = function(reg1: number, reg2: number)
	local a = CPU[reg1]
	local b = CPU[reg2]
	
	local pos_x = band(a, 0xFFFF)
	local pos_y = band(rshift(a, 8), 0xFFFF)
	
	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end
	
	local calc = MemModule.FramebufferAddress + ((pos_y * Framebuffer.WIDTH + pos_x) * 4)
	
	if calc > MemorySize then
		Dispatch[Instructions.INT](2)
		return
	end
	
	writeu32(Memory, calc, b)
	Framebuffer.Dirty = true
end

Dispatch[Instructions.FBDRAW_RECT] = function(reg1: number, reg2: number, reg3: number)
	local width = Framebuffer.WIDTH
	
	local a = CPU[reg1]
	local color = CPU[reg2]
	local c = CPU[reg3]
	
	if not a or not color or not c then
		Dispatch[Instructions.INT](0)
		return
	end
	
	local x_coord = band(a, 0xFFFF)
	local y_coord = band(rshift(a, 8), 0xFFFF)
	local size_x = band(c, 0xFFFF)
	local size_y = band(rshift(c, 8), 0xFFFF)
	
	for y = y_coord, y_coord + size_y - 1 do
		local row = (y * width) * 4
		for x = x_coord, x_coord + size_x - 1 do
			local region = row + x * 4
			writeu32(Memory, MemModule.FramebufferAddress + region, color)
		end
	end
	task.wait()
	Framebuffer.Dirty = true
end

Dispatch[Instructions.FBDRAW_LINE] = function(reg1: number, reg2: number, reg3: number)
	local width = Framebuffer.WIDTH
	
	local a = CPU[reg1]
	local length = CPU[reg2]
	local color = CPU[reg3]
	
	if not a or not length or not color then
		Dispatch[Instructions.INT](0)
		return
	end
	
	local x_coord = band(reg1, 0xFFFF)
	local y_coord = band(rshift(reg1, 8), 0xFFFF)

	local row = y_coord * width

	for x = x_coord, x_coord + length - 1 do
		local region = (row + x) * 4
		writeu32(Memory, MemModule.FramebufferAddress + region, color)
	end
	Framebuffer.Dirty = true
end

Dispatch[Instructions.L_FBDRAW_PIXELI] = function()
	local pc = CPU[0x12]

	local pos_x = readu16(Memory, pc)
	local pos_y = readu16(Memory, pc + 2)
	local color = readu32(Memory, pc + 4)

	CPU[0x12] = pc + 8

	writeu32(Memory, MemModule.FramebufferAddress + ((pos_y * Framebuffer.WIDTH + pos_x) * 4), color)
	Framebuffer.Dirty = true
end

Dispatch[Instructions.L_FBDRAW_RECTI] = function()
	local width = Framebuffer.WIDTH
	local pc = CPU[0x12]
	
	local x_coord = readu16(Memory, pc)
	local y_coord = readu16(Memory, pc + 2)
	local color = readu32(Memory, pc + 4)
	local size_x = readu16(Memory, pc + 8)
	local size_y = readu16(Memory, pc + 10)
	
	CPU[0x12] = pc + 12
	
	for y = y_coord, y_coord + size_y - 1 do
		local row = (y * width) * 4
		for x = x_coord, x_coord + size_x - 1 do
			local region = row + x * 4
			writeu32(Memory, MemModule.FramebufferAddress + region, color)
		end
	end
	task.wait()
	Framebuffer.Dirty = true
end

Dispatch[Instructions.L_FBDRAW_LINEI] = function()
	local width = Framebuffer.WIDTH
	local pc = CPU[0x12]
	
	local x_coord = readu16(Memory, pc)
	local y_coord = readu16(Memory, pc + 2)
	local length = readu16(Memory, pc + 4)
	local color = readu32(Memory, pc + 6)
	
	CPU[0x12] = pc + 10
	
	local row = y_coord * width
	
	for x = x_coord, x_coord + length - 1 do
		local region = (row + x) * 4
		writeu32(Memory, MemModule.FramebufferAddress + region, color)
	end
	Framebuffer.Dirty = true
end

Dispatch[Instructions.L_ADDI] = function(reg1: number)
	local pc = CPU[0x12]
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	local b = readu32(Memory, pc)
	CPU[0x12] = pc + 4
	
	local flags = 0

	local raw = a + b
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.L_MOVI] = function(reg1: number)
	local pc = CPU[0x12]
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	if not CPU[reg1] then
		Dispatch[Instructions.INT](0)
		return
	end

	local imm = readu32(Memory, pc)
	CPU[0x12] = pc + 4

	CPU[reg1] = imm
end

Dispatch[Instructions.L_SUBI] = function(reg1: number)
	local pc = CPU[0x12]
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	local b = readu32(Memory, pc)
	CPU[0x12] = pc + 4

	local raw = a - b
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if a < b then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, b), bxor(a, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.L_MULI] = function(reg1: number)
	local pc = CPU[0x12]
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local a = CPU[reg1]

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	local b = readu32(Memory, pc)
	CPU[0x12] = pc + 4
	local flags = 0
	
	local raw = a * b
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.L_DIVI] = function(reg1: number)
	local pc = CPU[0x12]
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	local b = readu32(Memory, pc)
	CPU[0x12] = pc + 4

	if b == 0 then
		Dispatch[Instructions.INT](3)
		return
	end

	local raw = math.floor(a / b)
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.L_MODI] = function(reg1: number)
	local pc = CPU[0x12]
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	local b = readu32(Memory, pc)
	CPU[0x12] = pc + 4

	if b == 0 then
		Dispatch[Instructions.INT](3)
		return
	end

	local raw = a % b
	local result = band(raw, 0xFFFFFFFF)

	CPU[reg1] = result

	if raw > RegisterSize then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, result), bxor(b, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.L_LOADI] = function(reg1: number)
	local pc = CPU[0x12]
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	if not CPU[reg1] then
		Dispatch[Instructions.INT](0)
		return
	end
	
	local b = readu32(Memory, pc)
	CPU[0x12] = pc + 4
	
	if b >= MemorySize then
		Dispatch[Instructions.INT](2)
		return
	end

	CPU[reg1] = readu32(Memory, b)
end

Dispatch[Instructions.L_STOREI] = function(reg1: number)
	local pc = CPU[0x12]
	local a = CPU[reg1]	-- addr
	local b = readu32(Memory, pc)
	CPU[0x12] = pc + 4
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if a > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	if a >= MemorySize then
		Dispatch[Instructions.INT](2)
		return
	end	

	writeu32(Memory, a, b)
end

Dispatch[Instructions.L_CMPI] = function(reg1: number)
	local pc = CPU[0x12]
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end
	
	local b = readu32(Memory, pc)
	CPU[0x12] = pc + 4

	local raw = a - b
	local result = band(raw, 0xFFFFFFFF)

	if a < b then
		flags = bor(flags, 0b10000000)
	end

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	local overflow = band(bxor(a, b), bxor(a, result))
	if band(overflow, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00100000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.L_ANDI] = function(reg1: number)
	local pc = CPU[0x12]
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	local b = readu32(Memory, pc)
	CPU[0x12] = pc + 4

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	local result = band(a, b)
	CPU[reg1] = result

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.L_ORI] = function(reg1: number)
	local pc = CPU[0x12]
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	local b = readu32(Memory, pc)
	CPU[0x12] = pc + 4

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	local result = bor(a, b)
	CPU[reg1] = result

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.L_XORI] = function(reg1: number)
	local pc = CPU[0x12]
	if reg1 > 0x10 then
		Dispatch[Instructions.INT](2)
		return
	end

	local flags = 0
	local a = CPU[reg1]
	local b = readu32(Memory, pc)
	CPU[0x12] = pc + 4

	if not a or not b then
		Dispatch[Instructions.INT](0)
		return
	end

	local result = bxor(a, b)
	CPU[reg1] = result

	if result == 0 then
		flags = bor(flags, 0b01000000)
	end

	if band(result, 0x80000000) ~= 0 then
		flags = bor(flags, 0b00010000)
	end

	CPU[0x11] = flags
end

Dispatch[Instructions.L_JMPI] = function()
	local a = readu32(Memory, CPU[0x12])
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	CPU[0x12] = a
end

Dispatch[Instructions.L_JEI] = function()
	local a = readu32(Memory, CPU[0x12])
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b01000000) ~= 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.L_JNEI] = function()
	local a = readu32(Memory, CPU[0x12])
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b01000000) == 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.L_JCI] = function()
	local a = readu32(Memory, CPU[0x12])
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b10000000) ~= 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.L_JNCI] = function()
	local a = readu32(Memory, CPU[0x12])
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b10000000) == 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.L_JNI] = function()
	local a = readu32(Memory, CPU[0x12])
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b00010000) ~= 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.L_JNNI] = function()
	local a = readu32(Memory, CPU[0x12])
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b00010000) == 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.L_JOI] = function()
	local a = readu32(Memory, CPU[0x12])
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b00100000) ~= 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.L_JNOI] = function()
	local a = readu32(Memory, CPU[0x12])
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if band(CPU[0x11], 0b00100000) == 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.L_JII] = function()
	local a = readu32(Memory, CPU[0x12])
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if CPU[0x14] ~= 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.L_JNII] = function()
	local a = readu32(Memory, CPU[0x12])
	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if CPU[0x14] == 0 then
		CPU[0x12] = a
	end
end

Dispatch[Instructions.INT] = function(imm8: number) -- int_no
	imm8 = band(imm8, 0xFF)
	-- 0 = Invalid Register
	-- 1 = Invalid Instruction
	-- 2 = General Protection
	-- 3 = DBZ
	-- 4 = Stack Overflow
	-- 5 = Stack Underflow
	-- 6-10 = Hardware interrupts
	-- 11-255 = Software interrupts
	if CPU[0x14] ~= 0 then
		if CPU[0x13] == 0 then
			-- We can consider a triple fault since address hasn't been loaded
			Running = false
			return
		end

		CPU[0x15] = imm8
		-- Dispatch[Instructions.CALL](0x13)
		-- Dispatch[Instructions.PUSHA]()
		-- Dispatch[Instructions.PUSH](0x10)
		-- Dispatch[Instructions.PUSH](0x15)

		Dispatch[Instructions.PUSHA]()
		Dispatch[Instructions.PUSH](0x10)
		Dispatch[Instructions.PUSH](0x15)
		Dispatch[Instructions.CALL](0x13)
	end
end

Dispatch[Instructions.IRET] = function()
	Dispatch[Instructions.RET]()
	Dispatch[Instructions.POP](0x15)
	Dispatch[Instructions.POP](0x10)
	Dispatch[Instructions.POPA]()
end

Dispatch[Instructions.LITA] = function(reg1: number)
	local a = CPU[reg1]

	if not a then
		Dispatch[Instructions.INT](0)
		return
	end

	if a > MemorySize then
		Dispatch[Instructions.INT](2)
		return
	end

	CPU[0x13] = a
end

function CPU.FDE()
	local cycle_count = 0

	local Dispatch_tbl = Dispatch
	local readu32_fn = readu32
	local band_fn = band
	local rshift_fn = rshift
	
	while Running == true do
		for i = 1, 3200 do
			local pc = CPU[0x12]
			if not Running then break end
			if pc + 4 >= MemorySize then
				warn("Out of bounds")
				return
			end
			local chunk = readu32_fn(Memory, pc)
			
			-- 0b11100110_10101110_10101110_10101111 (Ignore, for understanding purposes)
			-- Instruction Code = last 8 bits 
			-- other 3 arguments = first 24 bits (8-8-8)
			
			CPU[0x12] += 4
			
			local instruction = band_fn(chunk, 0xFF)
			local arg1 = band_fn(rshift_fn(chunk, 8), 0xFF)
			local arg2 = band_fn(rshift_fn(chunk, 16), 0xFF)
			local arg3 = band_fn(rshift_fn(chunk, 24), 0xFF)
			
			local op = Dispatch_tbl[instruction]
			
			if not op then
				Dispatch_tbl[Instructions.INT](1)
			else
				op(arg1, arg2, arg3)
			end

			cycle_count += 1
		end
		task.wait()
	end

	CPU.Cycles = cycle_count
end

return CPU