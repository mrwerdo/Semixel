//
//  HalfModalSheet.swift
//  Semixel
//
//  Created by Andrew Thompson on 21/1/21.
//  Copyright © 2021 Andrew Thompson. All rights reserved.
//

import SwiftUI

extension View {
    func halfModalSheet<Content: View>(isPresented: Binding<Bool>, content: @autoclosure () -> Content) -> some View {
        return HalfModalView(content: self, modalContent: content(), isPresented: isPresented)
    }
}

struct HalfModalSlider<Content: View, ModalContent: View, G1: Gesture, G2: Gesture>: View {
    var content: Content
    var modal: ModalContent
    var height: CGFloat
    var backgroundTap: G1
    var drag: G2

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                content
                ZStack {
                    if height > 0 {
                        Color.black
                            .edgesIgnoringSafeArea(.top)
                            .opacity(height > 0.5 ? 0.1 : 0.1 * Double(height / 0.5))
                            .contentShape(Rectangle())
                            .gesture(backgroundTap)
                            .transition(AnyTransition.opacity)
                            .zIndex(1)
                        modal
                            .edgesIgnoringSafeArea(.all)
                            .cornerRadius(15)
                            .offset(y: geometry.size.height - height * geometry.size.height)
                            // fixme: scrolling in the list view should be disabled unless the view is fully open.
                            .gesture(drag)
                            .transition(AnyTransition.move(edge: .bottom))
                            .zIndex(2)
                    }
                }
                .animation(Animation.easeInOut(duration: 0.3))
            }
            .background(Color.black.ignoresSafeArea())
        }
    }
}

struct HalfModalView<Content: View, ModalContent: View>: View {
    var content: Content
    var modal: ModalContent
    @Binding var isPresented: Bool
    
    private enum Notch {
        case halfOpen
        case open
    }
    
    @State private var notch: Notch = .halfOpen
    
    @GestureState private var translation: CGFloat?
    @State private var endTranslation: CGFloat? = nil
    
    init(content: Content, modalContent: ModalContent, isPresented: Binding<Bool>) {
        self.modal = modalContent
        self.content = content
        self._isPresented = isPresented
    }
    
    var tap: some Gesture {
        TapGesture().onEnded {
            notch = .halfOpen
            isPresented = false
        }
    }
    
    var drag: some Gesture {
        DragGesture()
            .updating($translation) { value, state, _ in
                state = -value.translation.height
            }
            .onEnded { value in
                endTranslation = -value.translation.height
                switch notch {
                case .open:
                    if value.translation.height > 90 && value.translation.height < 350 {
                        notch = .halfOpen
                        isPresented = true
                        endTranslation = nil
                        UITableView.appearance().isScrollEnabled = false
                        return
                    } else if value.translation.height >= 350 {
                        notch = .halfOpen
                        isPresented = false
                        endTranslation = nil
                    } else {
                        endTranslation = nil
                    }
                case .halfOpen:
                    if value.translation.height < -90 {
                        notch = .open
                        isPresented = true
                        endTranslation = nil
                        UITableView.appearance().isScrollEnabled = true
                    } else if value.translation.height > 90 {
                        notch = .halfOpen
                        isPresented = false
                        endTranslation = nil
                    }
                }
                endTranslation = nil
            }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let height = !isPresented ? 0 : (notch == .halfOpen ? 0.5 : 1 - 40/geometry.size.height)
            let dragOffset = (translation ?? (endTranslation ?? 0)) / geometry.size.height
            let boundedHeight = min(0.95, height + dragOffset)
            
            HalfModalSlider(content: content,
                            modal: modal,
                            height: boundedHeight,
                            backgroundTap: tap,
                            drag: drag)
                .onChange(of: isPresented) { (value) in
                    if !value {
                        notch = .halfOpen
                    }
                }
        }
    }
}
