//
//  RPN.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 27/10/2024.
//

public typealias Expression = [Token]

public struct LogicRPN {
    private let operatorPrecedence: [String: Int] = [
        "~": 3,  // NOT has highest precedence
        "*": 2,  // AND
        "+": 1   // OR
    ]
    
    public init() {}
    
    public func makeNotation(input: inout Expression) -> Expression {
        // Handle assignment prefix (if exists)
        let prefix = extractAssignmentPrefix(from: &input)
        let rpn = convertToRPN(&input)
        return prefix + rpn
    }
    
    private func extractAssignmentPrefix(from input: inout Expression) -> Expression {
        guard input.count >= 2,
              input[0].type == .Operand,
              input[1].type == .Equal else {
            return []
        }
        
        let prefix = Array(input.prefix(2))
        input.removeFirst(2)
        return prefix
    }
    
    private func convertToRPN(_ input: inout Expression) -> Expression {
        var stack: Expression = []
        var rpn: Expression = []
        
        while !input.isEmpty {
            let token = input.removeFirst()
            
            switch token.type {
            case .Operand:
                rpn.append(token)
                
            case .BracketOpen:
                stack.append(token)
                
            case .BracketClose:
                while let top = stack.last, top.type != .BracketOpen {
                    rpn.append(stack.removeLast())
                }
                _ = stack.popLast() // Remove the opening bracket
                
            case .Operator:
                while let top = stack.last,
                      top.type == .Operator,
                      let topPrec = operatorPrecedence[top.value],
                      let currentPrec = operatorPrecedence[token.value],
                      topPrec >= currentPrec {
                    rpn.append(stack.removeLast())
                }
                stack.append(token)
                
            default:
                continue
            }
        }
        
        // Add remaining operators to output
        rpn.append(contentsOf: stack.reversed())
        
        return rpn
    }
}
