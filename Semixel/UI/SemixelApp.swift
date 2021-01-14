//
//  SemixelApp.swift
//  Semixel
//
//  Created by Andrew Thompson on 23/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

@main
struct SemixelApp: App {
    
    @StateObject var model = initialize()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
