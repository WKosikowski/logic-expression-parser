//
//  lparser.swift
//  logic-expression-parser
//
//  Created by Wojciech Kosikowski on 25/10/2024.
//

import ArgumentParser
import Foundation
import LeXParser

/// Command-line interface for the Logic Expression Parser
@main
struct LeXParserCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "lparser",
        abstract: "A tool for parsing and simplifying logical expressions",
        version: "1.0.0"
    )
    
    // Input options
    @Option(name: .shortAndLong, help: "Input file path containing truth table")
    var input: String
    
    @Flag(name: .long, help: "Enable formula simplification")
    var simplify: Bool = false
    
    @Option(name: .long, help: "Output file path (optional)")
    var output: String?
    
    mutating func run() throws {
        // Read input file
        let fileReader = try FileReader(path: input)
        let content = try fileReader.read()
        
        // Create formulas from truth table
        let formulaCreator = FormulaCreator(
            simplifier: simplify ? LogicSimplifier() : nil
        )
        let formulas = formulaCreator.createFormula(table: content)
        
        // Format output
        let output = formatOutput(formulas)
        
        // Write to file or print to console
        if let outputPath = self.output {
            try output.write(
                toFile: outputPath,
                atomically: true,
                encoding: .utf8
            )
        } else {
            print(output)
        }
    }
    
    /// Formats formulas into a readable string
    private func formatOutput(_ formulas: [Formula]) -> String {
        formulas.enumerated().map { index, formula in
            let expression = formula.expression
                .map { $0.value }
                .joined(separator: " ")
            return "Formula \(index + 1): \(expression)"
        }.joined(separator: "\n")
    }
}
