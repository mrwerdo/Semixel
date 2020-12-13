//
//  ContentView.swift
//  Semixel
//
//  Created by Andrew Thompson on 9/7/20.
//  Copyright © 2020 Andrew Thompson. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var model: ArtworkModel
    
    @State var selection: URL?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(model.artwork) { (artwork: Artwork) in
                    let destination = PixelViewV2()
                        .environmentObject(artwork)
                        .onDisappear(perform: save(artwork: artwork))
                    NavigationLink(destination: destination, tag: artwork.url, selection: $selection) {
                        // todo: make the thumbnail preview pixel perfect
                        artwork.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding(EdgeInsets(top: 4, leading: 5, bottom: 6, trailing: 5))
                        VStack(alignment: .leading) {
                            Text(artwork.name)
                            Text("\(artwork.size.width)x\(artwork.size.height)")
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
                    Button {
                        add()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .padding()
                }
            }
        }
    }
    
    func save(artwork: Artwork) -> (() -> Void) {
        return {
            do {
                try artwork.pixelImage.write(to: artwork.url)
            } catch {
                print(error)
            }
        }
    }
    
    func delete(at offsets: IndexSet) {
        model.remove(at: offsets)
    }
    
    func add() {
        do {
            selection = try model.createArtwork().url
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
