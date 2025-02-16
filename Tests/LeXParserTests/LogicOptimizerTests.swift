import XCTest
@testable import LeXParser

/// Tests for the LogicOptimizer class which handles circuit optimization using K-maps
/// and other minimization techniques
final class LogicOptimizerTests: XCTestCase {
    var optimizer: LogicOptimizer!
    
    override func setUp() {
        super.setUp()
        optimizer = LogicOptimizer()
    }
    
    /// Tests basic optimization of a two-variable expression
    /// This test verifies that the optimizer can:
    /// 1. Recognize and combine adjacent terms
    /// 2. Remove redundant variables
    /// 3. Simplify to minimal form: A*B + A*~B = A
    func testBasicTwoVariableOptimization() {
        // Create a formula representing: A*B + A*~B
        // This should simplify to just A because:
        // - Both terms contain A
        // - B appears both normal and negated
        let formula = Formula(
            output: Token(value: "Out", type: .Operand),
            expression: [
                Token(value: "(", type: .BracketOpen),
                Token(value: "in1", type: .Operand),  // A
                Token(value: "*", type: .Operator),
                Token(value: "in2", type: .Operand),  // B
                Token(value: ")", type: .BracketClose),
                Token(value: "+", type: .Operator),
                Token(value: "(", type: .BracketOpen),
                Token(value: "in1", type: .Operand),  // A
                Token(value: "*", type: .Operator),
                Token(value: "~", type: .Operator),
                Token(value: "in2", type: .Operand),  // ~B
                Token(value: ")", type: .BracketClose)
            ],
            value: nil
        )
        
        let optimized = optimizer.optimize(formula)
        
        // The result should be just "in1" (representing A)
        XCTAssertEqual(
            optimized.expression.map { $0.value }.joined(separator: ""),
            "in1",
            "Expression A*B + A*~B should optimize to A"
        )
    }
    
    /// Tests optimization of a four-variable K-map pattern
    /// This test verifies that the optimizer can:
    /// 1. Handle 4-variable truth tables
    /// 2. Identify large groupings in K-map
    /// 3. Generate minimal expressions for complex patterns
    func testFourVariableKMapOptimization() {
        // Truth table representing pattern where only the first four rows are 1
        // This forms a rectangular group in K-map that can be represented as ~A*~B
        let truthTable = """
        0000|1
        0001|1
        0010|1
        0011|1
        0100|0
        0101|0
        0110|0
        0111|0
        1000|0
        1001|0
        1010|0
        1011|0
        1100|0
        1101|0
        1110|0
        1111|0
        """
        
        let formulaCreator = FormulaCreator(optimizer: optimizer)
        let formulas = formulaCreator.createFormula(table: truthTable)
        
        XCTAssertEqual(formulas.count, 1, "Should create one formula")
        
        // The pattern should optimize to ~in1 * ~in2 (NOT of first two variables)
        let optimized = formulas[0]
        XCTAssertEqual(
            optimized.expression.map { $0.value }.joined(separator: ""),
            "~in1*~in2",
            "Four-variable pattern should optimize to ~in1*~in2"
        )
    }
    
    /// Tests optimization of adjacent groups in K-map
    /// This test verifies that the optimizer can:
    /// 1. Identify adjacent terms that can be combined
    /// 2. Remove redundant variables
    /// 3. Handle NOT operations correctly
    func testAdjacentGroupOptimization() {
        // Create formula representing: (~A*~B) + (~A*B)
        // These terms are adjacent in K-map and should combine to ~A
        let formula = Formula(
            output: Token(value: "Out", type: .Operand),
            expression: [
                Token(value: "(", type: .BracketOpen),
                Token(value: "~", type: .Operator),
                Token(value: "in1", type: .Operand),  // ~A
                Token(value: "*", type: .Operator),
                Token(value: "~", type: .Operator),
                Token(value: "in2", type: .Operand),  // ~B
                Token(value: ")", type: .BracketClose),
                Token(value: "+", type: .Operator),
                Token(value: "(", type: .BracketOpen),
                Token(value: "~", type: .Operator),
                Token(value: "in1", type: .Operand),  // ~A
                Token(value: "*", type: .Operator),
                Token(value: "in2", type: .Operand),  // B
                Token(value: ")", type: .BracketClose)
            ],
            value: nil
        )
        
        let optimized = optimizer.optimize(formula)
        
        XCTAssertEqual(
            optimized.expression.map { $0.value }.joined(separator: ""),
            "~in1",
            "Expression (~A*~B) + (~A*B) should optimize to ~A"
        )
    }
    
