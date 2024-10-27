//
//  Test.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 25/10/2024.
//

@testable import LeXParser
import Testing

@Suite("Lexer")
struct OperandTests{

    
    @Test("Basic operandTests",
          arguments: [
            TestData(input: "A", output: [Token(value: "A", type: TokenType.Operand)]),
            TestData(input: "B", output: [Token(value: "B", type: TokenType.Operand)]),
            TestData(input: "C", output: [Token(value: "C", type: TokenType.Operand)]),
            TestData(input: "X", output: [Token(value: "X", type: TokenType.Operand)]),
            TestData(input: "ABC", output: [Token(value: "ABC", type: TokenType.Operand)]),
            TestData(input: "Wojtek", output: [Token(value: "Wojtek", type: TokenType.Operand)]),
            TestData(input: "Kosikowski", output: [Token(value: "Kosikowski", type: TokenType.Operand)]),
            TestData(input: "Input1", output: [Token(value: "Input1", type: TokenType.Operand)]),
            TestData(input: "Input122", output: [Token(value: "Input122", type: TokenType.Operand)])
          ])
    func testLexerSimpleOperand(data: TestData)  {
        
        var lexer = Lexer(input: data.input)
        let token = lexer.allTokens()
        
        #expect(token.count == 1)
        #expect(token[0].value == data.output[0].value)
        #expect(token[0].type == data.output[0].type)
    }

    @Test("Basic operandTests",
          arguments: [
            TestData(input: "!", output: [Token(value: "!", type: TokenType.Invalid)]),
            TestData(input: "@", output: [Token(value: "@", type: TokenType.Invalid)]),
            TestData(input: "£", output: [Token(value: "£", type: TokenType.Invalid)]),
            TestData(input: "\\", output: [Token(value: "\\", type: TokenType.Invalid)]),
            TestData(input: "&", output: [Token(value: "&", type: TokenType.Invalid)]),
            TestData(input: "^", output: [Token(value: "^", type: TokenType.Invalid)]),
            TestData(input: "\"", output: [Token(value: "\"", type: TokenType.Invalid)]),
            TestData(input: "[", output: [Token(value: "[", type: TokenType.Invalid)]),
            TestData(input: "/", output: [Token(value: "/", type: TokenType.Invalid)])
          ])
    func testLexerSimpleOperandWithInvalidInput(input: TestData) {
        var lexer = Lexer(input: input.input)
        let token = lexer.allTokens()
        
        #expect(token.count == 1)
        #expect(token[0].type == input.output[0].type)
    }
    
    @Test(
"complex expressions",
          arguments: [
            TestData(
                input: "A*B",
                output: [
                    Token(value: "A", type: TokenType.Operand),
                    Token(value: "*", type: TokenType.Operator),
                    Token(value: "B", type: TokenType.Operand)
                ]
            ),
            TestData(
                input: "A+B",
                output: [
                    Token(value: "A", type: TokenType.Operand),
                    Token(value: "+", type: TokenType.Operator),
                    Token(value: "B", type: TokenType.Operand)
                ]
            ),
            TestData(
                input: "A*B+C",
                output: [
                    Token(value: "A", type: TokenType.Operand),
                    Token(value: "*", type: TokenType.Operator),
                    Token(value: "B", type: TokenType.Operand),
                    Token(value: "+", type: TokenType.Operator),
                    Token(value: "C", type: TokenType.Operand)
                ]
            ),
            TestData(
                input: "F=(A*BB+C)",
                output: [
                    Token(value: "F", type: TokenType.Operand),
                    Token(value: "=", type: TokenType.Equal),
                    Token(value: "(", type: TokenType.BracketOpen),
                    Token(value: "A", type: TokenType.Operand),
                    Token(value: "*", type: TokenType.Operator),
                    Token(value: "BB", type: TokenType.Operand),
                    Token(value: "+", type: TokenType.Operator),
                    Token(value: "C", type: TokenType.Operand),
                    Token(value: ")", type: TokenType.BracketClose),
                ]
            )
          ]
)
    func testLexerComplexExpressions(input: TestData) {
        var lexer = Lexer(input: input.input)
        let token = lexer.allTokens()
        print(token)
        #expect(token.count == input.output.count)
        
    }
    
    @Test("invalid complex expressions",
          arguments: [
            TestData(
                input: "A!B",
                output: [
                    Token(value: "A", type: TokenType.Operand),
                    Token(value: "!", type: TokenType.Invalid),
                    Token(value: "B", type: TokenType.Operand)
                ]
            ),
            TestData(
                input: "A!B*C",
                output: [
                    Token(value: "A", type: TokenType.Operand),
                    Token(value: "!", type: TokenType.Invalid),
                    Token(value: "B", type: TokenType.Operand),
                    Token(value: "*", type: TokenType.Operator),
                    Token(value: "C", type: TokenType.Operand)
                ]
            ),
            TestData(
                input: "A@B£",
                output: [
                    Token(value: "A", type: TokenType.Operand),
                    Token(value: "@", type: TokenType.Invalid),
                    Token(value: "B", type: TokenType.Operand),
                    Token(value: "£", type: TokenType.Invalid)
                ]
            ),
            TestData(
                input: "A~(D@ )",
                output: [
                    Token(value: "A", type: TokenType.Operand),
                    Token(value: "~", type: TokenType.Invalid),
                    Token(value: "(", type: TokenType.BracketOpen),
                    Token(value: "D", type: TokenType.Operand),
                    Token(value: "@", type: TokenType.Invalid),
                    Token(value: " ", type: TokenType.Invalid),
                    Token(value: ")", type: TokenType.BracketClose)
                ]
            ),
            TestData(
                input: "A!B@B|]F",
                output: [
                    Token(value: "A", type: TokenType.Operand),
                    Token(value: "!", type: TokenType.Invalid),
                    Token(value: "B", type: TokenType.Operand),
                    Token(value: "@", type: TokenType.Invalid),
                    Token(value: "B", type: TokenType.Operand),
                    Token(value: "|", type: TokenType.Invalid),
                    Token(value: "]", type: TokenType.Invalid),
                    Token(value: "F", type: TokenType.Operand)
                ]
            ),
            TestData(
                input: "FB@£^6",
                output: [
                    Token(value: "FB", type: TokenType.Operand),
                    Token(value: "@", type: TokenType.Invalid),
                    Token(value: "£", type: TokenType.Invalid),
                    Token(value: "^", type: TokenType.Invalid),
                    Token(value: "6", type: TokenType.Operand),
                ]
            )
          ])
    func testLexerInvalidComplexExpressions(input: TestData) {
        var lexer = Lexer(input: input.input)
        let token = lexer.allTokens()
        print(token)
        #expect(token.count == input.output.count)
        
    }

}


struct TestData: Sendable {
    let input: String
    let output: [Token]
}

extension Lexer {
    mutating
    func allTokens() -> [Token] {
        var tokens: [Token] = []
        while let token = nextToken() {
            tokens.append(token)
        }
        return tokens
    }
}
