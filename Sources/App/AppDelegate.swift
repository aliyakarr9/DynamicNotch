import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowController = NotchWindowController()
        windowController?.showWindow(nil)

        // Ensure the window is visible and on top
        windowController?.window?.makeKeyAndOrderFront(nil)
    }
}
