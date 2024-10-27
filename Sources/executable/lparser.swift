//
//  lparser.swift
//  logic-expression-parser
//
//  Created by Wojciech Kosikowski on 25/10/2024.
//

import ArgumentParser
import LeXParser



@main
struct Repeat: ParsableCommand {
//    @Argument(help: "The phrase to repeat.")
//    var phrase: String
//    
    
    @Option(help: "Signle line logic expressiono")
    var singleLine: String
    
//    //A2=B*C+~D \n
//    //A1=B*C+~D
//    @Option(help: "Many...")
//    var many: String
    
    mutating func run() throws {
        print(singleLine)
        let parser = Parser()
        let result = try parser.parse(input: singleLine)
        print(result)
    }
}