    /// Tests optimization of groups that wrap around K-map edges
    func testWrappedGroupOptimization() {
        let testCases = [
            (
                """
                000|1
                001|0
                010|0
                011|1
                100|0
                101|1
                110|1
                111|0
                """,
                "in1*in3+~in1*~in3",
                "XNOR pattern with wrapped groups",
                5
            ),
            (
                """
                0000|1
                0001|0
                0010|0
                0011|1
                0100|1
                0101|0
                0110|0
                0111|1
                1000|1
                1001|0
                1010|0
                1011|1
                1100|1
                1101|0
                1110|0
                1111|1
                """,
                "in1*in3+~in1*~in3",
                "4-variable wrapped pattern",
                5
            )
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let (truthTable, expectedFormula, description, maxGates) = testCase
            
            let formulaCreator = FormulaCreator(optimizer: optimizer)
            let formulas = formulaCreator.createFormula(table: truthTable)
            
            XCTAssertEqual(formulas.count, 1, "Test case \(index): Should create one formula")
            
            let optimized = formulas[0]
            let expression = optimized.expression.map { $0.value }.joined(separator: "")
            
            XCTAssertEqual(
                expression,
                expectedFormula,
                "Test case \(index): \(description)"
            )
            
            let gateCount = countGates(in: optimized.expression)
            XCTAssertLessThanOrEqual(
                gateCount,
                maxGates,
                "Test case \(index): Should use no more than \(maxGates) gates"
            )
        }
    }
    
    /// Tests optimization with don't care conditions
    func testDontCareOptimization() {
        let optimizer = LogicOptimizer(configuration: .init(
            useKMap: true,
            useDontCares: true,
            preferAndGates: true
        ))
        
        let testCases = [
            (
                """
                000|-
                001|1
                010|0
                011|-
                100|1
                101|-
                110|0
                111|1
                """,
                "in1+in3",
                "Don't cares help form larger groups"
            ),
            (
                """
                0000|1
                0001|-
                0010|1
                0011|-
                0100|0
                0101|-
                0110|0
                0111|0
                1000|1
                1001|-
                1010|1
                1011|-
                1100|0
                1101|0
                1110|0
                1111|0
                """,
                "~in2*in3",
                "Don't cares enable simpler expression"
            )
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let (truthTable, expectedFormula, description) = testCase
            
            let formulaCreator = FormulaCreator(optimizer: optimizer)
            let formulas = formulaCreator.createFormula(table: truthTable)
            
            XCTAssertEqual(formulas.count, 1, "Test case \(index): Should create one formula")
            
            let optimized = formulas[0]
            XCTAssertEqual(
                optimized.expression.map { $0.value }.joined(separator: ""),
                expectedFormula,
                "Test case \(index): \(description)"
            )
        }
    }
    
    /// Tests different gate preferences in optimization
    func testGatePreference() {
        let andPreferred = LogicOptimizer(configuration: .init(
            useKMap: true,
            useDontCares: false,
            preferAndGates: true
        ))
        
        let orPreferred = LogicOptimizer(configuration: .init(
            useKMap: true,
            useDontCares: false,
            preferAndGates: false
        ))
        
        // Create a formula that can be optimized either as A*(B+C) or A*B + A*C
        let formula = Formula(
            output: Token(value: "Out", type: .Operand),
            expression: [
                // First term: A*B
                Token(value: "(", type: .BracketOpen),
                Token(value: "in1", type: .Operand),  // A
                Token(value: "*", type: .Operator),
                Token(value: "in2", type: .Operand),  // B
                Token(value: ")", type: .BracketClose),
                
                Token(value: "+", type: .Operator),
                
                // Second term: A*C
                Token(value: "(", type: .BracketOpen),
                Token(value: "in1", type: .Operand),  // A
                Token(value: "*", type: .Operator),
                Token(value: "in3", type: .Operand),  // C
                Token(value: ")", type: .BracketClose)
            ],
            value: nil
        )
        
        let andOptimized = andPreferred.optimize(formula)
        let orOptimized = orPreferred.optimize(formula)
        
        // Count gates in both versions
        let andGateCount = countSpecificGates(in: andOptimized.expression, operator: "*")
        let orGateCount = countSpecificGates(in: orOptimized.expression, operator: "*")
        
        // AND preference should produce A*(B+C) with one AND gate
        // OR preference should keep A*B + A*C with two AND gates
        XCTAssertEqual(andGateCount, 1, "AND-preferred version should use one AND gate")
        XCTAssertEqual(orGateCount, 2, "OR-preferred version should use two AND gates")
        XCTAssertLessThan(andGateCount, orGateCount, "AND-preferred version should use fewer AND gates")
    }
    
