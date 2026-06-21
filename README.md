# Cursor DVD Screensaver for macOS

A native macOS utility that monitors system idle time and transforms the mouse cursor into a bouncing screensaver, mimicking the classic DVD logo bounce effect.

## Features

- **Automatic Activation**: Monitors system activity in the background and activates after one minute of complete user inactivity (AFK).
- **Actual Cursor Control**: Rather than drawing a simulated cursor, the application takes programmatic control of the actual macOS system cursor.
- **Visual Scale and Color Cycles**: Temporarily enlarges the pointer cursor to a high-visibility format and cycles through a vibrant palette of colors on every screen edge collision.
- **Seamless Interruption**: Any physical keyboard activity or mouse movement immediately stops the screensaver, restores the cursor to its standard size, and resets the idle monitor.
- **Dock and Status Bar Presence**: Accessible via both the macOS Dock and the Status Menu Bar.

## Technical Architecture

The application is built in Swift using native macOS frameworks (AppKit and IOKit) to ensure high performance and low resource consumption:

- **Idle Monitoring**: Uses the IOKit framework (`IOHIDSystem`) to query hardware inactivity state, requiring no accessibility or input monitoring permissions from the user.
- **CoreGraphics Warp**: Uses `CGWarpMouseCursorPosition` to programmatically move the system pointer at 60 frames per second.
- **Custom Cursor Rects**: Employs a borderless, transparent overlay window spanning the active screen workspace to override the system cursor visual using a dynamically generated `NSCursor`.

## Building and Running

### Prerequisites
- macOS 14.0 or newer
- Swift 5.9+ / Xcode Command Line Tools

### Compilation
Build the executable using Swift Package Manager:
```bash
swift build -c release
```

### Packaging as an App Bundle
1. Create the application bundle structure:
   ```bash
   mkdir -p CursorDVD.app/Contents/MacOS
   mkdir -p CursorDVD.app/Contents/Resources
   ```
2. Copy the compiled binary and metadata:
   ```bash
   cp .build/release/CursorDVD CursorDVD.app/Contents/MacOS/CursorDVD
   cp CursorDVD.app/Contents/Info.plist CursorDVD.app/Contents/Info.plist
   cp dvd-logo.jpg CursorDVD.app/Contents/Resources/dvd-logo.jpg
   ```
3. Run the application:
   ```bash
   open CursorDVD.app
   ```

## Configuration

Click on the Status Menu Bar icon to adjust:
- **Idle Timeout**: Set the duration of inactivity required to trigger the screensaver (ranges from 5 seconds for testing up to 5 minutes).
- **Manual Launch**: Trigger the screensaver instantly using the "Test Screensaver Now" menu option.
- **Termination**: Quit the application safely using the "Quit Cursor DVD" option.
