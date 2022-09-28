//
//  ContentView.swift
//  Semixel
//
//  Created by Andrew Thompson on 9/7/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI
import Geometry
import SemixelCore

struct ArtworkView: View {
    
    @EnvironmentObject var store: ArtworkStore
    
    @State var selection: String?
    @State var showAttributes: Bool = false
    
    var attributesButton: some View {
        Button(action: {
            showAttributes.toggle()
        }, label: {
            Image(systemName: "ellipsis.circle")
                .font(Font.title2.weight(.light))
                .contentShape(Rectangle())
                .accentColor(Color.black)
        })
    }
    
    func navigationLinkView(_ artwork: ArtworkMetadata) -> some View {
        Group {
            store.preview(for: artwork)
                .padding(EdgeInsets(top: 4, leading: 5, bottom: 6, trailing: 5))
            VStack(alignment: .leading) {
                Text(artwork.title)
                Text(artwork.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.artwork) { (artwork: ArtworkMetadata) in
                    NavigationLink(value: artwork.id, label: { navigationLinkView(artwork) })
                }.onDelete(perform: delete(at:))
            }
            .navigationDestination(for: String.self, destination: { artworkId in
                let metadata = store.artwork.first(where: { $0.id == artworkId })!
                store.view(for: metadata)
                    .onDisappear(perform: { save(metadata) })
            })
            .navigationTitle("Artwork")
            .listStyle(PlainListStyle())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    attributesButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: add) {
                        Image(systemName: "plus")
                    }
                    .accentColor(.black)
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showAttributes) {
            attributesView.presentationDetents([PresentationDetent.medium, .large])
        }
    }
    
    var attributesView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Standalone Artwork")
                    .font(Font.title3)
                Spacer()
                Button {
                    showAttributes = false
                } label: {
                    ZStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(Color(UIColor.secondarySystemFill))
                            .font(.system(size: 31))
                        Image(systemName: "xmark")
                            .foregroundColor(Color.secondary)
                            .font(.system(size: 15, weight: .bold))
                    }
                }
            }
            .padding()
            .padding(.leading)
            .padding(.trailing)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            Divider()
            List {
                Section {
                    action(title: "Add default artwork",
                           icon: "doc.badge.plus",
                           callback: addDefaultArtwork)
                }
                let warning = Text("Warning: this will remove all of your artwork.")
                Section(footer: warning) {
                    action(title: "Reset",
                           icon: "exclamationmark.arrow.triangle.2.circlepath",
                           callback: reset)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .accentColor(Color.black)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    func action(title: String, icon: String, callback: @escaping () -> ()) -> some View {
        Button {
            callback()
            showAttributes = false
        } label: {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: icon)
                    .font(Font.title3)
            }
        }
    }
    
    func save(_ artwork: ArtworkMetadata) {
        do {
            try store.save(artwork)
        } catch {
            print(error)
        }
    }
    
    func delete(at offset: IndexSet) {
        do {
            try store.remove(at: offset)
        } catch {
            print(error)
        }
    }
    
    func add() {
        do {
            _ = try store.create(.semantic, size: Size2D(width: 32, height: 32))
        } catch {
            print(error)
        }
    }
    
    func reset() {
        do {
            try store.reset()
        }
        catch {
            print(error)
        }
    }
    
    func addDefaultArtwork() {
        ignoreErrors {
            try store.addDefaultArtwork(force: true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ArtworkView()
    }
}
