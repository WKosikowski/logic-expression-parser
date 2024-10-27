//
//  Test.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 27/10/2024.
//

import Testing
@testable import LeXParser

struct RPNTestData {
    let input: String
    let output: [Token]
}


struct RPNTests {
    
    @Test("Simple Inputs", arguments: [
        RPNTestData(input: "out1=a+b", output: [
            Token(value: "out1", type: .Operand),
            Token(value: "=", type: .Equal),
            Token(value: "a", type: .Operand),
            Token(value: "b", type: .Operand),
            Token(value: "+", type: .Operator)
        ]),
        RPNTestData(input: "out1=a*~b", output: [
            Token(value: "out1", type: .Operand),
            Token(value: "=", type: .Equal),
            Token(value: "a", type: .Operand),
            Token(value: "b", type: .Operand),
            Token(value: "~", type: .Operator),
            Token(value: "*", type: .Operator)
        ]),
        RPNTestData(input: "out1=a+b+(d*c)", output: [
            Token(value: "out1", type: .Operand),
            Token(value: "=", type: .Equal),
            Token(value: "a", type: .Operand),
            Token(value: "b", type: .Operand),
            Token(value: "+", type: .Operator),
            Token(value: "d", type: .Operand),
            Token(value: "c", type: .Operand),
            Token(value: "*", type: .Operator),
            Token(value: "+", type: .Operator)
        ]),
        RPNTestData(input: "out1=a+b+(d*(c+f))", output: [
            Token(value: "out1", type: .Operand),
            Token(value: "=", type: .Equal),
            Token(value: "a", type: .Operand),
            Token(value: "b", type: .Operand),
            Token(value: "+", type: .Operator),
            Token(value: "d", type: .Operand),
            Token(value: "c", type: .Operand),
            Token(value: "f", type: .Operator),
            Token(value: "+", type: .Operator),
            Token(value: "*", type: .Operator),
            Token(value: "+", type: .Operator)
        ]),
    ])
    func testRPN(data: RPNTestData) async throws {
        let parser = Parser()
        var tokens = try parser.parse(input: data.input)
        let rpn = ReversePolishNotation().makeNotation(input: &tokens)
        #expect(data.output == rpn)
    }

}
