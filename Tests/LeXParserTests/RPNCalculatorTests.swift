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
struct TruthTableTestData {
    let input: String
    let output: String
}

struct RPNPremutationsTestData {
    let input: String
}

@Suite("RPN Calculator")
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
    func testSimpleInput(data: RPNCalcTestData) async throws {
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

    @Test(
        "Truth Table Tests",
        arguments: [
            TruthTableTestData(
                input: "A=B*C+~D",
                output:
                    """
                        B C D   A
                    0 | 0 0 0 | 1
                    1 | 1 0 0 | 1
                    2 | 0 1 0 | 1
                    3 | 1 1 0 | 1
                    4 | 0 0 1 | 0
                    5 | 1 0 1 | 0
                    6 | 0 1 1 | 0
                    7 | 1 1 1 | 1
                    """),
            TruthTableTestData(
                input: "A=Baaa*C+~Ds",
                output:
                    """
                        Baaa C Ds   A
                    0 | 0    0 0  | 1
                    1 | 1    0 0  | 1
                    2 | 0    1 0  | 1
                    3 | 1    1 0  | 1
                    4 | 0    0 1  | 0
                    5 | 1    0 1  | 0
                    6 | 0    1 1  | 0
                    7 | 1    1 1  | 1
                    """),

        ])
    func testTruthTable(data: TruthTableTestData) async throws {
        let formula = try Parser().parse(input: data.input)
        var formulaExpression = formula.expression
        let rpnResults = LogicRPN().makeNotation(input: &formulaExpression)
        let RPNCalc = LogicRPNCalculator()
        let result =
            RPNCalc
            .printTruthTable(
                formula: Formula(
                    output: formula.output,
                    expression: rpnResults,
                    value: nil
                )
            )
        #expect(result == data.output)
    }
}
