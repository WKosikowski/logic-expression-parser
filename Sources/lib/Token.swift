//
//  Token.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 26/10/2024.
//
public enum TokenType: Sendable {
    case Operator
    case Equal
    case BracketOpen
    case BracketClose
    case Operand
    case Invalid
}

public struct Token: Sendable {
    let value: String
    let type: TokenType
    init(value: String, type: TokenType) {
        self.value = value
        self.type = type
    }
}

extension Token: Equatable {
    public static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.value == rhs.value && lhs.type == rhs.type
    }
}

extension Token: CustomDebugStringConvertible {
    public var debugDescription: String {
        "[\(self.value) \(self.type)]"
    }
}

extension Token: Hashable {}
