import Foundation
import AppKit

enum QuickActionType {
    case screenshot
    case calculator
    case settings
    case lock
}

class QuickActionsService {

    func perform(_ action: QuickActionType) {
        switch action {
        case .screenshot:
            takeScreenshot()
        case .calculator:
            launchApp("Calculator")
        case .settings:
            launchApp("System Settings")
        case .lock:
            lockScreen()
        }
    }

    private func takeScreenshot() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        // -i: interactive (selection mode)
        // -c: to clipboard (optional, but standard for utility apps)
        // If we want file output, we omit -c.
        // Let's do interactive selection mode:
        task.arguments = ["-i"]

        do {
            try task.run()
        } catch {
            print("Failed to take screenshot: \(error)")
        }
    }

    private func launchApp(_ name: String) {
        NSWorkspace.shared.launchApplication(name)
    }

    private func lockScreen() {
        // Send Ctrl+Cmd+Q keystroke to lock immediately
        let source = """
        tell application "System Events"
            keystroke "q" using {command down, control down}
        end tell
        """

        var error: NSDictionary?
        if let script = NSAppleScript(source: source) {
            script.executeAndReturnError(&error)
        }
    }
}
