//
//  ignore.swift
//  Semixel
//
//  Created by Andrew Thompson on 13/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation

@resultBuilder
public struct ErrorBuilder {
    
    public typealias Method = () throws -> ()
    public typealias M2 = () throws -> ()
    
    public static func buildBlock() -> [Method] {
        return []
    }

    // Sequential statements
    public static func buildBlock(_ methods: Method...) -> [Method] {
        return methods
    }

    // Sequential blocks
    public static func buildBlock(_ methods: [Method]...) -> [Method] {
        return methods.flatMap { $0 }
    }

    // Capture throwing functions
    public static func buildExpression(_ expression: @autoclosure @escaping Method) -> [Method] {
        return [expression]
    }
    
    // foreach
    public static func buildExpression(_ expression: [Method]) -> [Method] {
        return expression
    }
    
    // If statements
    public static func buildOptional(_ method: [M2]?) -> [M2] {
        if let m = method {
            return m
        } else {
            return []
        }
    }
    
    public struct ErrorUnion: Error, CustomStringConvertible {
        public var errors: [Error]
        public var line: Int
        public var file: String
        
        public init(_ errors: [Error], _ line: Int = #line, _ file: String = #file) {
            self.errors = errors
            self.line = line
            self.file = file
        }
        
        public var description: String {
            """
        Ignored \(errors.count) errors at \(file):\(line).
        \t\(errors.map { "\($0)" }.joined(separator: "\n\t"))
        """
        }
    }
}

public func foreach<S: Sequence>(_ sequence: S,
                          @ErrorBuilder block: (S.Element) throws -> [ErrorBuilder.Method]) throws -> [ErrorBuilder.Method] {
    return try sequence.flatMap { (element) -> [ErrorBuilder.Method] in
        return try block(element)
    }
}

public func captureErrors(@ErrorBuilder _ block: () throws -> [ErrorBuilder.Method],
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

public func ignoreErrors(log: Bool = true,
                  @ErrorBuilder _ block: () throws -> [ErrorBuilder.Method],
                  _ line: Int = #line,
                  _ file: String = #file) {
    do {
        try captureErrors(block, line, file)
    } catch {
        print(error)
    }
}
