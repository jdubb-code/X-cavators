# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**X-cavators** is a SwiftUI-based iOS application (iOS 26.2+) developed for iPhone and iPad. The project is in its early stages, currently displaying a logo on a black background. Bundle identifier: `FLL.X-cavators`, Team ID: `3CT2932SF4`.

## Build Commands

The project uses Xcode with standard iOS tooling:

- **Build the project**: Open `X-cavators.xcodeproj` in Xcode and build (Cmd+B)
- **Run the app**: Open in Xcode and run (Cmd+R) on a simulator or device
- **Clean build**: Product > Clean Build Folder in Xcode

Note: This project requires full Xcode (not just Command Line Tools) for building and running.

## Architecture

**Standard SwiftUI App Structure:**
- `X_cavatorsApp.swift`: App entry point using `@main` and `WindowGroup`
- `ContentView.swift`: Main view displaying the logo centered on a black background with white border and shadow effects
- `Assets.xcassets/`: Contains app icons, accent colors, and the logo image

**Swift Configuration:**
- Swift 5.0 with approachable concurrency enabled
- Default actor isolation: MainActor
- String catalog generation and symbol generation enabled
- Member import visibility feature enabled

**UI/UX Patterns:**
- Uses SwiftUI's declarative syntax
- ZStack for layering (background + logo)
- Supports both portrait and landscape orientations on iPhone and iPad
- Launch screen generation enabled
