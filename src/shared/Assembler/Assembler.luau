--WIP!
local Lexer = require("./Lexer")
local Parser = require("./Parser")

function AssembleCode(code: string): buffer | nil
    local tokens: {Lexer.Token} = Lexer.Tokenize(code)
    local intermediate: {Parser.Intermediate} = Parser.Parse(tokens)
    
    return nil
end

return AssembleCode