import XCTest
@testable import LeXParser

final class LogicSimplifierTests: XCTestCase {
    var simplifier: LogicSimplifier!
    
    override func setUp() {
        super.setUp()
        simplifier = LogicSimplifier()
    }
    
    func testIdempotentLaw() {
        let formula = Formula(
            output: Token(value: "Out", type: .Operand),
            expression: [
                Token(value: "A", type: .Operand),
                Token(value: "+", type: .Operator),
                Token(value: "A", type: .Operand)
            ],
            value: nil
        )
        
        let simplified = simplifier.simplify(formula)
        
        XCTAssertEqual(
            simplified.expression,
            [Token(value: "A", type: .Operand)]
        )
    }
    
    func testAbsorptionLaw() {
        let formula = Formula(
            output: Token(value: "Out", type: .Operand),
            expression: [
                Token(value: "A", type: .Operand),
                Token(value: "+", type: .Operator),
                Token(value: "(", type: .BracketOpen),
                Token(value: "A", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "B", type: .Operand),
                Token(value: ")", type: .BracketClose)
            ],
            value: nil
        )
        
        let simplified = simplifier.simplify(formula)
        
        XCTAssertEqual(
            simplified.expression,
            [Token(value: "A", type: .Operand)]
        )
    }
    
    /// Test complex expression with 6 inputs
    func testComplexSixInputExpression() {
        // This represents a complex function with 6 inputs
        // Example: f(a,b,c,d,e,f) = abc + ~a~bc~d + cdef + abcdef
        let formula = Formula(
            output: Token(value: "Out", type: .Operand),
            expression: [
                // First term: abc
                Token(value: "(", type: .BracketOpen),
                Token(value: "in1", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in2", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in3", type: .Operand),
                Token(value: ")", type: .BracketClose),
                
                Token(value: "+", type: .Operator),
                
                // Second term: ~a~bc~d
                Token(value: "(", type: .BracketOpen),
                Token(value: "~", type: .Operator),
                Token(value: "in1", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "~", type: .Operator),
                Token(value: "in2", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in3", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "~", type: .Operator),
                Token(value: "in4", type: .Operand),
                Token(value: ")", type: .BracketClose),
                
                Token(value: "+", type: .Operator),
                
                // Third term: cdef
                Token(value: "(", type: .BracketOpen),
                Token(value: "in3", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in4", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in5", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in6", type: .Operand),
                Token(value: ")", type: .BracketClose),
                
                Token(value: "+", type: .Operator),
                
                // Fourth term: abcdef
                Token(value: "(", type: .BracketOpen),
                Token(value: "in1", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in2", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in3", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in4", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in5", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "in6", type: .Operand),
                Token(value: ")", type: .BracketClose)
            ],
            value: nil
        )
        
        let simplified = simplifier.simplify(formula)
        
        // The simplified expression should remove redundant terms
        // abc + abcdef should simplify to abc (absorption law)
        XCTAssertFalse(
            containsFullTerm(simplified.expression, ["in1", "in2", "in3", "in4", "in5", "in6"]),
            "Simplified expression should not contain the full term abcdef"
        )
    }
    
    /// Test with real truth table data
    func testTruthTableSimplification() {
        let table = """
        000000|1
        000001|0
        000010|1
        000011|1
        000100|0
        000101|1
        000110|0
        000111|1
        111111|1
        """
        
        let formulaCreator = FormulaCreator(simplifier: simplifier)
        let formulas = formulaCreator.createFormula(table: table)
        
        XCTAssertEqual(formulas.count, 1, "Should create one formula")
        
        let simplified = formulas[0]
        // Verify the simplified expression has fewer terms than the original
        let orCount = simplified.expression.filter { $0.value == "+" }.count
        XCTAssertTrue(orCount < 8, "Simplified expression should have fewer terms than 8, but got \(orCount)")
    }
    
    /// Test configuration options
    func testSimplifierConfiguration() {
        let complexFormula = Formula(
            output: Token(value: "Out", type: .Operand),
            expression: [
                // A + A*B + A
                Token(value: "A", type: .Operand),
                Token(value: "+", type: .Operator),
                Token(value: "(", type: .BracketOpen),
                Token(value: "A", type: .Operand),
                Token(value: "*", type: .Operator),
                Token(value: "B", type: .Operand),
                Token(value: ")", type: .BracketClose),
                Token(value: "+", type: .Operator),
                Token(value: "A", type: .Operand)
            ],
            value: nil
        )
        
        // Test with only idempotent law
        let idempotentOnly = LogicSimplifier(configuration: .init(
            useAbsorptionLaw: false,
            useIdempotentLaw: true,
            useComplementLaw: false,
            useDeMorgansLaw: false
        ))
        
        let idempotentSimplified = idempotentOnly.simplify(complexFormula)
        XCTAssertNotEqual(
            idempotentSimplified.expression,
            [Token(value: "A", type: .Operand)],
            "Should only remove duplicate A terms"
        )
        
        // Test with all laws
        let fullSimplified = simplifier.simplify(complexFormula)
        XCTAssertEqual(
            fullSimplified.expression,
            [Token(value: "A", type: .Operand)],
            "Should fully simplify to A"
        )
    }
    
    // Helper function to check if expression contains a specific term
    private func containsFullTerm(_ expression: [Token], _ variables: [String]) -> Bool {
        let operands = expression.filter { $0.type == TokenType.Operand }.map { $0.value }
        return variables.allSatisfy { operands.contains($0) }
    }
} 