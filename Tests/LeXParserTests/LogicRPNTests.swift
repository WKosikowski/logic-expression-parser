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

@Suite("RPN Converter")
struct RPNTests {

    @Test(
        "Simple Inputs",
        arguments: [
            RPNTestData(
                input: "out1=a+b",
                output: [
                    Token(value: "a", type: .Operand),
                    Token(value: "b", type: .Operand),
                    Token(value: "+", type: .Operator),
                ]),
            RPNTestData(
                input: "out1=a*~b",
                output: [
                    Token(value: "a", type: .Operand),
                    Token(value: "b", type: .Operand),
                    Token(value: "~", type: .Operator),
                    Token(value: "*", type: .Operator),
                ]),
            RPNTestData(
                input: "out1=a+b+(d*c)",
                output: [
                    Token(value: "a", type: .Operand),
                    Token(value: "b", type: .Operand),
                    Token(value: "+", type: .Operator),
                    Token(value: "d", type: .Operand),
                    Token(value: "c", type: .Operand),
                    Token(value: "*", type: .Operator),
                    Token(value: "+", type: .Operator),
                ]),
            RPNTestData(
                input: "out1=a+b+(d*(c+f))",
                output: [
                    Token(value: "a", type: .Operand),
                    Token(value: "b", type: .Operand),
                    Token(value: "+", type: .Operator),
                    Token(value: "d", type: .Operand),
                    Token(value: "c", type: .Operand),
                    Token(value: "f", type: .Operand),
                    Token(value: "+", type: .Operator),
                    Token(value: "*", type: .Operator),
                    Token(value: "+", type: .Operator),
                ]),
        ])
    func testRPN(data: RPNTestData) async throws {
        let parser = Parser()
        var expression = try parser.parse(input: data.input).expression
        let rpn = LogicRPN().makeNotation(input: &expression)
        #expect(data.output == rpn)
    }

}
