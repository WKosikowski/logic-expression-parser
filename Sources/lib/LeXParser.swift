//
//  LeXParser.swift
//  logic-expression-parser
//
//  Created by Wojciech Kosikowski on 25/10/2024.
//



public enum ParserError: Error, Equatable {
    case invalidSyntax(index: Int, message: String)
    case bracketError(message: String) // a to nie jest syntax error?
}


public struct Parser{
    public init() {}
    public func parse(input: String) throws -> [Token]{
        var lexer = Lexer(input: input)
        var previousTokenType: TokenType?
        var index = -1
        var bracketLevel = 0
        var tokens: [Token] = []
        
        while let token = lexer.nextToken() {
            tokens.append(token)
            index += 1
            if token.type == TokenType.Invalid{
                throw ParserError.invalidSyntax(index: index, message: "Invalid syntax. This character is not allowed.")
            }
            if index > 1{
                if token.type == TokenType.BracketOpen{
                    bracketLevel += 1
                }
                if token.type == TokenType.BracketClose{
                    bracketLevel -= 1
                }
                if bracketLevel < 0{
                    throw ParserError.invalidSyntax(index: index, message: "Premature bracket closure.")
                }
                if token.type == TokenType.Operator && (previousTokenType != TokenType.Operand && previousTokenType != TokenType.BracketClose) {
                    throw ParserError.invalidSyntax(index: index, message: "Invalid syntax. Only operands and bracket closures allowed before an operator.")
                }
                if previousTokenType == TokenType.Operator && token.type == TokenType.Operator && token.value != "~"{
                    throw ParserError.invalidSyntax(index: index, message: "Invalid syntax. Can not place two-sided operators net to each other.")
                }
                if previousTokenType != TokenType.Operator && token.type == TokenType.BracketOpen && previousTokenType != TokenType.Equal {
                    throw ParserError.invalidSyntax(index: index, message: "Invalid syntax. Can only place operators before opening a bracket.")
                }
                if previousTokenType == TokenType.BracketOpen && token.type == TokenType.BracketClose {
                    throw ParserError.invalidSyntax(index: index, message: "Invalid syntax. Empty brackets.")
                }
                if previousTokenType != TokenType.Operand && token.type == TokenType.BracketClose {
                    throw ParserError.invalidSyntax(index: index, message: "Invalid syntax. Only operands allowed before closing a bracket")
                }
                if previousTokenType == TokenType.Equal && token.type != TokenType.BracketOpen && token.type != TokenType.Operand && token.value != "~" {
                    throw ParserError.invalidSyntax(index: index, message: "Invalid syntax. Only operands, opening brackets and negation is allowed after Equal sign.")
                }
            }
            else{
                if token.type != TokenType.Operand && index == 0{
                    throw ParserError.invalidSyntax(index: index, message: "Invalid syntax. The first element should be an Operand, then an Equal sign, followed by the formula.")
                }
                if token.type != TokenType.Equal && index == 1{
                    throw ParserError .invalidSyntax(index: index, message: "Invalid syntax. The first element should be an Operand, then an Equal sign, followed by the formula.")
                }
            }
            previousTokenType = token.type
        }
        if bracketLevel != 0{
            throw ParserError.bracketError(message: "Too many or too little brackets.")
        }
        
        return tokens
    }
    
    //    func nextToken() throws -> Token ? {
    //        nil
    //    }
}

