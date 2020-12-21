//
//  CursorDragGestureView.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/12/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct CursorDragGestureView<Content>: View {

    /// Controls how fast the cursor changes.
    var speed: CGFloat
    /// Defines the maximum and minimum position of the cursor.
    var size: CGSize
    
    @Binding
    var active: Bool
    
    private var content: Content
    
    @State
    private var lastPosition: CGPoint = .zero
    
    @State
    private var position: CGPoint = .zero
    
    init(speed: CGFloat, size: CGSize, active: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.speed = speed
        self.size = size
        self._active = active
        self.content = content()
    }
    
    var drag: some Gesture {
        DragGesture()
            .onChanged({ event in
                let delta = CGPoint(x: speed * (event.translation.width - lastPosition.x),
                                    y: speed * (event.translation.height - lastPosition.y))
                self.lastPosition = CGPoint(x: event.translation.width, y: event.translation.height)
                var newPosition = CGPoint(x: position.x + delta.x, y: position.y + delta.y)
                
                newPosition.x = max(-size.width/2, min(newPosition.x, size.width/2 - 12))
                newPosition.y = max(-size.height/2, min(newPosition.y, size.height/2 - 12))
                
                self.position = newPosition
                print(position)
//                updateTranslation(delta)
//                onDrag()
            })
            .onEnded({ delta in
                self.lastPosition = .zero
            })
    }
    
    var body: some View {
            Rectangle()
//                .opacity(0.0)
                .stroke(Color.green)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .simultaneousGesture(drag)
    }
}
