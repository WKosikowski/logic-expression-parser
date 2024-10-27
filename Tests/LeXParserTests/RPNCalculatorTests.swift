//
//  RPNCalculatorTests.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 27/10/2024.
//

import Testing

@testable import LeXParser

struct RPNCalcTestData {
    let input: String
    let inputValues: [Token: Bool]
    let output: Bool
}

struct RPNLogicCalculatorTests {
    @Test(
        "Simple Tests",
        arguments: [
            RPNCalcTestData(
                input: "y=a+a*b",
                inputValues: [
                    Token(value: "a", type: .Operand): true,
                    Token(value: "b", type: .Operand): false,
                ],
                output: true
            )
        ]
    )
    func testSimpleInput(data: RPNCalcTestData) throws {
        let parser = Parser()
        let calculator = LogicRPNCalculator()
        var expression = try parser.parse(input: data.input).expression

        let rpn = LogicRPN().makeNotation(
            input: &expression
        )
        #expect(
            calculator
                .calculateOne(
                    expression: rpn,
                    input: data.inputValues
                ) == data.output
        )
    }
}
