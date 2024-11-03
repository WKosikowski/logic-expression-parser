//
//  lparser.swift
//  logic-expression-parser
//
//  Created by Wojciech Kosikowski on 25/10/2024.
//

import ArgumentParser
import LeXParser

@main
struct Repeat: ParsableCommand {

    @Option(help: "Signle line logic expression")
    var singleLine: String

    mutating func run() throws {

        let result = try Parser().parse(input: singleLine)
        print(singleLine)
        print("Syntax OK")
        var resultExpression = result.expression
        let rpnResults = LogicRPN().makeNotation(input: &resultExpression)
        let RPNCalc = LogicRPNCalculator()
        print(
            RPNCalc
                .printTruthTable(
                    formula: Formula(
                        output: result.output,
                        expression: rpnResults,
                        value: nil
                    )
                ))
    }
}
