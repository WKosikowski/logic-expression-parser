//
//  ExpressionSyntax.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 27/10/2024.
//

public struct Formula {
    public let output: Token
    public let expression: [Token]
    public let value: Bool?

    public init(output: Token, expression: [Token], value: Bool?) {
        self.output = output
        self.expression = expression
        self.value = value
    }
}
