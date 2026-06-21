import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let engine = BouncingEngine()
    
    // Configuration
    var idleTimeout: Double = 60.0 // default 1 minute (60 seconds)
    var selectedStyle: ScreensaverStyle = .hybrid
    
    // State
    var isScreensaverRunning = false
    var checkIdleTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a regular app (shows Dock icon)
        NSApp.setActivationPolicy(.regular)
        
        setupMenuBar()
        startIdleChecking()
        
        // Listen to screensaver stopping to resume idle checking
        engine.onStop = { [weak self] in
            self?.isScreensaverRunning = false
            self?.updateMenuStatus()
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Using a standard mouse cursor symbol from SF Symbols
            if let image = NSImage(systemSymbolName: "cursorarrow.and.square.on.square.dashed", accessibilityDescription: "Cursor DVD") {
                // Ensure the icon scales nicely in dark/light menu bars
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "💿🖱️"
            }
        }
        
        buildMenu()
    }
    
    func buildMenu() {
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "Cursor DVD Screensaver", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let statusItem = NSMenuItem(title: "Status: Idle Monitor Active", action: nil, keyEquivalent: "")
        statusItem.tag = 100
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
        let testItem = NSMenuItem(title: "Test Screensaver Now", action: #selector(testNow), keyEquivalent: "t")
        testItem.target = self
        menu.addItem(testItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Style Submenu
        let styleSubmenu = NSMenu()
        for style in ScreensaverStyle.allCases {
            let item = NSMenuItem(title: style.rawValue, action: #selector(changeStyle(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style
            item.state = (style == selectedStyle) ? .on : .off
            styleSubmenu.addItem(item)
        }
        let styleMenuItem = NSMenuItem(title: "Style", action: nil, keyEquivalent: "")
        styleMenuItem.submenu = styleSubmenu
        menu.addItem(styleMenuItem)
        
        // Idle Timeout Submenu
        let timeoutSubmenu = NSMenu()
        let timeouts: [(String, Double)] = [
            ("5 seconds (Testing)", 5.0),
            ("15 seconds (Testing)", 15.0),
            ("1 minute (Default)", 60.0),
            ("2 minutes", 120.0),
            ("5 minutes", 300.0)
        ]
        
        for (label, val) in timeouts {
            let item = NSMenuItem(title: label, action: #selector(changeTimeout(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = val
            item.state = (val == idleTimeout) ? .on : .off
            timeoutSubmenu.addItem(item)
        }
        let timeoutMenuItem = NSMenuItem(title: "Idle Timeout", action: nil, keyEquivalent: "")
        timeoutMenuItem.submenu = timeoutSubmenu
        menu.addItem(timeoutMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Cursor DVD", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.statusItem?.menu = menu
    }
    
    func startIdleChecking() {
        checkIdleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkIdleTime()
        }
    }
    
    func checkIdleTime() {
        guard !isScreensaverRunning else { return }
        
        let idleSeconds = IdleMonitor.getSystemIdleTime()
        updateMenuStatus(currentIdle: idleSeconds)
        
        if idleSeconds >= idleTimeout {
            startScreensaver()
        }
    }
    
    func updateMenuStatus(currentIdle: Double? = nil) {
        guard let menu = statusItem?.menu else { return }
        if let statusMenuItem = menu.item(withTag: 100) {
            if isScreensaverRunning {
                statusMenuItem.title = "Status: Screensaver Active"
            } else if let idle = currentIdle {
                statusMenuItem.title = "Status: Waiting (Idle: \(Int(idle))s / \(Int(idleTimeout))s)"
            } else {
                statusMenuItem.title = "Status: Idle Monitor Active"
            }
        }
    }
    
    func startScreensaver() {
        guard !isScreensaverRunning else { return }
        isScreensaverRunning = true
        updateMenuStatus()
        
        // Make sure the application is activated and overlay takes full screen context
        NSApp.activate(ignoringOtherApps: true)
        engine.start(style: selectedStyle)
    }
    
    @objc func testNow() {
        startScreensaver()
    }
    
    @objc func changeStyle(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? ScreensaverStyle else { return }
        selectedStyle = style
        buildMenu() // Rebuild to update tick marks
    }
    
    @objc func changeTimeout(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? Double else { return }
        idleTimeout = seconds
        buildMenu() // Rebuild to update tick marks
    }
    
    @objc func quitApp() {
        engine.stop()
        NSApplication.shared.terminate(nil)
    }
}

// Custom main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
