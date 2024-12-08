//
//  File.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 23/11/2024.
//

/// FormulaCreator transforms a truth table into logical formulas in disjunctive normal form (DNF)
/// Example input table:
/// 00|10  (inputs|outputs)
/// 01|11
/// 10|01
/// 11|00
struct FormulaCreator {
    /// Creates formulas from a truth table string
    /// - Parameter table: String containing truth table with inputs and outputs separated by '|'
    /// - Returns: Array of Formula objects, one for each output column
    func createFormula(table: String) -> [Formula] {
        let instances = table.split(separator: "\n")
        
        // Return empty array if table is empty
        guard let firstInstance = instances.first,
              !firstInstance.isEmpty else { return [] }
        
        // Split first row and validate format
        let parts = firstInstance.split(separator: "|")
        guard parts.count >= 2,
              !parts[1].isEmpty else { return [] }
        
        // Get number of outputs from first row
        let outputs = Array(parts[1])
        
        // Create a formula for each output column
        return (0..<outputs.count).map { outputIndex in
            createSingleFormula(instances: instances, outputIndex: outputIndex)
        }
    }
    
    /// Creates a single formula for one output column
    /// - Parameters:
    ///   - instances: Array of table rows
    ///   - outputIndex: Index of the output column to process
    /// - Returns: A Formula object representing the logical function for this output
    private func createSingleFormula(instances: [Substring], outputIndex: Int) -> Formula {
        let expression = createExpression(instances: instances, outputIndex: outputIndex)
        return Formula(
            output: Token(value: "Out", type: .Operand),
            expression: expression,
            value: nil
        )
    }
    
    /// Creates an expression in DNF (sum of products) for one output column
    /// - Parameters:
    ///   - instances: Array of table rows
    ///   - outputIndex: Index of the output column to process
    /// - Returns: Expression representing the logical function
    private func createExpression(instances: [Substring], outputIndex: Int) -> Expression {
        instances.enumerated().reduce(into: Expression()) { expression, instance in
            let (index, row) = instance
            let parts = row.split(separator: "|")
            let inputs = parts[0]   // Input combinations (e.g., "001")
            let outputs = parts[1]  // Output values (e.g., "10")
            
            // Only process rows where output is 1
            guard outputs[outputs.index(outputs.startIndex, offsetBy: outputIndex)] == "1" else { return }
            
            // Add OR operator between terms
            if !expression.isEmpty {
                expression.append(Token(value: "+", type: .Operator))
            }
            
            // Add product term for this input combination
            expression.append(contentsOf: createProductTerm(inputs: inputs))
        }
    }
    
    /// Creates a product term for one input combination
    /// Example: for input "001" creates "(~in1 * ~in2 * in3)"
    /// - Parameter inputs: String of 0s and 1s representing input values
    /// - Returns: Expression for this product term
    private func createProductTerm(inputs: Substring) -> Expression {
        var term: Expression = [Token(value: "(", type: .BracketOpen)]
        
        inputs.enumerated().forEach { index, input in
            // Add AND operator between inputs
            if index > 0 {
                term.append(Token(value: "*", type: .Operator))
            }
            
            // Add NOT operator for 0 inputs
            if input == "0" {
                term.append(Token(value: "~", type: .Operator))
            }
            // Add input variable
            term.append(Token(value: "in\(index + 1)", type: .Operand))
        }
        
        term.append(Token(value: ")", type: .BracketClose))
        return term
    }
}
