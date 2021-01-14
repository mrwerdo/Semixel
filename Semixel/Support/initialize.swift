//
//  initialize.swift
//  Semixel
//
//  Created by Andrew Thompson on 11/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation

extension ProcessInfo {
    func env<T>(_ key: String, _ init: (String) -> T?, default: @autoclosure () -> T) -> T {
        if let string = environment[key], let value = `init`(string) {
            return value
        } else {
            return `default`()
        }
    }
}

func initialize() -> ArtworkStore {
    let proc = ProcessInfo()
    let reset = proc.env("Semixel_ArtworkFileSystem_Reset", Bool.init, default: false)
    let initialize = proc.env("Semixel_ArtworkFileSystem_Initialize", Bool.init, default: false)
    
    let fs = ArtworkFileSystem.default
    
    ignoreErrors {
        if reset {
            try fs.reset()
        }
    }
    
    let store: ArtworkStore
    
    do {
        store = try ArtworkStore(fileSystem: fs)
    } catch {
        print(error)
        fatalError()
    }
    
    ignoreErrors {
        if initialize {
//            try store.addDefaultArtwork()
        }
    }
    
    return store
}

