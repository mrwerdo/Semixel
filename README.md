# Semixel
A one-handed iOS pixel art editing prototype.

## Introduction

I made Semixel because I was experimenting with an alternative user interaction model for editing pixel artwork.

![TrafficLight](Docs/TrafficLight.gif)

## Functionality

Pixel artwork editing is possible, albeit awkwardly, with the following features implemented:
- Undo & redo
- Pen, line, circle, and paint bucket tool.
- Color palatte with eye dropper and color remapping (based on identity not value).
- Rectangular select and deselect, magic select and deselect, move, vertical flip, and horizontal flip.
- Add, rename, and delete artwork.
- Toggling an alignment grid.

An additional novel features includes syncing artwork between the device and a laptop using a command
line program. See below for a discussion about how this works.

### Project Sync

Project Sync transfers project artwork between an iOS and macOS device. Images are copied between
devices by running a macOS command line program in the root directory of a project. Semixel tracks
where an artwork is located in a project using an artwork's path property. The sync is limited
to devices signed in with the same Apple Id.

This skips the need to rename and move files - quite convenient when iterating quickly. No more
`Image 1.png`, `Image 2.png`, ... in the downloads folder!

### Not Implemented (Yet)

Missing functionality includes:
- Cut, Copy, paste, and 90º rotate.
- Resizing artwork.
- Zoom (partially implemented).
- Layers (partially implemented).
- Grouping artwork by projects and path.

## Architecture

Semixel aimed to follow a clean architecture. The code is grouped into three areas: SemixelCore,
Support, and UI. **SemixelCore** contains the logic of working with pixel art images. **Support** interfaces
with the file system, network, and adds additional image processing functionality (like converting a
pixel art image to a UIImage so it can be displayed). **UI** provides the user interface using 
SwiftUI views.
