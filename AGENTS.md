# Fenetta

A UVC (USB) camera viewer for iPad only. SwiftUI + AVFoundation. iOS 17 or later, iPad only (`TARGETED_DEVICE_FAMILY = 2`).

## Controls

The video is always full screen. The UI is brought up with gestures.

- Single tap: toggle the controls (camera selection, 90-degree rotation, Fit/Fill)
- Double tap: switch between contain / cover
- Pinch: 1x–5x zoom. While zoomed, drag with two fingers to pan

Gestures are consolidated in `GestureOverlay` (UIKit). SwiftUI's DragGesture cannot distinguish the number of fingers.
View state is held by `ViewerState`. If you change the pan limit calculation (which depends on fit / rotation / viewport),
you can verify the numbers by compiling for macOS with `swiftc -parse-as-library Fenetta/ViewerState.swift <harness>`.

## Project layout

- `Fenetta.xcodeproj` is generated from `project.yml` with `xcodegen generate`. Do not edit the pbxproj directly.
  Build settings changed in the Xcode GUI are lost on the next regeneration, so put settings in `project.yml`.
- Sources are `Fenetta/*.swift`. After adding a file, run `xcodegen generate`.
- `Fenetta/Info.plist` is hand-written (`GENERATE_INFOPLIST_FILE = NO`). Standard keys such as CFBundleIdentifier are
  written as build setting variables. If you remove them, devicectl refuses to install with "not a valid bundle".
- Build output goes to `~build/` (already gitignored).

## Build and install on a device

The steps are collected in `.j-menu.yaml` (pick and run them with `j-menu`). To type them by hand:

```shell
xcodegen generate
xcodebuild -project Fenetta.xcodeproj -scheme Fenetta \
  -destination 'generic/platform=iOS' -configuration Debug \
  -derivedDataPath '~build' -allowProvisioningUpdates build
xcrun devicectl list devices
xcrun devicectl device install app --device <UDID> '~build/Build/Products/Debug-iphoneos/Fenetta.app'
xcrun devicectl device process launch --device <UDID> com.ytyng.Fenetta
```

- Signing is Automatic with Cyberneura K.K. (`DEVELOPMENT_TEAM = 2YN5TLNQ9J`). The personal team GHB7FBR8UY
  cannot be used because Xcode rejects its Apple ID login.
- The development iPad is "Bartolome" (iPad mini A17 Pro). If devicectl shows it as `unavailable`, it is not connected.
- Inside the Claude Code sandbox, xcodebuild / devicectl do not work (the xcrun cache and CoreDevice XPC are
  blocked). Lift the sandbox with `/sandbox` and run them.

## Tests

There are no unit tests. Verify behavior by connecting a USB camera to a physical device.
