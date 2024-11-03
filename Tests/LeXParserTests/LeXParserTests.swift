//
//  Untitled.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 26/10/2024.
//

import Testing

@testable import LeXParser

struct ParserTestData: Sendable {
    let input: String
    let output: [Token]
    let error: ParserError?

    init(input: String, output: [Token], error: ParserError? = nil) {
        self.input = input
        self.output = output
        self.error = error
    }
}

@Suite("Parser")
struct LeXParserTests {
    @Test(
        "Basic Tests",
        arguments: [
            TestData(
                input: "out1=A*B",
                output: [
                    Token(value: "A", type: TokenType.Operand),
                    Token(value: "*", type: TokenType.Operator),
                    Token(value: "B", type: TokenType.Operand),
                ]),
            TestData(
                input: "out1=A*~B",
                output: [
                    Token(value: "A", type: TokenType.Operand),
                    Token(value: "*", type: TokenType.Operator),
                    Token(value: "~", type: TokenType.Operator),
                    Token(value: "B", type: TokenType.Operand),
                ]),
            TestData(
                input: "out1=(Ab*B)",
                output: [
                    Token(value: "(", type: TokenType.BracketOpen),
                    Token(value: "Ab", type: TokenType.Operand),
                    Token(value: "*", type: TokenType.Operator),
                    Token(value: "B", type: TokenType.Operand),
                    Token(value: ")", type: TokenType.BracketClose),
                ]),
            TestData(
                input: "out1=(Ab*B)*P",
                output: [
                    Token(value: "(", type: TokenType.BracketOpen),
                    Token(value: "Ab", type: TokenType.Operand),
                    Token(value: "*", type: TokenType.Operator),
                    Token(value: "B", type: TokenType.Operand),
                    Token(value: ")", type: TokenType.BracketClose),
                    Token(value: "*", type: TokenType.Operator),
                    Token(value: "P", type: TokenType.Operand),
                ]),
        ]
    )
    func testParserSimpleInput(testData: TestData) throws {
        let parser = Parser()
        var tokens: [Token]
        try tokens = parser.parse(input: testData.input).expression
        //        print(tokens)
        #expect(tokens == testData.output)

    }

    @Test(
        "Error Tests",
        arguments: [
            ParserTestData(
                input: "out1A*B",
                output: [],
                error: .invalidSyntax(
                    index: 1,
                    message:
                        "Invalid syntax. The first element should be an Operand, then an Equal sign, followed by the formula."
                )
            ),
            ParserTestData(
                input: "out1=A++B",
                output: [],
                error: .invalidSyntax(
                    index: 4,
                    message:
                        "Invalid syntax. Only operands and bracket closures allowed in front of a two sided operator."
                )
            ),
            ParserTestData(
                input: "out1=A~+B",
                output: [],
                error: .invalidSyntax(
                    index: 4,
                    message:
                        "Invalid syntax. Only operands and bracket closures allowed in front of a two sided operator."
                )
            ),
            ParserTestData(
                input: "out1=)Ab*B)",
                output: [],
                error: .invalidSyntax(
                    index: 2, message: "Premature bracket closure.")
            ),
            ParserTestData(
                input: "out1=(Ab*B(*P",
                output: [],
                error: .invalidSyntax(
                    index: 6,
                    message:
                        "Invalid syntax. Can only place operators before opening a bracket."
                )
            ),
            ParserTestData(
                input: "out1=()",
                output: [],
                error: .invalidSyntax(
                    index: 3, message: "Invalid syntax. Empty brackets.")
            ),
            ParserTestData(
                input: "out1=(+)",
                output: [],
                error: .invalidSyntax(
                    index: 3,
                    message:
                        "Invalid syntax. Only operands and bracket closures allowed in front of a two sided operator."
                )
            ),
            ParserTestData(
                input: "out1=(a+)",
                output: [],
                error: .invalidSyntax(
                    index: 5,
                    message:
                        "Invalid syntax. Only operands allowed before closing a bracket"
                )
            ),
            ParserTestData(
                input: "out1==bb+cc",
                output: [],
                error: .invalidSyntax(
                    index: 2,
                    message:
                        "Invalid syntax. Only operands, opening brackets and negation is allowed after Equal sign."
                )
            ),
            ParserTestData(
                input: "out1=((a+b)",
                output: [],
                error: .invalidSyntax(
                    index: 7,
                    message:
                        "Invalid syntax. Brackets were left opened and were never closed."
                )
            ),
        ])
    func testParserErroneousInput(testData: ParserTestData) throws {
        let parser = Parser()

        #expect {
            _ = try parser.parse(input: testData.input)
        } throws: { error in
            let error = error as! ParserError
            return error == testData.error
        }
    }
}
