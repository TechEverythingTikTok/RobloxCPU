# General format
> [opcode] [arg1] [arg2] [arg3]

### NOP
> [0x00] [] [] []

### ADD
> [0x01] [Rdest] [Rsrc] []

### ADDI
> [0x02] [Rdest] [imm_lower] [imm_upper]

### MOV
> [0x03] [Rdest] [Rsrc] []

### MOVI
> [0x04] [Rdest] [imm_lower] [imm_upper]

### LOAD
> [0x05] [Rdest] [Raddr] []

### SET_FB_ADDR
> [0x06] [Raddr] [] []

### STORE
> [0x07] [Raddr] [Rval] []

### LUI
> [0x08] [Rdest] [imm_lower] [imm_upper]

### LLI
> [0x09] [Rdest] [imm_lower] [imm_upper]

### SUB
> [0x0A] [Rdest] [Rsrc] []

### SUBI
> [0x0B] [Rdest] [imm_lower] [imm_upper]

### MUL
> [0x0C] [Rdest] [Rsrc] []

### MULI
> [0x0D] [Rdest] [imm_lower] [imm_upper]

### DIV
> [0x0E] [Rdest] [Rsrc] []

### DIVI
> [0x0F] [Rdest] [imm_lower] [imm_upper]

### CMP
> [0x10] [Rsrc1] [Rsrc2] []

### CMPI
> [0x11] [Rsrc] [imm_lower] [imm_upper]

### AND
> [0x12] [Rdest] [Rsrc] []

### OR
> [0x13] [Rdest] [Rsrc] []

### XOR
> [0x14] [Rdest] [Rsrc] []

### NOT
> [0x15] [Rdest] [] []

### SHL
> [0x16] [Rdest] [Rsrc] []

### SHR
> [0x17] [Rdest] [Rsrc] []

### JMP
> [0x18] [Raddr] [] []

### JE
> [0x19] [Raddr] [] []

### JZ
> [0x19] [Raddr] [] []

### JNE
> [0x1A] [Raddr] [] []

### JNZ
> [0x1A] [Raddr] [] []

### JC
> [0x1B] [Raddr] [] []

### JNC
> [0x1C] [Raddr] [] []

### JN
> [0x1D] [Raddr] [] []

### JNN
> [0x1E] [Raddr] [] []

### JO
> [0x1F] [Raddr] [] []

### JNO
> [0x20] [Raddr] [] []

### JI
> [0x21] [Raddr] [] []

### JNI
> [0x22] [Raddr] [] []

### CLE
> [0x23] [] [] []

### CLZ
> [0x23] [] [] []

### CLC
> [0x24] [] [] []

### CLN
> [0x25] [] [] []

### CLO
> [0x26] [] [] []

### CLI
> [0x27] [] [] []

### STE
> [0x28] [] [] []

### STZ
> [0x28] [] [] []

### STC
> [0x29] [] [] []

### STN
> [0x2A] [] [] []

### STO
> [0x2B] [] [] []

### STI
> [0x2C] [] [] []

### PUSH
> [0x2D] [Rsrc] [] []

### POP
> [0x2E] [Rsrc] [] []

### PUSHA
> [0x2F] [] [] []

### POPA
> [0x30] [] [] []

### CALL
> [0x31] [Raddr] [] []

### RET
> [0x32] [] [] []

### IRET
> [0x33] [] [] []

### INT
> [0x34] [imm] [] []

### LITA
> [0x35] [Raddr] [] []

### MOD
> [0x36] [Rdest] [Rsrc] []

### MODI
> [0x37] [Rdest] [imm_lower] [imm_upper]

### L_FBDRAW_PIXELI
> [0x38] [] [] [] [(2b) pos_x] [(2b) pos_y] [(4b) color]

### L_FBDRAW_RECTI
> [0x39] [] [] [] [(2b) x_coord] [(2b) y_coord] [(4b) color] [(2b) size_x] [(2b) size_y]

### L_FBDRAW_LINEI
> [0x3A] [] [] [] [(2b) x_coord] [(2b) y_coord] [(2b) len] [(4b) color]

### FBDRAW_PIXEL
> [0x3B] [Rcoord_xy] [Rcolor] []

### FBDRAW_RECT
> [0x3C] [Rcoord_xy] [Rcolor] [Rsize]

### FBDRAW_LINE
> [0x3D] [Rcoord_xy] [Rlen] [Rcolor]

### L_ADDI
> [0x3E] [Rdest] [] [] [(4b) imm32]

### L_SUBI
> [0x3F] [Rdest] [] [] [(4b) imm32]

### L_MULI
> [0x40] [Rdest] [] [] [(4b) imm32]

### L_DIVI
> [0x41] [Rdest] [] [] [(4b) imm32]

### L_MODI
> [0x42] [Rdest] [] [] [(4b) imm32]

### L_MOVI
> [0x43] [Rdest] [] [] [(4b) imm32]

### L_LOADI
> [0x44] [Rdest] [] [] [(4b) addr]

### L_STOREI
> [0x45] [] [] [] [(4b) addr] [(4b) val]

### L_CMPI
> [0x46] [Rdest] [] [] [(4b) imm32]

### L_ANDI
> [0x47] [Rdest] [] [] [(4b) imm32]

### L_ORI
> [0x48] [Rdest] [] [] [(4b) imm32]

### L_XORI
> [0x49] [Rdest] [] [] [(4b) imm32]

### L_NOTI
> Not implemented, dropped.

> [0x4A] [] [] []

### L_JMPI
> [0x4B] [] [] [] [(4b) addr]

### L_JEI
> [0x4C] [] [] [] [(4b) addr]

### L_JZI
> [0x4D] [] [] [] [(4b) addr]

### L_JNEI
> [0x4E] [] [] [] [(4b) addr]

### L_JNZI
> [0x4F] [] [] [] [(4b) addr]

### L_JCI
> [0x50] [] [] [] [(4b) addr]

### L_JNCI
> [0x51] [] [] [] [(4b) addr]

### L_JNI
> [0x52] [] [] [] [(4b) addr]

### L_JNNI
> [0x53] [] [] [] [(4b) addr]

### L_JOI
> [0x54] [] [] [] [(4b) addr]

### L_JNOI
> [0x55] [] [] [] [(4b) addr]

### L_JII
> [0x56] [] [] [] [(4b) addr]

### L_JNII
> [0x57] [] [] [] [(4b) addr]

### L_FBDRAW_BITMAPI
> To be implemented and decided

> [0x58] [] [] []

### T_ADD
> [0x59] [Rdest] [Rsrc1] [Rsrc2]

### T_SUB
> [0x5A] [Rdest] [Rsrc1] [Rsrc2]

### T_MUL
> [0x5B] [Rdest] [Rsrc1] [Rsrc2]

### T_DIV
> [0x5C] [Rdest] [Rsrc1] [Rsrc2]

### T_MOD
> [0x5D] [Rdest] [Rsrc1] [Rsrc2]

### T_CMP
> [0x5E] [Rdest] [Rsrc1] [Rsrc2]

### T_AND
> [0x5F] [Rdest] [Rsrc1] [Rsrc2]

### T_OR
> [0x60] [Rdest] [Rsrc1] [Rsrc2]

### T_XOR
> [0x61] [Rdest] [Rsrc1] [Rsrc2]