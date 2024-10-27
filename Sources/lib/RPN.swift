//
//  RPN.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 27/10/2024.
//

class ReversePolishNotation {
    
    // out = A *(A + B + C)+  B
 
    func makeNotation(input: inout [Token]) -> [Token]{
        
        var stack: [Token] = []
        var rpn: [Token] = []
        
        while !input.isEmpty {
            let token = input.removeFirst()
            
            if token.type == .BracketOpen {
                // wywoluje rekursje
                let inBrackets = makeNotation(input: &input)
                // add inBrackets to rpn
            } else if token.type == .BracketClose {
                //move all from stack to rpn
                // return rpn
            }
            
            if token.type == TokenType.Operand{
                rpn.append(token)
            }
            else if token.type == TokenType.Operator{
                if stack.isEmpty{
                    stack.append(token)
                }
                else if let lastToken = stack.last, lastToken.value == "~" ||
                            lastToken.value == "*" && (token.value == "*" || token.value == "+") ||
                            lastToken.value == token.value
                {
                    rpn.append(lastToken)
                    stack.removeLast()
                    rpn.append(token)
                }
                else {
                    stack.append(token)
                }
            }
        }
        
        // przeniesc stack to rpn
        rpn.append(contentsOf: stack.reversed())
        return rpn
    }
}
