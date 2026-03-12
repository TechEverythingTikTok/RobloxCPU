local Registers = {}

Registers.R0 	= 0x00	-- R0
Registers.R1	= 0x01 	-- R1
Registers.R2	= 0x02 	-- R2
Registers.R3	= 0x03 	-- R3
Registers.R4	= 0x04 	-- R4
Registers.R5	= 0x05 	-- R5
Registers.R6	= 0x06 	-- R6
Registers.R7	= 0x07 	-- R7
Registers.R8	= 0x08 	-- R8
Registers.R9	= 0x09 	-- R9
Registers.R10	= 0x0A 	-- R10
Registers.R11	= 0x0B 	-- R11
Registers.R12	= 0x0C 	-- R12
Registers.R13	= 0x0D 	-- R13
Registers.R14	= 0x0E 	-- R14
Registers.R15	= 0x0F 	-- R15
Registers.RSP	= 0x10 	-- RSP
Registers.RFLAGS= 0x11	-- RFLAGS
-- Bit 7 = Carry
-- Bit 6 = Zero
-- Bit 5 = Overflow
-- Bit 4 = Negative
Registers.RPC	= 0x12 	-- RPC
Registers.RITA	= 0x13 	-- RITA	(Register Interrupt Table Address)
Registers.RITF	= 0x14	-- RITF (Register Interrupt Flag)

return Registers