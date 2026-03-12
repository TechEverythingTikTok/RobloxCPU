--WIP!
local Parser = {}
local Lexer = require("./Lexer")

local Instructions = require("../CPU/Instructions")
local Registers = require("../CPU/Registers")

export type Intermediate = {
    operation: number,
    arguments: {number | nil}
}

function Parser.Parse(tokens: {Lexer.Token}): {Intermediate}
    local IntermediateTable = {}

    

    return IntermediateTable
end

return Parser