    /// Counts occurrences of a specific gate type
    private func countSpecificGates(in expression: [Token], operator: String) -> Int {
        expression.filter { token in
            token.type == .Operator && token.value == `operator`
        }.count
    }
    
    // MARK: - Helper Methods
    
    /// Counts the number of logical gates in an expression
    /// - Parameter expression: The expression to analyze
    /// - Returns: Count of AND, OR, and NOT gates in the expression
    private func countGates(in expression: [Token]) -> Int {
        expression.filter { token in
            token.type == .Operator && ["*", "+", "~"].contains(token.value)
        }.count
    }
    
    /// Tests conversion of various truth table patterns to optimized formulas
    func testTruthTableOptimizations() {
        // Test cases with expected optimizations
        let testCases = [
            // Single variable cases
            (
                """
                0|0
                1|1
                """,
                "in1",
                "Identity function: f(A) = A"
            ),
            (
                """
                0|1
                1|0
                """,
                "~in1",
                "NOT function: f(A) = ~A"
            ),
            
            // Two variable cases
            (
                """
                00|1
                01|1
                10|1
                11|1
                """,
                "1",
                "Always true: f(A,B) = 1"
            ),
            (
                """
                00|0
                01|0
                10|0
                11|0
                """,
                "0",
                "Always false: f(A,B) = 0"
            ),
            (
                """
                00|0
                01|0
                10|0
                11|1
                """,
                "in1*in2",
                "AND function: f(A,B) = A*B"
            ),
            (
                """
                00|0
                01|1
                10|1
                11|1
                """,
                "in1+in2",
                "OR function: f(A,B) = A+B"
            ),
            
            // Three variable cases
            (
                """
                000|0
                001|0
                010|0
                011|1
                100|0
                101|0
                110|0
                111|1
                """,
                "in2*in3",
                "AND of second two variables: f(A,B,C) = B*C"
            ),
            (
                """
                000|1
                001|1
                010|1
                011|1
                100|0
                101|0
                110|0
                111|0
                """,
                "~in1",
                "NOT of first variable: f(A,B,C) = ~A"
            ),
            
            // Four variable cases with complex patterns
            (
                """
                0000|1
                0001|1
                0010|1
                0011|1
                0100|0
                0101|0
                0110|0
                0111|0
                1000|0
                1001|0
                1010|0
                1011|0
                1100|0
                1101|0
                1110|0
                1111|0
                """,
                "~in1*~in2",
                "First two variables must be 0: f(A,B,C,D) = ~A*~B"
            ),
            (
                """
                0000|0
                0001|0
                0010|0
                0011|0
                0100|1
                0101|1
                0110|1
                0111|1
                1000|0
                1001|0
                1010|0
                1011|0
                1100|1
                1101|1
                1110|1
                1111|1
                """,
                "in2",
                "Second variable determines output: f(A,B,C,D) = B"
            )
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let (truthTable, expectedFormula, description) = testCase
            
            let formulaCreator = FormulaCreator(optimizer: optimizer)
            let formulas = formulaCreator.createFormula(table: truthTable)
            
            XCTAssertEqual(formulas.count, 1, "Test case \(index): Should create one formula")
            
            let optimized = formulas[0]
            XCTAssertEqual(
                optimized.expression.map { $0.value }.joined(separator: ""),
                expectedFormula,
                "Test case \(index): \(description)"
            )
        }
    }
    
