//
//  ignore.swift
//  Semixel
//
//  Created by Andrew Thompson on 13/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation

@_functionBuilder
struct ErrorBuilder {
    
    typealias Method = () throws -> ()
    typealias M2 = () throws -> ()
    
    static func buildBlock() -> [Method] {
        return []
    }

    // Sequential statements
    static func buildBlock(_ methods: Method...) -> [Method] {
        return methods
    }

    // Sequential blocks
    static func buildBlock(_ methods: [Method]...) -> [Method] {
        return methods.flatMap { $0 }
    }

    // Capture throwing functions
    static func buildExpression(_ expression: @autoclosure @escaping Method) -> [Method] {
        return [expression]
    }
    
    // If statements
    static func buildOptional(_ method: [M2]?) -> [M2] {
        if let m = method {
            return m
        } else {
            return []
        }
    }
    
    struct ErrorUnion: Error, CustomStringConvertible {
        var errors: [Error]
        var line: Int
        var file: String
        
        init(_ errors: [Error], _ line: Int = #line, _ file: String = #file) {
            self.errors = errors
            self.line = line
            self.file = file
        }
        
        var description: String {
            """
        Ignored \(errors.count) errors at \(file):\(line).
        \t\(errors.map { "\($0)" }.joined(separator: "\n\t"))
        """
        }
    }
}

func foreach<S: Sequence>(_ sequence: S,
                          @ErrorBuilder block: (S.Element) throws -> [ErrorBuilder.Method]) throws -> [ErrorBuilder.Method] {
    return try sequence.flatMap { (element) -> [ErrorBuilder.Method] in
        return try block(element)
    }
}

func captureErrors(@ErrorBuilder _ block: () throws -> [ErrorBuilder.Method],
                                  _ line: Int = #line,
                                  _ file: String = #file) throws {
    var ignoredErrors: [Error] = []
    let methods = try block()
    for method in methods {
        do {
            try method()
        } catch {
            ignoredErrors.append(error)
        }
    }
    if ignoredErrors.count > 0 {
        throw ErrorBuilder.ErrorUnion(ignoredErrors, line, file)
    }
}

func ignoreErrors(log: Bool = true,
                  @ErrorBuilder _ block: () throws -> [ErrorBuilder.Method],
                  _ line: Int = #line,
                  _ file: String = #file) {
    do {
        try captureErrors(block, line, file)
    } catch {
        print(error)
    }
}
