//
//  Lexer.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 26/10/2024.
//

import Foundation

struct Lexer {
    private let validPattern: NSRegularExpression
    private var nextTokenIndex: String.Index
    private var input: String

    init(
        pattern: String = "[a-zA-Z0-9*+()]",  // Default regex pattern for allowed characters
        input: String
    ) {
        do {
            self.validPattern = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            // Fallback to a very basic pattern if the provided one is invalid
            self.validPattern = try! NSRegularExpression(pattern: "[a-zA-Z0-9]", options: [])
        }
        self.input = input
        self.nextTokenIndex = self.input.startIndex
    }

    private var inStack: String = ""

    mutating func nextToken() -> Token? {
        var token: Token? = nil

        while token == nil {
            guard self.nextTokenIndex < self.input.endIndex else {
                return makeOperand()
            }

            let char = input[nextTokenIndex]

            switch char {
            case "+", "*", "~":  // operator
                token = makeOperand() ?? Token(value: String(char), type: TokenType.Operator)
            case "=":  // equals
                token = makeOperand() ?? Token(value: String(char), type: TokenType.Equal)
            case "(":  // bracket open
                token = makeOperand() ?? Token(value: String(char), type: TokenType.BracketOpen)
            case ")":  // bracket close
                token = makeOperand() ?? Token(value: String(char), type: TokenType.BracketClose)
            default:  // operand
                let charString = String(char)
                let range = NSRange(location: 0, length: charString.utf16.count)
                if validPattern.firstMatch(in: charString, options: [], range: range) != nil {
                    inStack += charString
                    nextTokenIndex = input.index(after: nextTokenIndex)
                } else {  // invalid character
                    token = makeOperand() ?? Token(value: String(char), type: TokenType.Invalid)
                }
            }
        }

        self.nextTokenIndex = self.input.index(after: nextTokenIndex)
        return token
    }

    mutating
        private func makeOperand() -> Token?
    {  // tokenizes the operand
        if !inStack.isEmpty {
            let token = Token(
                value: String(inStack),
                type: TokenType.Operand
            )
            inStack = ""

            if nextTokenIndex < self.input.endIndex {
                nextTokenIndex = input.index(before: nextTokenIndex)
            }
            return token
        }
        return nil
    }
}
