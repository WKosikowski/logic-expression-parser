//
//  File.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 23/11/2024.
//

import XCTest
@testable import LeXParser

final class FormulaCreatorTests: XCTestCase {
    var formulaCreator: FormulaCreator!
    
    override func setUp() {
        super.setUp()
        formulaCreator = FormulaCreator()
    }
    
    /// Test empty input
    func testEmptyTable() {
        let result = formulaCreator.createFormula(table: "")
        XCTAssertTrue(result.isEmpty, "Empty input should return empty result")
    }
    
    /// Test single output column
    func testSingleOutput() {
        let table = """
        00|1
        01|0
        10|1
        11|0
        """
        
        let expected = Formula(
            output: Token(value: "Out", type: .Operand),
            expression: [
                Token(value: "(", type: .BracketOpen),
                Token(value: "~", type: .Operator),
                Token(value: "in1", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "~", type: .Operator),
                Token(value: "in2", type: .Operand),
                Token(value: ")", type: .BracketClose),
                Token(value: "+", type: .Operator),
                Token(value: "(", type: .BracketOpen),
                Token(value: "in1", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "~", type: .Operator),
                Token(value: "in2", type: .Operand),
                Token(value: ")", type: .BracketClose)
            ],
            value: nil
        )
        
        let result = formulaCreator.createFormula(table: table)
        XCTAssertEqual(result.count, 1, "Should create one formula")
        XCTAssertEqual(result.first?.expression, expected.expression)
    }
    
    /// Test multiple output columns
    func testMultipleOutputs() {
        let table = """
        00|10
        01|01
        10|11
        11|00
        """
        
        let result = formulaCreator.createFormula(table: table)
        XCTAssertEqual(result.count, 2, "Should create two formulas")
    }
    
    /// Test all zeros in output
    func testAllZerosOutput() {
        let table = """
        00|0
        01|0
        10|0
        11|0
        """
        
        let result = formulaCreator.createFormula(table: table)
        XCTAssertEqual(result.first?.expression.count, 0, "Should create empty expression for all zeros")
    }
    
    /// Test all ones in output
    func testAllOnesOutput() {
        let table = """
        00|1
        01|1
        10|1
        11|1
        """
        
        let result = formulaCreator.createFormula(table: table)
        XCTAssertFalse(result.first?.expression.isEmpty ?? true, "Should create non-empty expression for all ones")
    }
    
    /// Test invalid input format
    func testInvalidFormat() {
        // Test cases for invalid formats
        let invalidTables = [
            // No separator
            """
            001
            010
            101
            110
            """,
            // Empty output
            """
            00|
            01|
            10|
            11|
            """,
            // Empty input
            """
            |1
            |0
            |1
            |0
            """,
            // Invalid separator
            """
            00:1
            01:0
            10:1
            11:0
            """
        ]
        
        for table in invalidTables {
            let result = formulaCreator.createFormula(table: table)
            XCTAssertTrue(result.isEmpty, "Should return empty array for invalid format: \(table)")
        }
    }
    
    /// Test three input variables
    func testThreeInputs() {
        let table = """
        000|1
        001|0
        010|1
        011|0
        100|1
        101|0
        110|1
        111|0
        """
        
        let result = formulaCreator.createFormula(table: table)
        XCTAssertTrue(result.first?.expression.contains(where: { $0.value == "in3" }) ?? false,
                     "Should handle three input variables")
    }
    
    /// Test single row
    func testSingleRow() {
        let table = "00|1"
        
        let result = formulaCreator.createFormula(table: table)
        XCTAssertFalse(result.isEmpty, "Should handle single row")
        XCTAssertFalse(result.first?.expression.isEmpty ?? true, "Should create valid expression")
    }
    
    /// Test expression correctness
    func testExpressionCorrectness() {
        let table = """
        00|1
        01|0
        10|0
        11|1
        """
        
        let result = formulaCreator.createFormula(table: table)
        let expression = result.first?.expression
        
        // Check if expression starts with opening bracket
        XCTAssertEqual(expression?.first?.type, .BracketOpen)
        
        // Check if expression has proper operator sequence
        let operators = expression?.filter { $0.type == .Operator }.map { $0.value }
        XCTAssertTrue(operators?.contains("*") ?? false, "Should contain AND operator")
        XCTAssertTrue(operators?.contains("+") ?? false, "Should contain OR operator")
    }
}
