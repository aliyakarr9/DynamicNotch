import Foundation
import AppKit
import SwiftUI

enum QuickActionType {
    case calculator
    case settings
    case lock
    case screenshot
}

class QuickActionsService {
    
    static let shared = QuickActionsService()
    
    
    private static var settingsWindowController: NSWindowController?
    
    func perform(_ action: QuickActionType) {
        switch action {
        case .calculator:
            
            
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.calculator") {
                NSWorkspace.shared.open(url)
            }
            
        case .settings:
            
            openSettings()
            
        case .lock:
            let source = """
            tell application "System Events" to keystroke "q" using {command down, control down}
            """
            executeAppleScript(source)
            
        case .screenshot:
            
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = ["-i", "-c", "-U"]
            task.launch()
        }
    }
    
    private func openSettings() {
        if let controller = QuickActionsService.settingsWindowController, let window = controller.window {
            controller.showWindow(nil)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = "NotchNook Ayarlar"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true

        let controller = NSWindowController(window: window)
        QuickActionsService.settingsWindowController = controller
        
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func executeAppleScript(_ source: String) {
        var error: NSDictionary?
        if let script = NSAppleScript(source: source) {
            script.executeAndReturnError(&error)
            if let error = error {
                print("⚠️ AppleScript Hatası: \(error)")
            }
        }
    }
}
