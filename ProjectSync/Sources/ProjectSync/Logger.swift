//
//  Logger.swift
//  Semixel
//
//  Created by Andrew Thompson on 20/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation

struct StandardError: TextOutputStream {
  mutating func write(_ string: String) {
    for byte in string.utf8 { putc(numericCast(byte), stderr) }
  }
}

var standardError = StandardError()
struct Logger: Codable {
    var verbosity: Bool = false
    var prettyPrint: Bool = false
    
    func verbose(_ msg: String) {
        if verbosity {
            print(msg)
        }
    }
    
    func log(_ msg: String) {
        print(msg)
    }
    
    func warning(_ msg: String, isVerbose: Bool = false) {
        if verbosity || !isVerbose {
            var handle = StandardError()
            let warning = prettyPrint ? "\u{1b}[33mwarning: \u{1b}[0m" : "warning: "
            print(warning + msg, to: &handle)
        }
    }
    
    func error(_ msg: String, isVerbose: Bool = false) {
        if verbosity || !isVerbose {
            var handle = StandardError()
            let error = prettyPrint ? "\u{1b}[31merror: \u{1b}[0m" : "error: "
            print(error + msg, to: &handle)
        }
    }
}
