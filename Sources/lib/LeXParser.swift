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

public struct Parser {
    public init() {}
    public func parse(input: String) throws -> Formula {
        var lexer = Lexer(input: input)
        var previousTokenType: TokenType?  // used to check if syntax is correct.
        var index = -1
        var bracketLevel = 0  // how many brackets were opened or closed at index. should never go below 0.
        var tokens: [Token] = []

        while let token = lexer.nextToken() {
            tokens.append(token)
            index += 1
            if token.type == TokenType.Invalid {  // invalid token
                throw ParserError.invalidSyntax(
                    index: index,
                    message:
                        "\"\(token.value)\" character at position \(index) is not allowed."
                )
            }

            if index > 1 {  // expression part of formula
                if token.type == TokenType.BracketOpen {
                    bracketLevel += 1
                }
                if token.type == TokenType.BracketClose {
                    bracketLevel -= 1
                }
                if bracketLevel < 0 {  // no bracket to close
                    throw ParserError.invalidSyntax(
                        index: index, message: "Premature bracket closure.")
                }
                if token.type == TokenType.Operator  // if an operator token is to the right of to the appropreate token.
                    && previousTokenType != TokenType.Operand
                    && token.value != "~"
                    && previousTokenType != TokenType.BracketClose
                {
                    throw ParserError.invalidSyntax(
                        index: index,
                        message:
                            "Invalid syntax. Only operands and bracket closures allowed in front of a two sided operator."
                    )
                }
                if previousTokenType != TokenType.Operator  // if a bracket opening is to the right of an operator
                    && token.type == TokenType.BracketOpen
                    && previousTokenType != TokenType.Equal
                    && previousTokenType != TokenType.BracketOpen
                {
                    throw ParserError.invalidSyntax(
                        index: index,
                        message:
                            "Invalid syntax. Can only place operators before opening a bracket."
                    )
                }
                if previousTokenType == TokenType.BracketOpen  // if bracket closure is to the right of a bracket opening
                    && token.type == TokenType.BracketClose
                {
                    throw ParserError.invalidSyntax(
                        index: index, message: "Invalid syntax. Empty brackets."
                    )
                }
                if previousTokenType != TokenType.Operand  // if previous token type is not an operand to the left of a bracket closure
                    && previousTokenType != TokenType.BracketClose
                    && token.type == TokenType.BracketClose
                {
                    throw ParserError.invalidSyntax(
                        index: index,
                        message:
                            "Invalid syntax. Only operands allowed before closing a bracket"
                    )
                }
                if previousTokenType == TokenType.Equal  // if token is a two sided operator to the right of an equal sign.
                    && token.type != TokenType.BracketOpen
                    && token.type != TokenType.Operand && token.value != "~"
                {
                    throw ParserError.invalidSyntax(
                        index: index,
                        message:
                            "Invalid syntax. Only operands, opening brackets and negation is allowed after Equal sign."
                    )
                }
            } else {  // output (prefix) part of formula
                if token.type != TokenType.Operand && index == 0 {  // if the first element is not an operand
                    throw ParserError.invalidSyntax(
                        index: index,
                        message:
                            "Invalid syntax. The first element should be an Operand, then an Equal sign, followed by the formula."
                    )
                }
                if token.type != TokenType.Equal && index == 1 {  // if the second element is not an equal sign
                    throw ParserError.invalidSyntax(
                        index: index,
                        message:
                            "Invalid syntax. The first element should be an Operand, then an Equal sign, followed by the formula."
                    )
                }
            }
            previousTokenType = token.type
        }
        if bracketLevel > 0 {  // if any brackets were not closed after iterating through all tokens
            throw
                ParserError
                .invalidSyntax(
                    index: index,
                    message:
                        "Invalid syntax. Brackets were left opened and were never closed."
                )
        }

        return Formula(
            output: tokens[0],
            expression: Array(tokens.suffix(from: 2)),
            value: nil
        )
    }

}
