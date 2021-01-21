//
//  main.swift
//  Semixel
//
//  Created by Andrew Thompson on 11/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import Cocoa
import ArgumentParser

struct ProjectSync: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "semxiel",
        abstract: "Syncronize artwork to and from the iOS app.",
        version: "0.1",
        subcommands: [Download.self],
        defaultSubcommand: Download.self)
}

struct Options: ParsableArguments {
    @Flag(name: .shortAndLong,
          help: "Include to increase the level of detail.")
    var verbose: Bool = false

    @Flag(name: [.customLong("no-pp", withSingleDash: true), .long],
          help: "Enable colorized output.")
    var noPrettyPrint: Bool = false
    
    @Option(name: .shortAndLong,
            help: "The name of the project on the iOS app to syncronize.")
    var project: String?
    
    @Option(name: .shortAndLong,
            help: "Only artwork with titles containing this string will be syncronized.")
    var filter: String?
    
    @Option(name: .shortAndLong,
            completion: .directory,
            help: "The path to the project directory on this computer.")
    var directory: String = FileManager.default.currentDirectoryPath
}

extension ProjectSync {
    struct Download: ParsableCommand {

        @OptionGroup var options: Options
                
        func run() throws {
            var logger = Logger()
            logger.prettyPrint = !options.noPrettyPrint
            logger.verbosity = options.verbose
            
            guard let displayName = Host.current().localizedName else {
                logger.error("unable to get current host name.")
                throw ExitCode.failure
            }

            let peerId = MCPeerID(displayName: displayName)
            
            let request = SyncRequest(project: options.project,
                                      filter: options.filter,
                                      projectBaseDirectory: options.directory)

            let browser = Browser(peerId, request, RunLoop.current, logger: logger)
            browser.start()
        }
    }
}

ProjectSync.main()
