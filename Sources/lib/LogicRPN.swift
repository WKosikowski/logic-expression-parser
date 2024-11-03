//
//  RPN.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 27/10/2024.
//

public typealias Expression = [Token]

public struct LogicRPN {
    public init() {}
    public func makeNotation(input: inout Expression) -> Expression {

        var stack: Expression = []
        var rpn: Expression = []
        var prefix: Expression = []
        if input[0].type == .Operand && input[1].type == .Equal {
            prefix = [input[0], input[1]]
            input.removeFirst(2)
        }

        while !input.isEmpty {
            let token = input.removeFirst()

            if token.type == .BracketOpen {
                let inBrackets = makeNotation(input: &input)
                rpn += inBrackets
            } else if token.type == .BracketClose {
                rpn.append(contentsOf: stack.reversed())
                stack.removeAll()
                return rpn
            }

            if token.type == TokenType.Operand {
                rpn.append(token)
            } else if token.type == TokenType.Operator {
                if stack.isEmpty {
                    stack.append(token)
                } else if let lastToken = stack.last,
                    lastToken.value == "~"
                        || lastToken.value == "*"
                            && (token.value == "*" || token.value == "+")
                        || lastToken.value == token.value
                {
                    rpn.append(contentsOf: stack.reversed())
                    stack.removeAll()
                    stack.append(token)
                } else {
                    stack.append(token)
                }
            }
        }
        rpn.append(contentsOf: stack.reversed())
        return prefix + rpn
    }
}
