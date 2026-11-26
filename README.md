# Fenetta

A UVC (USB) camera viewer for iPad only. It shows the video from a USB-connected camera full screen, and you can pinch to zoom.

## Requirements

- Xcode 16 or later
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- An iPad running iOS 17 or later (with a UVC camera connected over USB-C)

## Build

```shell
xcodegen generate
open Fenetta.xcodeproj
```

Select a physical device in Xcode and Run. For command-line steps, see `AGENTS.md` and `.j-menu.yaml`.
