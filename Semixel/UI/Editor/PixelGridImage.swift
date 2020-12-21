//
//  PixelGridImage.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct PixelGridImage: View {
    
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            if verticalSpacing > 1 && horizontalSpacing > 1 {
                Path { path in
                    let numberOfHorizontalGridLines = Int(geometry.size.height / self.verticalSpacing)
                    let numberOfVerticalGridLines = Int(geometry.size.width / self.horizontalSpacing)
                    for index in 0...numberOfVerticalGridLines {
                        let vOffset: CGFloat = CGFloat(index) * self.horizontalSpacing
                        path.move(to: CGPoint(x: vOffset, y: 0))
                        path.addLine(to: CGPoint(x: vOffset, y: geometry.size.height))
                    }
                    for index in 0...numberOfHorizontalGridLines {
                        let hOffset: CGFloat = CGFloat(index) * self.verticalSpacing
                        path.move(to: CGPoint(x: 0, y: hOffset))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: hOffset))
                    }
                }
                .stroke(Color(UIColor.darkGray))
            }
        }
    }
}
