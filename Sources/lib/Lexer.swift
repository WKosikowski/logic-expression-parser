//
//  Lexer.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 26/10/2024.
//



struct Lexer {
    private let  validSymbols: String
    private var nextTokenIndex: String.Index
    private var input: String
    
    init(validSymbols: String = "abcdefghijklomnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890*+()", input: String) {
        self.validSymbols = validSymbols
        self.input = input
        self.nextTokenIndex = self.input.startIndex
    }
    
    private var inStack: String = ""
    
    mutating
    func nextToken() -> Token? {
        
        var token: Token? = nil
        
        while token == nil {
            guard self.nextTokenIndex < self.input.endIndex else {
                return makeOperand()
            }
            
            let char = input[nextTokenIndex]
            
            switch char {
                case "+","*","~":
                    token = makeOperand() ?? Token(value: String(char), type: TokenType.Operator)
                case "=":
                    token = makeOperand() ?? Token(value: String(char), type: TokenType.Equal)
                case "(":
                    token = makeOperand() ??  Token(value: String(char), type: TokenType.BracketOpen)
                case ")":
                    token =  makeOperand() ?? Token(value: String(char), type: TokenType.BracketClose)
                default:
                    if validSymbols.contains(char) {
                        inStack += String(char)
                        nextTokenIndex = input.index(after: nextTokenIndex)
                    }
                    else{
                        token = makeOperand() ??  Token(value: String(char), type: TokenType.Invalid)
                    }
            }
            
        }
        
        self.nextTokenIndex = self.input.index(after: nextTokenIndex)
        return token
    }
    
    mutating
    private func makeOperand() -> Token? {
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
