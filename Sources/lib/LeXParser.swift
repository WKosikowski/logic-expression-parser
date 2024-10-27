//
//  LeXParser.swift
//  logic-expression-parser
//
//  Created by Wojciech Kosikowski on 25/10/2024.
//

import Foundation



public enum ParserError: Error, Equatable {
    case invalidSyntax(index: Int, message: String)
}

extension ParserError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
            case let .invalidSyntax(_, message):
                return message
        }
    }
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
                throw ParserError.invalidSyntax(index: index, message: "\"\(token.value)\" character at position \(index) is not allowed.")
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
                if token.type == TokenType.Operator && (previousTokenType != TokenType.Operand && previousTokenType != TokenType.BracketClose && token.value != "~") {
                    throw ParserError.invalidSyntax(index: index, message: "Invalid syntax. Only operands and bracket closures allowed before a two sided operator.")
                }
                if previousTokenType != TokenType.Operator && token.type == TokenType.BracketOpen && previousTokenType != TokenType.Equal && previousTokenType != TokenType.BracketOpen {
                    throw ParserError.invalidSyntax(index: index, message: "Invalid syntax. Can only place operators before opening a bracket.")
                }
                if previousTokenType == TokenType.BracketOpen && token.type == TokenType.BracketClose {
                    throw ParserError.invalidSyntax(index: index, message: "Invalid syntax. Empty brackets.")
                }
                if previousTokenType != TokenType.Operand && previousTokenType != TokenType.BracketClose && token.type == TokenType.BracketClose {
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
        if bracketLevel > 0{
            throw ParserError
                .invalidSyntax(
                    index: index,
                    message: "Invalid syntax. Brackets were left opened and were never closed."
                )
        }
        
        return tokens
    }
    
}

