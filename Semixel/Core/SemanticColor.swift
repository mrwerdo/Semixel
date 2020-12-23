//
//  SemanticColor.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import UIKit
import Combine

struct IdentifiableColor: Identifiable, Equatable {
    var color: RGBA
    var id: UUID
}

class ColorPalette: ObservableObject {
    @Published
    var colors: [IdentifiableColor]
    
    init(colors: [IdentifiableColor]) {
        self.colors = colors
    }
}
