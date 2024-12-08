//
//  File.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 23/11/2024.
//

import Testing

@testable import LeXParser

@Suite("FileCreator Tests")
struct FileCreatorTests {

    @Test(
        "Basic 3-var Test",
        arguments: [
            (
                "/Users/wojciech.kosikowski/Projects/IOS/logic-expression-parser/Sources/lib/InOutTables.txt",
                0
            )
        ])
    func basicTests(data: (String, Int)) async throws {
        let formulaCreator = FormulaCreator()
        let fileReader = FileReader()
        let fileContent = fileReader.readString(file: data.0)
        print(fileContent)
        let result = formulaCreator.createFormula(
            table: fileContent
        )
        #expect(
            result[0].expression == [
                Token(value: "(", type: .BracketOpen),
                Token(value: "~", type: .Operator),
                Token(value: "in1", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in2", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in3", type: .Operand),
                Token(value: ")", type: .BracketClose),
                Token(value: "+", type: .Operator),
                Token(value: "(", type: .BracketOpen),
                Token(value: "in1", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "~", type: .Operator),
                Token(value: "in2", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in3", type: .Operand),
                Token(value: ")", type: .BracketClose),
            ]
                && result[1].expression == [
                    Token(value: "(", type: .BracketOpen),
                    Token(value: "~", type: .Operator),
                    Token(value: "in1", type: .Operand),
                    Token(value: "*", type: .Operator),
                    Token(value: "~", type: .Operator),
                    Token(value: "in2", type: .Operand),
                    Token(value: "*", type: .Operator),
                    Token(value: "in3", type: .Operand),
                    Token(value: ")", type: .BracketClose),
                    Token(value: "+", type: .Operator),
                    Token(value: "(", type: .BracketOpen),
                    Token(value: "in1", type: .Operand),
                    Token(value: "*", type: .Operator),
                    Token(value: "~", type: .Operator),
                    Token(value: "in2", type: .Operand),
                    Token(value: "*", type: .Operator),
                    Token(value: "in3", type: .Operand),
                    Token(value: ")", type: .BracketClose),
                ]
        )

    }
}
