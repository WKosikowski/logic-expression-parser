//
//  Lexer.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 26/10/2024.
//

struct Lexer {
    private let validSymbols: String
    private var nextTokenIndex: String.Index
    private var input: String

    init(
        validSymbols: String =
            "abcdefghijklomnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890*+()",  // list of allowed characters usable in the Lexer.
        input: String
    ) {
        self.validSymbols = validSymbols
        self.input = input
        self.nextTokenIndex = self.input.startIndex  // used in nextToken(). it is the index of the current character being tokenized.
    }

    private var inStack: String = ""

    mutating
        func nextToken() -> Token?  // takes the charater at self.nextTokenIndex from self.input and returns it as a token
    {

        var token: Token? = nil  // created token to be returned

        while token == nil {
            guard self.nextTokenIndex < self.input.endIndex else {
                return makeOperand()
            }

            let char = input[nextTokenIndex]

            switch char {
            case "+", "*", "~":  // operator
                token =
                    makeOperand()
                    ?? Token(value: String(char), type: TokenType.Operator)
            case "=":  // equals
                token =
                    makeOperand()
                    ?? Token(value: String(char), type: TokenType.Equal)
            case "(":  // bracket open
                token =
                    makeOperand()
                    ?? Token(value: String(char), type: TokenType.BracketOpen)
            case ")":  // bracket close
                token =
                    makeOperand()
                    ?? Token(value: String(char), type: TokenType.BracketClose)
            default:  // operand
                if validSymbols.contains(char) {  // valid character
                    inStack += String(char)
                    nextTokenIndex = input.index(after: nextTokenIndex)
                } else {  // invalid character
                    token =
                        makeOperand()
                        ?? Token(value: String(char), type: TokenType.Invalid)
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
