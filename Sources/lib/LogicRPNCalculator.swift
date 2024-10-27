//
//  RPNCalculator.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 27/10/2024.
//

struct LogicRPNCalculator {
    func calculateOne(expression: Expression, input: [Token: Bool]) -> Bool {
        var newFormula: [Component] = []
        for token in expression {
            if token.type == .Operand {
                newFormula.append(.bool(input[token] ?? false))
            } else {
                newFormula.append(.operator(token.value))
            }
        }
        var index = 0
        while newFormula.count != 1 {
            let element = newFormula[index]
            switch element {
            case .bool(_):
                increaseIndex(&index, max: newFormula.count)
            case let .operator(op):
                if op == "~" {
                    if case let .bool(n) = newFormula[index - 1] {
                        newFormula[index - 1] = .bool(!n)
                        newFormula.remove(at: index)
                        decreaseIndex(&index)
                    } else {
                        fatalError("this is unexpected")
                    }
                } else if op == "+" {
                    if case let .bool(n1) = newFormula[index - 1],
                        case let .bool(n2) = newFormula[index - 2]
                    {
                        newFormula[index - 2] = .bool(n1 || n2)
                        newFormula.remove(at: index)
                        newFormula.remove(at: index - 1)
                        decreaseIndex(&index, k: 2)
                    } else {
                        fatalError("this is unexpected")
                    }
                } else if op == "*" {
                    if case let .bool(n1) = newFormula[index - 1],
                        case let .bool(n2) = newFormula[index - 2]
                    {
                        newFormula[index - 2] = .bool(n1 && n2)
                        newFormula.remove(at: index)
                        newFormula.remove(at: index - 1)
                        decreaseIndex(&index, k: 2)
                    } else {
                        fatalError("this is unexpected")
                    }
                }
            }
        }
        return newFormula[0].value
    }

    @inline(__always)
    private func increaseIndex(_ index: inout Int, max: Int) {
        index += 1
        #if DEBUG
            if index > (max - 1) {
                fatalError("Aout of bound \(index) of \(max)")
            }
        #endif
    }

    @inline(__always)
    private func decreaseIndex(_ index: inout Int, k: Int = 1) {
        index -= k
        #if DEBUG
            if index < 0 {
                fatalError("Aout of bound \(index)")
            }
        #endif
    }

    private enum Component {
        case bool(Bool)
        case `operator`(String)

        var value: Bool {
            if case let .bool(bool) = self {
                return bool
            }
            return false
        }
    }
}
