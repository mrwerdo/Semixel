//
//  ContentView.swift
//  Semixel
//
//  Created by Andrew Thompson on 9/7/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var store: ArtworkStore
    
    @State var selection: String?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.artwork) { (artwork: ArtworkMetadata) in
                    let destination = store.view(for: artwork)
                        .onDisappear(perform: { save(artwork) })
                        .navigationBarTitle(artwork.title, displayMode: .inline)
                    NavigationLink(destination: destination, tag: artwork.id, selection: $selection) {
                        // todo: make the thumbnail preview pixel perfect
                        store.preview(for: artwork)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding(EdgeInsets(top: 4, leading: 5, bottom: 6, trailing: 5))
                        VStack(alignment: .leading) {
                            Text(artwork.title)
                            Text(artwork.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }.onDelete(perform: delete(at:))
            }
            .navigationBarTitle("Artwork")
            .navigationBarItems(trailing: EditButton())
            .listStyle(PlainListStyle())
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            add()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .padding()
                        Button {
                            ignoreErrors {
                                try store.addDefaultArtwork(force: true)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }.padding()
                        Spacer()
                    }
                }
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
