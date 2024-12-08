//
//  File.swift
//  LeXParser
//
//  Created by Wojciech Kosikowski on 23/11/2024.
//

struct FileReader{
    func readString(file: String) -> String{
        let filePath = file
        do {
            return try String(contentsOfFile: filePath, encoding: .utf8)
        } catch {
            print("Error reading the file: \(error)")
        }
        return ""
    }
}