    /// Tests pattern detection in K-map optimization
    func testPatternDetection() {
        let testCases = [
            // Row pattern tests
            (
                """
                0000|1
                0001|1
                0010|1
                0011|1
                0100|0
                0101|0
                0110|0
                0111|0
                1000|0
                1001|0
                1010|0
                1011|0
                1100|0
                1101|0
                1110|0
                1111|0
                """,
                "~in1*~in2",
                "First two variables must be 0"
            ),
            
            // Column pattern tests
            (
                """
                0000|1
                0001|0
                0010|1
                0011|0
                0100|1
                0101|0
                0110|1
                0111|0
                1000|1
                1001|0
                1010|1
                1011|0
                1100|1
                1101|0
                1110|1
                1111|0
                """,
                "~in4",
                "Last variable must be 0"
            ),
            
            // Mixed row-column pattern
            (
                """
                0000|1
                0001|1
                0010|0
                0011|0
                0100|1
                0101|1
                0110|0
                0111|0
                1000|0
                1001|0
                1010|0
                1011|0
                1100|0
                1101|0
                1110|0
                1111|0
                """,
                "~in1*~in3",
                "First and third variables must be 0"
            ),
            
            // Wrapped pattern tests
            (
                """
                0000|1
                0001|0
                0010|0
                0011|1
                0100|0
                0101|0
                0110|0
                0111|0
                1000|1
                1001|0
                1010|0
                1011|1
                1100|0
                1101|0
                1110|0
                1111|0
                """,
                "in1*in3+~in1*~in3",
                "Variables 1 and 3 must be same (XNOR)"
            ),
            
            // Don't care pattern tests
            (
                """
                0000|1
                0001|-
                0010|1
                0011|-
                0100|0
                0101|0
                0110|0
                0111|0
                1000|1
                1001|-
                1010|1
                1011|-
                1100|0
                1101|0
                1110|0
                1111|0
                """,
                "in3",
                "Third variable determines output (using don't cares)"
            ),
            
            // Complex patterns
            (
                """
                0000|1
                0001|1
                0010|1
                0011|1
                0100|1
                0101|1
                0110|1
                0111|1
                1000|0
                1001|0
                1010|0
                1011|0
                1100|0
                1101|0
                1110|0
                1111|0
                """,
                "~in1",
                "First variable must be 0 (large group)"
            ),
            
            // Multiple group patterns
            (
                """
                0000|1
                0001|0
                0010|1
                0011|0
                0100|1
                0101|0
                0110|1
                0111|0
                1000|0
                1001|0
                1010|0
                1011|0
                1100|0
                1101|0
                1110|0
                1111|0
                """,
                "~in1*~in4",
                "First variable 0 AND last variable 0"
            )
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let (truthTable, expectedFormula, description) = testCase
            
            let formulaCreator = FormulaCreator(optimizer: optimizer)
            let formulas = formulaCreator.createFormula(table: truthTable)
            
            XCTAssertEqual(formulas.count, 1, "Test case \(index): Should create one formula")
            
            let optimized = formulas[0]
            XCTAssertEqual(
                optimized.expression.map { $0.value }.joined(separator: ""),
                expectedFormula,
                "Test case \(index): \(description)"
            )
        }
    }
    
    /// Tests gate count optimization
    func testGateCountOptimization() {
        let testCases = [
            (
                """
                0000|1
                0001|1
                0010|1
                0011|1
                0100|0
                0101|0
                0110|0
                0111|0
                1000|0
                1001|0
                1010|0
                1011|0
                1100|0
                1101|0
                1110|0
                1111|0
                """,
                3,  // Expected gate count (~in1*~in2 has 3 gates: 2 NOT and 1 AND)
                "Simple pattern should use minimal gates"
            ),
            (
                """
                0000|1
                0001|1
                0010|0
                0011|0
                0100|1
                0101|1
                0110|0
                0111|0
                1000|0
                1001|0
                1010|0
                1011|0
                1100|0
                1101|0
                1110|0
                1111|0
                """,
                3,  // Expected gate count (~in1*~in3 has 3 gates)
                "Mixed pattern should use minimal gates"
            )
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let (truthTable, expectedGateCount, description) = testCase
            
            let formulaCreator = FormulaCreator(optimizer: optimizer)
            let formulas = formulaCreator.createFormula(table: truthTable)
            
            XCTAssertEqual(formulas.count, 1, "Test case \(index): Should create one formula")
            
            let optimized = formulas[0]
            let actualGateCount = countGates(in: optimized.expression)
            
            XCTAssertEqual(
                actualGateCount,
                expectedGateCount,
                "Test case \(index): \(description)"
            )
        }
    }
    
    /// Tests edge cases and special patterns
    func testEdgeCases() {
        let testCases = [
            // Empty expression
            (
                """
                0|0
                1|0
                """,
                "0",
                "Empty expression should optimize to 0"
            ),
            // Single variable unchanged
            (
                """
                0|0
                1|1
                """,
                "in1",
                "Single variable should remain unchanged"
            ),
            // Alternating pattern
            (
                """
                000|1
                001|0
                010|1
                011|0
                100|1
                101|0
                110|1
                111|0
                """,
                "~in3",
                "Alternating pattern should detect last variable"
            ),
            // All variables required
            (
                """
                000|0
                001|0
                010|0
                011|0
                100|0
                101|0
                110|0
                111|1
                """,
                "in1*in2*in3",
                "All variables required should show in expression"
            )
        ]
        
        for (index, testCase) in testCases.enumerated() {
            let (truthTable, expectedFormula, description) = testCase
            
            let formulaCreator = FormulaCreator(optimizer: optimizer)
            let formulas = formulaCreator.createFormula(table: truthTable)
            
            XCTAssertEqual(formulas.count, 1, "Test case \(index): Should create one formula")
            
            let optimized = formulas[0]
            XCTAssertEqual(
                optimized.expression.map { $0.value }.joined(separator: ""),
                expectedFormula,
                "Test case \(index): \(description)"
            )
        }
    }
} 
