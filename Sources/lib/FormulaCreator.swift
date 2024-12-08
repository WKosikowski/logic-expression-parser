//
//  File.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 23/11/2024.
//

struct FormulaCreator {
    func createFormula(table: String) -> [Formula] {
        var expressions: [Expression] = []
        let instances = table.split(separator: "\n")
        let outputs = Array(instances[0].split(separator: "|")[1])
        
        for outputIdx in 0...outputs.count-1{
            var expression: Expression = []
            for instance in instances {
                let dividedInstance = instance.split(separator: "|")
                
                let outValue = dividedInstance[1][dividedInstance[1].index(dividedInstance[1].startIndex, offsetBy: outputIdx)]
                if outValue == "1" {
                    var subExpression: Expression = []
                    
                    if !expression.isEmpty {
                        expression.append(Token(value: "+", type: .Operator))
                    }
                    
                    subExpression.append(Token(value: "(", type: .BracketOpen))
                    var inputCounter = 0
                    
                    for input in dividedInstance[0] {
                        inputCounter += 1
                        
                        if inputCounter != 1 {
                            subExpression.append(Token(value: "*", type: .Operator))
                        }
                        if String(input) == "0"{
                            subExpression.append(
                                Token(value: "~", type: .Operator))
                        }
                        subExpression.append(
                            Token(value: "in\(inputCounter)", type: .Operand))
                    }
                    
                    subExpression.append(Token(value: ")", type: .BracketClose))
                    expression += subExpression
                }
            }
            expressions.append(expression)
        }
        
        var formulas: [Formula] = []
        for expression in expressions {
            print(expression)
            formulas
                .append(
                    Formula(
                        output: Token(value: "Out", type: .Operand),
                        expression: expression,
                        value: nil
                    )
                )
        }
        
        return formulas
    }
}
