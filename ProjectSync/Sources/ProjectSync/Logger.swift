//
//  Logger.swift
//  Semixel
//
//  Created by Andrew Thompson on 20/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//
import Foundation

enum Verbosity: Int {
    case normal
    case verbose
}

var currentVerbosity: Verbosity = .normal
var prettyPrint: Bool = true

enum MessageType {
    case error
    case warning
    case output
}

func log(_ msg: String, _ type: MessageType = .output, _ verbosity: Verbosity = .normal) {
    if verbosity.rawValue <= currentVerbosity.rawValue {
        switch type {
        case .output:
            print(msg)
        case .warning:
            var handle = FileHandle.standardError
            let warning = prettyPrint ? "\u{1b}[33mwarning: \u{1b}[0m" : "warning"
            print(warning + msg, to: &handle)
        case .error:
            var handle = FileHandle.standardError
            let error = prettyPrint ? "\u{1b}[31merror: \u{1b}[0m" : "error"
            print(error + msg, to: &handle)
        }
    }
}

extension FileHandle : TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}

