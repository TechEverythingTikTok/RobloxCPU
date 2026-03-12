--WIP!
local Lexer = {}

local TokenType = {
    Mnemonic = 1,
    Register = 2,
    Digit = 3,
    Label = 4,
    Punct = 5
}

export type Token = {
    _type: number,
    _content: string
}

local Mnemonics = {
    NOP = true,
	ADD = true,
	ADDI = true,
	MOV = true,
	MOVI = true,
	LOAD = true,
	STORE = true,
	LUI = true,	-- Load Upper Immediate
	LLI = true,	-- Load Lower Immediate
	SUB = true,
	SUBI = true,
	MUL = true,
	MULI = true,
	DIV = true,
	DIVI = true,
	CMP = true,
	CMPI = true,
	AND = true,
	OR = true,
	XOR = true,
	NOT = true,
	SHL = true,
	SHR = true,
	JMP = true,
	JE = true,
	JZ = true,
	JNE = true,
	JNZ = true,
	JC = true,
	JNC = true,
	JN = true,
	JNN = true,
	JO = true,
	JNO = true,
	JI = true,
	JNI = true,
	CLE = true,
	CLZ = true,
	CLC = true,
	CLN = true,
	CLO = true,
	CLI = true,
	STE = true,
	STZ = true,
	STC = true,
	STN = true,
	STO = true,
	STI = true,
	PUSH = true,
	POP = true,
	PUSHA = true,
	POPA = true,
	CALL = true,
	RET = true,
	IRET = true,
	INT = true,
	LITA = true,
	MOD = true,
	MODI = true
}

local RegisterOperands = {
    R0 = true,
    R1 = true,
    R2 = true,
    R3 = true,
    R4 = true,
    R5 = true,
    R6 = true,
    R7 = true,
    R8 = true,
    R9 = true,
    R10 = true,
    R11 = true,
    R12 = true,
    R13 = true,
    R14 = true,
    R15 = true,
    RSP = true,
    RFLAGS = true,
    RITA = true
}

local States = {
    Identifier = 1,
    Digit = 2,
    None = 3
}
table.freeze(States)

function Lexer.Tokenize(code: string): {Token}
    local TokenTable = {}

    local i = 1
    local build = ""

    local State = States.None

    while i <= code:len() do
        local c: string = code:sub(i, i)

        if c:match("%a") then
            if State == States.None then
                State = States.Identifier
            elseif State == States.Digit then
                if not c:match("%x") and c ~= "b" then
                    error("Attempt to tokenize initialized digit with literals after")
                end
            end
            build = build..c
        elseif c:match("%d") then
            if State == States.None then
                State = States.Digit
            end
            build = build..c
        elseif c:match("%s") or c:match("%p") then
            local token_type = 0

            if Mnemonics[build] then
                token_type = TokenType.Mnemonic
            elseif RegisterOperands[build] then
                token_type = TokenType.Register
            else
                if State == States.Identifier then
                    token_type = TokenType.Label
                elseif State == States.Digit then
                    token_type = TokenType.Digit
                else
                    error("Cannot continue tokenizing code, invalid state")
                end
            end

            table.insert(TokenTable, {
                _type = token_type,
                _content = build
            })

            State = States.None
            build = ""

            if c:match("%p") then
                table.insert(TokenTable, {
                    _type = TokenType.Punct,
                    _content = c
                })
            end
        else
            error("Cannot continue tokenizing code, invalid character")
        end

        i += 1
    end

    if build ~= "" then
        local token_type = 0

        if Mnemonics[build] then
            token_type = TokenType.Mnemonic
        elseif RegisterOperands[build] then
            token_type = TokenType.Register
        else
            if State == States.Identifier then
                token_type = TokenType.Label
            elseif State == States.Digit then
                token_type = TokenType.Digit
            else
                error("Cannot continue tokenizing code, invalid state")
            end
        end

        table.insert(TokenTable, {
            _type = token_type,
            _content = build
        })
    end

    return TokenTable
end

return Lexer