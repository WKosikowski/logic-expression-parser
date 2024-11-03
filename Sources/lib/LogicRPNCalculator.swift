//
//  RPNCalculator.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 27/10/2024.
//
import Darwin

public struct LogicRPNCalculator {

    public init() {}

    public func calculateOne(expression: Expression, input: [Token: Bool])
        -> Bool
    {
        var newFormula: [Component] = []
        for token in expression {
            if token.type == .Operand {
                newFormula.append(.bool(input[token] ?? false))
            } else {
                newFormula.append(.operator(token.value))
            }
        }
        var index = 0
        while newFormula.count > 1 {
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

    class PermutationList {
        var firstNode: PermutationNode?

        var lastNode: PermutationNode? {
            firstNode?.getLast()
        }
        let permutations: Int

        init(formula: Formula) {

            let inputs = Set(
                formula.expression
                    .filter({ $0.type == TokenType.Operand })
            ).sorted(
                by: { $0.value < $1.value })
            permutations = Int(pow(Double(2), Double(inputs.count)))

            for token in inputs {

                let node = PermutationNode(value: false, input: token)

                if let last = firstNode?.getLast() {
                    last.nextNode = node
                } else {
                    firstNode = node
                }
            }

        }

        @inline(__always)
        @_optimize(speed)
        func getNextPermutationDictionary() -> [Token: Bool] {
            var result: [Token: Bool] = [:]
            var current = firstNode
            while let c = current {
                result[c.input] = c.value
                current = c.nextNode
            }
            firstNode?.increment()
            return result
        }

        func reset() {
            while let n = firstNode?.nextNode {
                n.value = false
            }
            firstNode?.value = false
        }
    }

    class PermutationNode {
        init(value: Bool, input: Token, nextNode: PermutationNode? = nil) {
            self.value = value
            self.input = input
            self.nextNode = nextNode
        }
        var value: Bool
        var input: Token
        var nextNode: PermutationNode?

        func getLast() -> PermutationNode {
            nextNode?.getLast() ?? self
        }

        @inline(__always)
        @_optimize(speed)
        func increment() {
            value.toggle()
            if !value {
                nextNode?.increment()
            }
        }
    }

    @_optimize(speed)
    public func printTruthTable(formula: Formula) -> String {
        var printString = ""
        let permutationsList = PermutationList(formula: formula)
        let inputs = Set(
            formula.expression.filter({ $0.type == TokenType.Operand })
        ).sorted(
            by: { $0.value < $1.value })

        printString += "    "  // 4 spaces
        for e in inputs {
            printString += e.value + " "
        }
        printString += "  \(formula.output.value)\n"

        for c in 0...permutationsList.permutations - 1 {
//            print(
//                "\(100*Double(c)/Double(permutationsList.permutations))% done ",
//                terminator: "\r")
            printString += "\(c) | "
            let inValues = permutationsList.getNextPermutationDictionary()
            let result = calculateOne(
                expression: formula.expression,
                input: inValues)
            for r in inValues.keys.sorted(
                by: { $0.value < $1.value })
            {
                if let inValue = inValues[r] {
                    printString +=
                        inValue
                        ? "1"
                            .padding(
                                toLength: r.value.count + 1,
                                withPad: " ",
                                startingAt: 0
                            )
                        : "0"
                            .padding(
                                toLength: r.value.count + 1,
                                withPad: " ",
                                startingAt: 0
                            )
                }
            }
            printString += result ? "| 1" : "| 0"
            if c != permutationsList.permutations - 1 {
                printString += "\n"
            }
        }
        return printString
    }
}
