# Normal instruction format
\[opcode\]\[arg1\]\[arg2\]\[arg3\]

### NOP
\[0x00\]\[0x00\]\[0x00\]\[0x00\]

### ADD
\[0x01\]\[Rdest\]\[Rsrc\]\[0x00\]

### SUB
\[0x0A\]\[Rdest\]\[Rsrc\]\[0x00\]

### MUL
\[0x0C\]\[Rdest\]\[Rsrc\]\[0x00\]

### DIV
\[0x0E\]\[Rdest\]\[Rsrc\]\[0x00\]

### MOD
\[0x36\]\[Rdest\]\[Rsrc\]\[0x00\]

### CMP
\[0x10\]\[Rsrc1\]\[Rsrc2\]\[0x00\]

### MOV
\[0x03\]\[Rdest\]\[Rsrc\]\[0x00\]

